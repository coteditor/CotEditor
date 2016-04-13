/*
 
 CEFindResultViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-04.

 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

#import "CEFindResultViewController.h"
#import "CETextFinder.h"


/// the maximum number of characters to add to the left of the matched string
static const int kMaxLeftMargin = 32;
/// maximal number of characters for the result line
static const int kMaxMatchedStringLength = 256;


#pragma mark -

@interface CEFindResultViewController ()

@property (nonatomic, nullable, weak) NSLayoutManager *layoutManager;
@property (nonatomic, nullable, copy) NSString *resultMessage;
@property (nonatomic) NSUInteger count;

@property (nonatomic, nullable, weak) IBOutlet NSTableView *tableView;

@end




#pragma mark -

@implementation CEFindResultViewController

#pragma mark Public Accessors

// ------------------------------------------------------
/// setter for result property
- (void)setResult:(nullable NSArray<NSDictionary *> *)result
// ------------------------------------------------------
{
    _result = result;
    
    [self reloadResult];
}


// ------------------------------------------------------
/// set target textView of the result
- (void)setTarget:(nullable NSTextView *)target
// ------------------------------------------------------
{
    // keep layoutManager as `weak` instaed to avoid handling unsafe_unretained TextView
    [self setLayoutManager:[target layoutManager]];
}


// ------------------------------------------------------
/// target textView of the current result
- (nullable NSTextView *)target
// ------------------------------------------------------
{
    // keep layoutManager as `week` instaed to avoid handling unsafe_unretained TextView
    return [[self layoutManager] firstTextView];
}



#pragma mark Protocol

//=======================================================
// NSTableViewDataSource Protocol
//=======================================================

// ------------------------------------------------------
/// return number of row (required)
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView
// ------------------------------------------------------
{
    return [[self result] count];
}


// ------------------------------------------------------
/// return value of cell (required)
- (nullable id)tableView:(nonnull NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *result = [self result][row];
    
    if (!result) { return nil; }
    
    if ([[tableColumn identifier] isEqualToString:@"line"]) {
        return result[CEFindResultLineNumber];
    } else {
        NSMutableAttributedString *lineAttrString = [result[CEFindResultAttributedLineString] mutableCopy];
        NSRange inlineRange = [result[CEFindResultLineRange] rangeValue];
        
        // trim
        if (inlineRange.location > kMaxLeftMargin) {
            NSUInteger diff = inlineRange.location - kMaxLeftMargin;
            [lineAttrString replaceCharactersInRange:NSMakeRange(0, diff) withString:@"…"];
        }
        if ([lineAttrString length] > kMaxMatchedStringLength) {
            NSUInteger extra = [lineAttrString length] - kMaxMatchedStringLength;
            [lineAttrString replaceCharactersInRange:NSMakeRange(kMaxMatchedStringLength, extra) withString:@"…"];
        }
        
        // truncate tail
        NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [lineAttrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [lineAttrString length])];
        
        return lineAttrString;
    }
}



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < tableView
//=======================================================

// ------------------------------------------------------
/// select matched string in text view
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];
    
    if (row > [self count]) { return; }
    
    NSRange range = [(NSValue *)[self result][row][CEFindResultRange] rangeValue];
    
    NSTextView *textView = [self target];
    dispatch_async(dispatch_get_main_queue(), ^{
        [textView setSelectedRange:range];
        [textView centerSelectionInVisibleArea:nil];
        [textView showFindIndicatorForRange:range];
    });
}



#pragma mark Private Methods

// ------------------------------------------------------
/// apply actual result to UI
- (void)reloadResult
// ------------------------------------------------------
{
    if (![self result]) { return; }
    
    [self setCount:[[self result] count]];
    
    NSString *message;
    if ([self count] == 0) {
        message = [NSString stringWithFormat:NSLocalizedString(@"No strings found in “%@”.", nil), [self documentName]];
    } else if ([self count] == 1) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Found one string in “%@”.", nil), [self documentName]];
    } else {
        NSString *countStr = [NSString localizedStringWithFormat:@"%li", [self count]];
        message = [NSString stringWithFormat:NSLocalizedString(@"Found %@ strings in “%@”.", nil), countStr, [self documentName]];
    }
    [self setResultMessage:message];
    
    [[self tableView] reloadData];
}

@end
