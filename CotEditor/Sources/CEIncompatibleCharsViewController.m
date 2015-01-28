/*
 ==============================================================================
 CEIncompatibleCharsViewController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 1024jp
 
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

#import "CEIncompatibleCharsViewController.h"
#import "CEDocument.h"
#import "constants.h"


@interface CEIncompatibleCharsViewController () <NSTableViewDelegate>

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic, getter=isCharAvailable) BOOL charAvailable;

@property (nonatomic) IBOutlet NSArrayController *incompatibleCharsController;

@end




#pragma mark -

@implementation CEIncompatibleCharsViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [self stopUpdateTimer];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// force scan incompatible chars and update immediately
- (void)update
// ------------------------------------------------------
{
    NSArray *contents = [[self document] findCharsIncompatibleWithEncoding:[[self document] encoding]];
    
    NSMutableArray *ranges = [NSMutableArray array];
    for (NSDictionary *incompatible in contents) {
        [ranges addObject:incompatible[CEIncompatibleRangeKey]];
    }
    [[[self document] editor] clearAllMarkup];
    [[[self document] editor] markupRanges:ranges];
    
    [[self incompatibleCharsController] setContent:contents];
    [self setCharAvailable:([contents count] > 0)];
}


// ------------------------------------------------------
/// set update timer only if needed
- (void)updateIfNeeded
// ------------------------------------------------------
{
    if (![[self view] superview]) { return; }
    
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultIncompatibleCharIntervalKey];
    
    if ([self updateTimer]) {
        [[self updateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    } else {
        [self setUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                              target:self
                                                            selector:@selector(updateWithTimer:)
                                                            userInfo:nil
                                                             repeats:NO]];
    }
}



#pragma mark Delegate

// ------------------------------------------------------
/// select correspondent char in text view
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    NSArray *selectedIncompatibles = [[self incompatibleCharsController] selectedObjects];
    
    if ([selectedIncompatibles count] == 0) { return; }
    
    NSRange range = [[selectedIncompatibles firstObject][CEIncompatibleRangeKey] rangeValue];
    CEEditorWrapper *editor = [[self document] editor];
    NSTextView *textView = [editor focusedTextView];
    
    [editor setSelectedRange:range];
    [[[self view] window] makeFirstResponder:textView];
    
    // focus result (`range` is incompatible with CR/LF)
    [textView scrollRangeToVisible:[textView selectedRange]];
    [textView showFindIndicatorForRange:[textView selectedRange]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return represented document instance
- (CEDocument *)document
// ------------------------------------------------------
{
    return [self representedObject];
}


// ------------------------------------------------------
/// update incompatible chars afer interval
- (void)updateWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopUpdateTimer];
    [self update];
}


// ------------------------------------------------------
/// stop update timer
- (void)stopUpdateTimer
// ------------------------------------------------------
{
    if ([self updateTimer]) {
        [[self updateTimer] invalidate];
        [self setUpdateTimer:nil];
    }
}

@end
