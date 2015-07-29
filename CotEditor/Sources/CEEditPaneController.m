/*
 ==============================================================================
 CEEditPaneController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-18 by 1024jp
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

#import "CEEditPaneController.h"
#import "CEUtils.h"
#import "Constants.h"


@interface CEEditPaneController ()

@property (nonatomic, nullable, weak) IBOutlet NSButton *smartQuoteCheckButton;

@property (nonatomic, nonnull, copy) NSArray *invisibleSpaces;
@property (nonatomic, nonnull, copy) NSArray *invisibleTabs;
@property (nonatomic, nonnull, copy) NSArray *invisibleNewLines;
@property (nonatomic, nonnull, copy) NSArray *invisibleFullWidthSpaces;

@end




#pragma mark -

@implementation CEEditPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // setup popup menu items for invisible characters
        NSMutableArray *spaces = [NSMutableArray arrayWithCapacity:kSizeOfInvisibleSpaceCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleSpaceCharList; i++) {
            [spaces addObject:[NSString stringWithFormat:@"%C", [CEUtils invisibleSpaceChar:i]]];
        }
        _invisibleSpaces = spaces;
        
        NSMutableArray *tabs = [NSMutableArray arrayWithCapacity:kSizeOfInvisibleTabCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleTabCharList; i++) {
            [tabs addObject:[NSString stringWithFormat:@"%C", [CEUtils invisibleTabChar:i]]];
        }
        _invisibleTabs = tabs;
        
        NSMutableArray *newLines = [NSMutableArray arrayWithCapacity:kSizeOfInvisibleNewLineCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleNewLineCharList; i++) {
            [newLines addObject:[NSString stringWithFormat:@"%C", [CEUtils invisibleNewLineChar:i]]];
        }
        _invisibleNewLines = newLines;
        
        NSMutableArray *fullWidthSpaces = [NSMutableArray arrayWithCapacity:kSizeOfInvisibleFullwidthSpaceCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleFullwidthSpaceCharList; i++) {
            [fullWidthSpaces addObject:[NSString stringWithFormat:@"%C", [CEUtils invisibleFullwidthSpaceChar:i]]];
        }
        _invisibleFullWidthSpaces = fullWidthSpaces;
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // disable Smart Quotes/Dashes setting on under Mavericks
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
        [[self smartQuoteCheckButton] setEnabled:NO];
        [[self smartQuoteCheckButton] setState:NSOffState];
        [[self smartQuoteCheckButton] setTitle:[NSString stringWithFormat:@"%@%@", [[self smartQuoteCheckButton] title],
                                                NSLocalizedString(@" (on Mavericks and later)", nil)]];
    }
}

@end
