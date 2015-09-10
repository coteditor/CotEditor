/*
 
 CEIncompatibleCharsViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEIncompatibleCharsViewController.h"
#import "CEDocument.h"
#import "Constants.h"


@interface CEIncompatibleCharsViewController () <NSTableViewDelegate>

@property (nonatomic, nullable) NSTimer *updateTimer;
@property (nonatomic, getter=isCharAvailable) BOOL charAvailable;

@property (nonatomic, nullable) IBOutlet NSArrayController *incompatibleCharsController;

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
    NSArray<NSDictionary<NSString *, NSValue *> *> *contents = [[self document] findCharsIncompatibleWithEncoding:[[self document] encoding]];
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    for (NSDictionary<NSString *, NSValue *> *incompatible in contents) {
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
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSArray<NSDictionary<NSString *, NSValue *> *> *selectedIncompatibles = [[self incompatibleCharsController] selectedObjects];
    
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
/// update incompatible chars afer interval
- (void)updateWithTimer:(nonnull NSTimer *)timer
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
