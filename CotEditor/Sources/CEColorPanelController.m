/*
 =================================================
 CEColorPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-22 by 1024jp
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEColorPanelController.h"
#import "CEDocument.h"
#import "NSColor+HSL.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEColorCodeType) {
    CEAutoDetectColorCode,
    CEHexCode,
    CEShortHexCode,
    CERGBCode,
    CERGBaCode,
    CEHSLCode,
    CEHSLaCode
};


@interface CEColorPanelController ()

@property (nonatomic) IBOutlet NSView *accessoryView;
@property (nonatomic) NSColor *color;
@property (nonatomic) NSString *colorCode;

@end




#pragma mark -

@implementation CEColorPanelController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ColorCodePanelAccessory" owner:self];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// カラーコードから色をセットする
- (void)setColorWithCode:(NSString *)colorCode
// ------------------------------------------------------
{
    if ([colorCode length] > 0) {
        [self setColorWithCode:colorCode codeType:CEAutoDetectColorCode];
    }
}


#pragma mark Delegate

//=======================================================
// Delegate method (NSWindowDelegate)
//  <== NSColorPanel
//=======================================================

// ------------------------------------------------------
/// パネルをクローズ
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    NSColorPanel *colorPanel = (NSColorPanel *)[self window];
    [[self window] setDelegate:nil];
    [colorPanel orderOut:self];
    [colorPanel setAccessoryView:nil];
    [colorPanel setShowsAlpha:NO];
}



#pragma mark Action Messages

//=======================================================
// Action Messages
//
//=======================================================

// ------------------------------------------------------
/// パネルを表示
- (void)showWindow:(id)sender
// ------------------------------------------------------
{
    // 共有カラーパネルをセットアップ
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAccessoryView:[self accessoryView]];
    [colorPanel setShowsAlpha:YES];
    [colorPanel setStyleMask:[colorPanel styleMask] & ~NSResizableWindowMask];
    [colorPanel setRestorable:NO];
    
    [colorPanel setDelegate:self];
    [colorPanel setAction:@selector(selectColor:)];
    [colorPanel setTarget:self];
    
    [self setWindow:colorPanel];
    [self setColor:[colorPanel color]];
    [self updateCode:self];
    
    [colorPanel orderFront:self];
}


// ------------------------------------------------------
/// 書類にカラーコードを挿入する
- (IBAction)insertCodeToDocument:(id)sender
// ------------------------------------------------------
{
    [[[self documentWindowController] editorView] replaceTextViewSelectedStringTo:[self colorCode] scroll:YES];
}


// ------------------------------------------------------
/// カラーパネルで新しい色が選ばれた
- (IBAction)selectColor:(id)sender
// ------------------------------------------------------
{
    [self setColor:[sender color]];
    [self updateCode:sender];
}


// ------------------------------------------------------
/// カラーコードフィールドのカラーコードからカラーをセット
- (IBAction)applayColorCode:(id)sender
// ------------------------------------------------------
{
    CEColorCodeType codeType = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_colorCodeType];
    
    [self setColorWithCode:[self colorCode] codeType:codeType];
}


// ------------------------------------------------------
/// カラーコードを更新する
- (IBAction)updateCode:(id)sender
// ------------------------------------------------------
{
    NSColor *color = [self color];
    NSString *code;
    CEColorCodeType codeType = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_colorCodeType];
    
    // カラースペースをコンバートする
    color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    
    int r = (int)roundf(255 * [color redComponent]);
    int g = (int)roundf(255 * [color greenComponent]);
    int b = (int)roundf(255 * [color blueComponent]);
    double alpha = (double)[color alphaComponent];
    
    switch (codeType) {
        case CEHexCode:
            code = [NSString stringWithFormat:@"#%02x%02x%02x", r, g, b];
            break;
            
        case CEShortHexCode:
            code = [NSString stringWithFormat:@"#%1x%1x%1x", r/16, g/16, b/16];
            break;
            
        case CERGBCode:
            code = [NSString stringWithFormat:@"rgb(%d,%d,%d)", r, g, b];
            break;
            
        case CERGBaCode:
            code = [NSString stringWithFormat:@"rgba(%d,%d,%d,%g)", r, g, b, alpha];
            break;
            
        case CEHSLCode:
        case CEHSLaCode: {
            CGFloat hue, saturation, lightness, alpha;
            [color getHue:&hue saturation:&saturation lightness:&lightness alpha:&alpha];
            
            int h = (int)roundf(360 * hue);
            int s = (int)roundf(100 * saturation);
            int l = (int)roundf(100 * lightness);
            
            if (codeType == CEHSLaCode) {
                code = [NSString stringWithFormat:@"hsla(%d,%d%%,%d%%,%g)", h, s, l, alpha];
            } else {
                code = [NSString stringWithFormat:@"hsl(%d,%d%%,%d%%)", h, s, l];
            }
        } break;
            
        case CEAutoDetectColorCode:
            break;
    }
    
    [self setColorCode:code];
}


// ------------------------------------------------------
/// カラーパネルからのアクションで色を変更しない
- (void)changeColor:(id)sender
// ------------------------------------------------------
{
    NSLog(@"hoge");
    // do nothing.
}


#pragma mark Private Methods

//=======================================================
// Private Methods
//
//=======================================================

// ------------------------------------------------------
/// カラーコードから色をセットする
- (void)setColorWithCode:(NSString *)colorCode codeType:(CEColorCodeType)codeType
// ------------------------------------------------------
{
    colorCode = [colorCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRange codeRange = NSMakeRange(0, [colorCode length]);
    
    NSDictionary *patterns = @{@(CEHexCode): @"^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$",
                               @(CEShortHexCode): @"^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$",
                               @(CERGBCode): @"^rgb\\( ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9]{1,3})\\)$",
                               @(CERGBaCode): @"^rgba\\( ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9.]+)\\)$",
                               @(CEHSLCode): @"^hsl\\( ?([0-9]{1,3}), ?([0-9.]+)%, ?([0-9.]+)%\\)$",
                               @(CEHSLaCode): @"^hsla\\( ?([0-9]{1,3}), ?([0-9.]+)%, ?([0-9.]+)%, ?([0-9.]+)\\)$"
                               };
    NSRegularExpression *regex;
    NSArray *matchs;
    NSTextCheckingResult *result;
    
    
    if (codeType != CEAutoDetectColorCode) {
        regex = [NSRegularExpression regularExpressionWithPattern:patterns[@(codeType)] options:0 error:nil];
        matchs = [regex matchesInString:colorCode options:0 range:codeRange];
        if ([matchs count] == 1) {
            result = matchs[0];
        }
    }
    
    if (!result) {
        for (NSString *key in patterns) {
            regex = [NSRegularExpression regularExpressionWithPattern:patterns[key] options:0 error:nil];
            matchs = [regex matchesInString:colorCode options:0 range:codeRange];
            if ([matchs count] == 1) {
                codeType = [key integerValue];
                result = matchs[0];
                break;
            }
        }
    }
    
    if (!result) {
        NSBeep();
        return;
    }
    
    NSColor *color;
    
    switch (codeType) {
        case CEHexCode: {
            unsigned int r, g, b;
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:1]]] scanHexInt:&r];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:2]]] scanHexInt:&g];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:3]]] scanHexInt:&b];
            color = [NSColor colorWithDeviceRed:((CGFloat)r/255) green:((CGFloat)g/255) blue:((CGFloat)b/255) alpha:1.0];
        } break;
            
        case CEShortHexCode: {
            unsigned int r, g, b;
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:1]]] scanHexInt:&r];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:2]]] scanHexInt:&g];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:3]]] scanHexInt:&b];
            color = [NSColor colorWithDeviceRed:((CGFloat)r/15) green:((CGFloat)g/15) blue:((CGFloat)b/15) alpha:1.0];
        } break;
            
        case CERGBCode: {
            CGFloat r = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat g = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat b = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            color = [NSColor colorWithDeviceRed:r/255 green:g/255 blue:b/255 alpha:1.0];
        } break;
            
        case CERGBaCode: {
            CGFloat r = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat g = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat b = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            CGFloat a = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:4]] doubleValue];
            color = [NSColor colorWithDeviceRed:r/255 green:g/255 blue:b/255 alpha:a];
        } break;
            
        case CEHSLCode: {
            CGFloat h = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat s = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat l = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            color = [NSColor colorWithDeviceHue:h/360 saturation:s/100 lightness:l/100 alpha:1.0];
        } break;
            
        case CEHSLaCode: {
            CGFloat h = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat s = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat l = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            CGFloat a = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:4]] doubleValue];
            color = [NSColor colorWithDeviceHue:h/360 saturation:s/100 lightness:l/100 alpha:a];
        } break;
            
        default:
            break;
    }
    
    if (color) {
        [[NSUserDefaults standardUserDefaults] setInteger:codeType forKey:k_key_colorCodeType];
        [(NSColorPanel *)[self window] setColor:color];
        return;
    }
    
    NSBeep();
}

@end
