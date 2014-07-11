/*
 =================================================
 CEStatusBarController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created on 2014-07-11 by 1024jp
 
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

#import "CEStatusBarController.h"
#import "CEByteCountTransformer.h"
#import "constants.h"


static const CGFloat defaultHeight = 20.0;
static const NSTimeInterval duration = 0.1;


@interface CEStatusBarController ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) IBOutlet NSNumberFormatter *decimalFormatter;
@property (nonatomic) CEByteCountTransformer *byteCountTransformer;

@property (nonatomic, copy) NSString *editorStatus;
@property (nonatomic, copy) NSString *documentStatus;

@end




#pragma mark -

@implementation CEStatusBarController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// init instance
- (instancetype)initWithCoder:(NSCoder *)aDecoder
// ------------------------------------------------------
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _showStatusBar = YES;
        _byteCountTransformer = [[CEByteCountTransformer alloc] init];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// update left side text
- (void)updateEditorStatus
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableString *status = [NSMutableString string];
    NSString *space = @"  ";
    NSNumberFormatter *formatter = [self decimalFormatter];
    
    if ([defaults boolForKey:k_key_showStatusBarLines]) {
        [status appendFormat:NSLocalizedString(@"Lines: %@", nil), [formatter stringFromNumber:@([self linesInfo])]];
        
        if ([self selectedLinesInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedLinesInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarChars]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Chars: %@", nil), [formatter stringFromNumber:@([self charsInfo])]];
        
        if ([self selectedCharsInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedCharsInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarLength]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Length: %@", nil), [formatter stringFromNumber:@([self lengthInfo])]];
        
        if ([self selectedLengthInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedLengthInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarWords]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Words: %@", nil), [formatter stringFromNumber:@([self wordsInfo])]];
        
        if ([self selectedWordsInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedWordsInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarLocation]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Location: %@", nil), [formatter stringFromNumber:@([self locationInfo])]];
    }
    if ([defaults boolForKey:k_key_showStatusBarLine]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Line: %@", nil), [formatter stringFromNumber:@([self lineInfo])]];
    }
    if ([defaults boolForKey:k_key_showStatusBarColumn]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Column: %@", nil), [formatter stringFromNumber:@([self columnInfo])]];
    }
    
    [self setEditorStatus:status];
}


// ------------------------------------------------------
/// update right side text
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *status = [NSMutableArray array];
    
    if ([defaults boolForKey:k_key_showStatusBarEncoding]) {
        [status addObject:[self encodingInfo]];
    }
    if ([defaults boolForKey:k_key_showStatusBarLineEndings]) {
        [status addObject:[self lineEndingsInfo]];
    }
    if ([defaults boolForKey:k_key_showStatusBarFileSize]) {
        [status addObject:([self fileSizeInfo] ?
                           [[self byteCountTransformer] transformedValue:@([self fileSizeInfo])] : @"-")];
    }
    
    [self setDocumentStatus:[status componentsJoinedByString:@"  "]];
}


// ------------------------------------------------------
/// update visibility
- (void)setShowStatusBar:(BOOL)showStatusBar
// ------------------------------------------------------
{
    _showStatusBar = showStatusBar;
    
    CGFloat height = [self showStatusBar] ? defaultHeight : 0.0;
    
    // resize with animation
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:duration];
        [[[self heightConstraint] animator] setConstant:height];
    } completionHandler:nil];
}

@end
