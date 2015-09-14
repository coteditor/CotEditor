/*
 
 CESyntaxEditTableViewDelegate.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-09-08.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 1024jp
 
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

#import "CESyntaxEditTableViewDelegate.h"


@implementation CESyntaxEditTableViewDelegate

#pragma mark Delegate

// ------------------------------------------------------
/// selection did change
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];
    
    if (row == -1) { return; }
    
    // the last row is selected
    if ((row + 1) == [tableView numberOfRows]) {
        [tableView scrollRowToVisible:row];
        
        // proceed on the next run loop
        // (since the string of the selected cell cannot be read at this point)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTableCellView *cellView = [[tableView rowViewAtRow:row makeIfNecessary:NO] viewAtColumn:0];
            
            // start editing automatically if the leftmost cell of the added row is blank
            if ([[[cellView textField] stringValue] isEqualToString:@""]) {
                [tableView editColumn:0 row:row withEvent:nil select:YES];
            }
        });
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// click all selected checkboxes
- (IBAction)didCheckboxClicked:(nullable id)sender
// ------------------------------------------------------
{
    // To perform this action,
    // checkbox (NSBUtton) and column (NSTableColumn) must have the same identifier as the style dict key
    
    NSButton *checkbox = (NSButton *)sender;
    BOOL isChecked = ([checkbox state] == NSOnState);
    NSString *identifier = [checkbox identifier];
    
    // find tableview
    NSView *superview = [checkbox superview];
    NSTableView *tableView = nil;
    while (!tableView && superview) {
        if ([superview isKindOfClass:[NSTableView class]]) {
            tableView = (NSTableView *)superview;
        }
        superview = [superview superview];
    }
    
    if (([tableView numberOfSelectedRows] <= 1) || !identifier) { return; }
    
    NSInteger *columnIndex = [tableView columnWithIdentifier:identifier];
    
    [tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        if (![rowView isSelected]) { return; }
        
        NSTableCellView *view = [rowView viewAtColumn:columnIndex];
        [view objectValue][identifier] = @(isChecked);
    }];
}

@end
