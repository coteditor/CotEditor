/*
 
 CENavigationBarController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-08-22.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CENavigationBarController.h"
#import "CEOutlineItem.h"
#import "Constants.h"

#import "NSFont+CESize.h"


static const CGFloat kDefaultHeight = 16.0;
static const NSTimeInterval kDuration = 0.12;


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
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// view is loaded
- (void)awakeFromNib
// ------------------------------------------------------
{
    [super awakeFromNib];
    
    // hide as default (avoid flick)
    [[self prevButton] setHidden:YES];
    [[self nextButton] setHidden:YES];
    [[self outlineMenu] setHidden:YES];
    
    [[self outlineIndicator] setUsesThreadedAnimation:YES];
    
    // observe text selection change to update outline menu selection
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidateOutlineMenuSelection)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:[self textView]];
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
- (void)setOutlineItems:(nonnull NSArray<CEOutlineItem *> *)outlineItems
// ------------------------------------------------------
{
    // stop outline extracting indicator
    [[self outlineIndicator] stopAnimation:self];
    [[self outlineLoadingMessage] setHidden:YES];
    
    [[self outlineMenu] removeAllItems];
    
    BOOL hasOutlineItems = [outlineItems count];
    // set buttons status here to avoid flicking (2008-05-17)
    [[self outlineMenu] setHidden:!hasOutlineItems];
    [[self prevButton] setHidden:!hasOutlineItems];
    [[self nextButton] setHidden:!hasOutlineItems];
    
    if (!hasOutlineItems) { return; }
    
    NSMenu *menu = [[self outlineMenu] menu];
    
    static NSMutableParagraphStyle *paragraphStyle;
    if (!paragraphStyle) {
        // generate paragraphStyle only once to avoid calling `spaceAdvancement` every time
        paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setTabStops:@[]];
        [paragraphStyle setDefaultTabInterval:2 * [[menu font] advancementForCharacter:' ']];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [paragraphStyle setTighteningFactorForTruncation:0];  // don't tighten
    }
    NSDictionary<NSString *, id> *baseAttributes = @{NSFontAttributeName: [menu font],
                                                     NSParagraphStyleAttributeName: paragraphStyle};
    
    // add headding item
    [menu addItemWithTitle:NSLocalizedString(@"<Outline Menu>", nil)
                    action:@selector(selectOutlineMenuItem:)
             keyEquivalent:@""];
    [[menu itemAtIndex:0] setTarget:self];
    [[menu itemAtIndex:0] setRepresentedObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
    
    // add outline items
    for (CEOutlineItem *outlineItem in outlineItems) {
        if ([[outlineItem title] isEqualToString:CESeparatorString]) {
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
        
        NSRange titleRange = NSMakeRange(0, [[outlineItem title] length]);
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:[outlineItem title]
                                                                                      attributes:baseAttributes];
        
        NSFontTraitMask fontTrait = 0;
        fontTrait |= [outlineItem isBold] ? NSBoldFontMask : 0;
        fontTrait |= [outlineItem isItalic] ? NSItalicFontMask : 0;
        [attrTitle applyFontTraits:fontTrait range:titleRange];
        
        if ([outlineItem hasUnderline]) {
            [attrTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:titleRange];
        }
        
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        [menuItem setAttributedTitle:attrTitle];
        [menuItem setAction:@selector(selectOutlineMenuItem:)];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:[NSValue valueWithRange:[outlineItem range]]];
        
        [menu addItem:menuItem];
    }
    
    [self invalidateOutlineMenuSelection];
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
/// select outline menu item via pupup menu
- (IBAction)selectOutlineMenuItem:(nullable id)sender
// ------------------------------------------------------
{
    NSValue *value = [sender representedObject];
    
    if (!value) { return; }
    
    NSRange range = [value rangeValue];
    NSTextView *textView = [self textView];
    
    [textView setSelectedRange:range];
    [textView centerSelectionInVisibleArea:textView];
    [[textView window] makeFirstResponder:textView];
}


// ------------------------------------------------------
/// set select prev item of outline menu
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
/// set select next item of outline menu
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



#pragma mark Private Methods

// ------------------------------------------------------
/// set outline menu selection
- (void)invalidateOutlineMenuSelection
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) { return; }
    if ([[[self outlineMenu] menu] numberOfItems] == 0) { return; }
    
    NSRange range = [[self textView] selectedRange];
    __block NSInteger index = 0;
    [[[[self outlineMenu] menu] itemArray] enumerateObjectsWithOptions:NSEnumerationReverse
                                                            usingBlock:^(NSMenuItem * _Nonnull menuItem,
                                                                         NSUInteger idx,
                                                                         BOOL * _Nonnull stop)
     {
         if ([menuItem isSeparatorItem]) { return; }
         
         NSRange itemRange = [[menuItem representedObject] rangeValue];
         
         if (itemRange.location <= range.location) {
             index = idx;
             *stop = YES;
         }
     }];
    
    [[self outlineMenu] selectItemAtIndex:index];
    [self updatePrevNextButtonEnabled];
}

@end
