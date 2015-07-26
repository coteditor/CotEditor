/*
 ==============================================================================
 CENavigationBarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-08-22 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CENavigationBarController.h"
#import "Constants.h"


static const CGFloat kDefaultHeight = 16.0;
static const NSTimeInterval kDuration = 0.25;


@interface CENavigationBarController ()

@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *outlineMenu;
@property (nonatomic, nullable, weak) IBOutlet NSButton *prevButton;
@property (nonatomic, nullable, weak) IBOutlet NSButton *nextButton;
@property (nonatomic, nullable, weak) IBOutlet NSButton *openSplitButton;
@property (nonatomic, nullable, weak) IBOutlet NSButton *closeSplitButton;
@property (nonatomic, nullable, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic, nullable, weak) IBOutlet NSProgressIndicator *outlineIndicator;
@property (nonatomic, nullable, weak) IBOutlet NSTextField *outlineLoadingMessage;

// readonly
@property (readwrite, nonatomic, getter=isShown) BOOL shown;

@end




#pragma mark -

@implementation CENavigationBarController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// designated initializer
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithNibName:@"NavigationBar" bundle:nil];
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    _textView = nil;
}


// ------------------------------------------------------
/// view is loaded
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // hide as default (avoid flick)
    [[self prevButton] setHidden:YES];
    [[self nextButton] setHidden:YES];
    [[self outlineMenu] setHidden:YES];
    
    [[self outlineIndicator] setUsesThreadedAnimation:YES];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// set to show navigation bar.
- (void)setShown:(BOOL)isShown animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    [self setShown:isShown];
    
    NSLayoutConstraint *heightConstraint = [self heightConstraint];
    CGFloat height = [self isShown] ? kDefaultHeight : 0.0;
    
    if (performAnimation) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:kDuration];
            [[heightConstraint animator] setConstant:height];
        } completionHandler:nil];
        
    } else {
        [heightConstraint setConstant:height];
    }
}


// ------------------------------------------------------
/// build outline menu from given array
- (void)setOutlineMenuArray:(nonnull NSArray *)outlineItems
// ------------------------------------------------------
{
    // stop outline extracting indicator
    [[self outlineIndicator] stopAnimation:self];
    [[self outlineLoadingMessage] setHidden:YES];
    
    [[self outlineMenu] removeAllItems];
    
    if ([outlineItems count] == 0) {
        [[self outlineMenu] setHidden:YES];
        [[self prevButton] setHidden:YES];
        [[self nextButton] setHidden:YES];
        
        return;
    }
    
    NSMenu *menu = [[self outlineMenu] menu];
    NSFont *defaultFont = [NSFont fontWithName:kNavigationBarFontName
                                          size:[NSFont smallSystemFontSize]];
    
    // add headding item
    [menu addItemWithTitle:NSLocalizedString(@"<Outline Menu>", nil)
                    action:@selector(setSelectedRangeWithNSValue:)
             keyEquivalent:@""];
    [[menu itemAtIndex:0] setTarget:[self textView]];
    [[menu itemAtIndex:0] setRepresentedObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
    
    // add outline items
    for (NSDictionary *outlineItem in outlineItems) {
        if ([outlineItem[CEOutlineItemTitleKey] isEqualToString:CESeparatorString]) {
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
        
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        
        NSFontTraitMask fontTrait = [outlineItem[CEOutlineItemStyleBoldKey] boolValue] ? NSBoldFontMask : 0;
        fontTrait |= [outlineItem[CEOutlineItemStyleItalicKey] boolValue] ? NSItalicFontMask : 0;
        NSFont *font = [[NSFontManager sharedFontManager] convertFont:defaultFont toHaveTrait:fontTrait];
        attrs[NSFontAttributeName] = font;
        
        if ([outlineItem[CEOutlineItemStyleUnderlineKey] boolValue]) {
            attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineByWordMask | NSUnderlinePatternSolid | NSUnderlineStyleThick);
        }
        
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:outlineItem[CEOutlineItemTitleKey]
                                                                    attributes:attrs];
        
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        [menuItem setAttributedTitle:title];
        [menuItem setAction:@selector(setSelectedRangeWithNSValue:)];
        [menuItem setTarget:[self textView]];
        [menuItem setRepresentedObject:outlineItem[CEOutlineItemRangeKey]];
        
        [menu addItem:menuItem];
    }
    
    // set buttons status here to avoid flicking (2008-05-17)
    [self selectOutlineMenuItemWithRange:[[self textView] selectedRange]];
    [[self outlineMenu] setMenu:menu];
    [[self outlineMenu] setHidden:NO];
    [[self prevButton] setHidden:NO];
    [[self nextButton] setHidden:NO];
}


// ------------------------------------------------------
/// set outline menu selection
- (void)selectOutlineMenuItemWithRange:(NSRange)range
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) { return; }
    
    NSMenu *menu = [[self outlineMenu] menu];
    NSInteger count = [menu numberOfItems];
    if (count < 1) { return; }
    NSInteger index;

    if (NSEqualRanges(range, NSMakeRange(0, 0))) {
        index = 1;
    } else {
        for (index = 1; index < count; index++) {
            NSMenuItem *menuItem = [menu itemAtIndex:index];
            NSRange itemRange = [[menuItem representedObject] rangeValue];
            if (itemRange.location > range.location) {
                break;
            }
        }
    }
    // ループを抜けた時点で「次のアイテムインデックス」になっているので、減ずる
    index--;
    // skip separators
    while ([[[self outlineMenu] itemAtIndex:index] isSeparatorItem]) {
        index--;
        if (index < 0) {
            break;
        }
    }
    [[self outlineMenu] selectItemAtIndex:index];
    [self updatePrevNextButtonEnabled];
}


// ------------------------------------------------------
/// update enabilities of jump buttons
- (void)updatePrevNextButtonEnabled
// ------------------------------------------------------
{
    [[self prevButton] setEnabled:[self canSelectPrevItem]];
    [[self nextButton] setEnabled:[self canSelectNextItem]];
}


// ------------------------------------------------------
/// can select prev item in outline menu?
- (BOOL)canSelectPrevItem
// ------------------------------------------------------
{
    return ([[self outlineMenu] indexOfSelectedItem] > 1);
}


// ------------------------------------------------------
/// can select next item in outline menu?
- (BOOL)canSelectNextItem
// ------------------------------------------------------
{
    for (NSInteger i = ([[self outlineMenu] indexOfSelectedItem] + 1); i < [[self outlineMenu] numberOfItems]; i++) {
        if (![[[self outlineMenu] itemAtIndex:i] isSeparatorItem]) {
            return YES;
        }
    }
    return NO;
}


// ------------------------------------------------------
/// start displaying outline indicator
- (void)showOutlineIndicator
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) {
        [[self outlineIndicator] startAnimation:self];
        [[self outlineLoadingMessage] setHidden:NO];
    }
}


// ------------------------------------------------------
/// set closeSplitButton enabled or disabled
- (void)setCloseSplitButtonEnabled:(BOOL)enabled
// ------------------------------------------------------
{
    [[self closeSplitButton] setHidden:!enabled];
}


// ------------------------------------------------------
/// set image of open split view button
- (void)setSplitOrientationVertical:(BOOL)isVertical
// ------------------------------------------------------
{
    NSString *imageName = isVertical ? @"OpenSplitVerticalTemplate" : @"OpenSplitTemplate";
    
    [[self openSplitButton] setImage:[NSImage imageNamed:imageName]];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// set select prev item of outline menu.
- (IBAction)selectPrevItem:(nullable id)sender
// ------------------------------------------------------
{
    if (![self canSelectPrevItem]) { return; }
    
    NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] - 1;
    
    while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
        targetIndex--;
        if (targetIndex < 0) {
            break;
        }
    }
    [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
}


// ------------------------------------------------------
/// set select next item of outline menu.
- (IBAction)selectNextItem:(nullable id)sender
// ------------------------------------------------------
{
    if (![self canSelectNextItem]) { return; }
    
    NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] + 1;
    NSInteger maxIndex = [[self outlineMenu] numberOfItems] - 1;
    
    while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
        targetIndex++;
        if (targetIndex > maxIndex) {
            break;
        }
    }
    [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
}

@end
