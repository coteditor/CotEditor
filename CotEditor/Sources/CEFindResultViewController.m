/*
 ==============================================================================
 CEFindResultViewController
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-04 by 1024jp
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

#import <OgreKit/OgreKit.h>
#import "CEFindResultViewController.h"

/// the maximum number of characters to add to the left of the matched string
static const int kMaxLeftMargin = 64;
/// maximal number of characters for the result line
static const int kMaxMatchedStringLength = 256;


// hack OgreKit's private OgreTextViewFindResult class (cf. OgreTextViewFindResult.h in OgreKit framewrok source)
@protocol OgreTextViewFindResultInterface <NSObject>

// index番目にマッチした文字列のある行番号
- (NSNumber*)lineOfMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列
- (NSAttributedString *)matchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択・表示する
- (BOOL)showMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択する
- (BOOL)selectMatchedStringAtIndex:(unsigned)index;

@end


#pragma mark -

@interface CEFindResultViewController () <OgreTextFindResultDelegateProtocol>

@property (nonatomic, copy) NSString *resultMessage;
@property (nonatomic, copy) NSString *findString;
@property (nonatomic, copy) NSString *documentName;
@property (nonatomic) NSUInteger count;
@property (nonatomic) BOOL enableLiveUpdate;

@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@end




#pragma mark -

@implementation CEFindResultViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[self result] setDelegate:nil];
}



#pragma mark Public Accessors

// ------------------------------------------------------
/// setter for result property
- (void)setResult:(OgreTextFindResult *)result
// ------------------------------------------------------
{
    [result setMaximumLeftMargin:kMaxLeftMargin];
    [result setMaximumMatchedStringLength:kMaxMatchedStringLength];
    [result setDelegate:self];
    
    _result = result;
    
    [self reloadResult];
}



#pragma mark Protocol

//=======================================================
// NSTableViewDataSource Protocol
//=======================================================

// ------------------------------------------------------
/// return number of row (required)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
// ------------------------------------------------------
{
    // [note] This method `selectMatchedString` in fact just returns whether textView exists yet and do nothing else.
    BOOL existsTarget = [[self textViewResult] selectMatchedString];
    
    if ([self enableLiveUpdate] && !existsTarget) {
        return 1;
    }
    
    return [[self result] numberOfMatches];
}


// ------------------------------------------------------
/// return value of cell (required)
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
// ------------------------------------------------------
{
    if (![self result]) { return nil; }
    
    OgreFindResultBranch<OgreTextViewFindResultInterface> *textViewResult = [self textViewResult];
    BOOL existsTarget = [textViewResult selectMatchedString];
    
    if ([[tableColumn identifier] isEqualToString:@"line"]) {
        return existsTarget ? [textViewResult lineOfMatchedStringAtIndex:row] : nil;
    } else {
        return [textViewResult matchedStringAtIndex:row];
    }
}



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < tableView
//=======================================================

// ------------------------------------------------------
/// select matched string in text view
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];
    
    if (row > [self count]) { return; }
    
    OgreFindResultBranch<OgreTextViewFindResultInterface> *result = [self textViewResult];
    
    if (![result selectMatchedString]) {
        NSBeep();
        return;
    }
    
    NSTextView *textView = [self target];
    dispatch_async(dispatch_get_main_queue(), ^{
        [result selectMatchedStringAtIndex:row];
        [textView showFindIndicatorForRange:[textView selectedRange]];
    });
}


//=======================================================
// OgreTextFindResultDelegateProtocol  < result
//=======================================================

// ------------------------------------------------------
/// live update
- (void)didUpdateTextFindResult:(id)textFindResult
// ------------------------------------------------------
{
    if ([self enableLiveUpdate]) {
        [self reloadResult];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return text view result adding interface for OgreKit private class
- (OgreFindResultBranch<OgreTextViewFindResultInterface> *)textViewResult
// ------------------------------------------------------
{
    return [[[self result] result] childAtIndex:0 inSelection:NO];
}


// ------------------------------------------------------
/// apply actual result to UI
- (void)reloadResult
// ------------------------------------------------------
{
    if (![self result]) { return; }
    
    [self setFindString:[[self result] findString]];
    [self setCount:[[self result] numberOfMatches]];
    [self setDocumentName:[[self result] title]];
    
    NSString *message;
    if ([self count] == 0) {
        message = [NSString stringWithFormat:NSLocalizedString(@"No strings found in “%@”.", nil), [self documentName]];
    } else if ([self count] == 1) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Found one string in “%@”.", nil), [self documentName]];
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"Found %li strings in “%@”.", nil), [self count], [self documentName]];
    }
    [self setResultMessage:message];
    
    [[self tableView] reloadData];
}

@end
