/*
 =================================================
 CEAppearancePaneController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-18
 
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

#import "CEAppearancePaneController.h"
#import "constants.h"


@interface CEAppearancePaneController ()

@property (nonatomic, weak) IBOutlet NSTextField *fontField;

@end




#pragma mark -

@implementation CEAppearancePaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setFontFamilyNameAndSize];
}



#pragma mark Action Messages

//------------------------------------------------------
/// 行間値を調整
- (IBAction)setupCustomLineSpacing:(id)sender
//------------------------------------------------------
{
    // IB で Formatter が設定できないのでメソッドで行ってる。
    
    CGFloat value = (CGFloat)[sender doubleValue];
    
    if (value < k_lineSpacingMin) { value = k_lineSpacingMin; }
    if (value > k_lineSpacingMax) { value = k_lineSpacingMax; }
    
    [sender setStringValue:[NSString stringWithFormat:@"%.2f", value]];
}


// ------------------------------------------------------
/// フォントパネルを表示
- (IBAction)showFonts:(id)sender
//-------------------------------------------------------
{
    NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName]
                                   size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize]];
    
    [[[self view] window] makeFirstResponder:self];
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}


// ------------------------------------------------------
/// フォントパネルでフォントが変更された
- (void)changeFont:(id)sender
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSFont *newFont = [sender convertFont:[NSFont systemFontOfSize:0]];
    NSString *name = [newFont fontName];
    CGFloat size = [newFont pointSize];

    [[NSUserDefaults standardUserDefaults] setObject:name forKey:k_key_fontName];
    [[NSUserDefaults standardUserDefaults] setFloat:size forKey:k_key_fontSize];
    [self setFontFamilyNameAndSize];
}



#pragma mark Private Methods

//------------------------------------------------------
/// メインウィンドウのフォントファミリー名とサイズをprefFontFamilyNameSizeに表示させる
- (void)setFontFamilyNameAndSize
//------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize];
    NSFont *font = [NSFont fontWithName:name size:size];
    NSString *localizedName = [font displayName];
    
    [[self fontField] setStringValue:[NSString stringWithFormat:@"%@ %g", localizedName, size]];
    [[self fontField] setFont:[NSFont fontWithName:name size:13.0]];
}

@end
