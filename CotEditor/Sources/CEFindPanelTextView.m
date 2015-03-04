/*
 ==============================================================================
 CEFindPanelTextView
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-03-04 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEFindPanelTextView.h"
#import "CEFindPanelController.h"
#import "constants.h"


@interface CEFindPanelTextView ()

@property (nonatomic) IBOutlet CEFindPanelController *findPanelController;

@end




#pragma mark -

@implementation CEFindPanelTextView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (instancetype)initWithCoder:(NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        // set system font (standard NSTextField behavior)
        NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        [self setFont:font];
        
        // set inset a bit like NSTextField (horizontal inset is added in CEFindPanelTextClipView)
        [self setTextContainerInset:NSMakeSize(0.0, 2.0)];
        
        // avoid wrapping
        [[self textContainer] setWidthTracksTextView:NO];
        [[self textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [self setHorizontallyResizable:YES];
    }
    return self;
}


// ------------------------------------------------------
/// view is on focus
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    // select whole string on focus (standard NSTextField behavior)
    [self setSelectedRange:NSMakeRange(0, [[self string] length])];
    
    return [super becomeFirstResponder];
}


// ------------------------------------------------------
/// view dismiss focus
- (BOOL)resignFirstResponder
// ------------------------------------------------------
{
    // clear current selection (standard NSTextField behavior)
    [self setSelectedRange:NSMakeRange(0, 0)];
    return [super resignFirstResponder];
}


// ------------------------------------------------------
/// swap '¥' with '\' if needed
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
// ------------------------------------------------------
{
    NSString *string = ([aString isKindOfClass:[NSAttributedString class]]) ? [aString string] : aString;
    
    // swap '¥' with '\' if needed
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSwapYenAndBackSlashKey] && ([string length] == 1)) {
        NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
        
        if ([string isEqualToString:@"\\"]) {
            string = yen;
        } else if ([string isEqualToString:yen]) {
            string = @"\\";
        }
    }
    
    [super insertText:string replacementRange:replacementRange];
}


// ------------------------------------------------------
/// jump to the next responder with tab key (standard NSTextField behavior)
- (void)insertTab:(id)sender
// ------------------------------------------------------
{
    [[self window] makeFirstResponder:[self nextKeyView]];
}


// ------------------------------------------------------
/// perform Find Next with return
- (void)insertNewline:(id)sender
// ------------------------------------------------------
{
    // -> do nothing if no findpanelController is connected (standard NSTextField behavior)
    if ([self findPanelController]) {
        [[self findPanelController] findNext:self];
    }
}

@end
