/*
 ==============================================================================
 CESyntaxEditTableViewDelegate
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-09-08 by 1024jp
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

#import "CESyntaxEditTableViewDelegate.h"


@implementation CESyntaxEditTableViewDelegate

#pragma mark Delegate

// ------------------------------------------------------
/// selection did change
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];
    
    /// the last row is selected
    if ((row + 1) == [tableView numberOfRows]) {
        [tableView scrollRowToVisible:row];
        
        // proceed on the next run loop
        // (since the string of the selected cell cannot be read at this point)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTableCellView *cellView = [[tableView rowViewAtRow:row makeIfNecessary:NO] viewAtColumn:0];
            
            /// start editing automatically if the leftmost cell of the added row is blank
            if ([[[cellView textField] stringValue] isEqualToString:@""]) {
                [tableView editColumn:0 row:row withEvent:nil select:YES];
            }
        });
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// click all selected checkboxes
- (IBAction)didCheckboxClicked:(id)sender
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
