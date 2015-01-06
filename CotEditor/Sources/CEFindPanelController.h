/*
 ==============================================================================
 CEFindPanelController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-30 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@import Cocoa;
#import <OgreKit/OgreKit.h>


typedef NS_ENUM(NSInteger, CETextFinderAction) {
    CETextFinderActionSetReplacementString = 100,
    CETextFinderActionFindSelectedText,
    CETextFinderActionFindAll,
    CETextFinderActionSetHighlight,
    CETextFinderActionSetUnhighlight,
};


@interface CEFindPanelController : OgreFindPanelController

// action messages
- (IBAction)showFindPanel:(id)sender;
- (IBAction)findNext:(id)sender;
- (IBAction)findPrevious:(id)sender;
- (IBAction)findSelectedText:(id)sender;
- (IBAction)findAll:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)useSelectionForReplace:(id)sender;
- (IBAction)replace:(id)sender;
- (IBAction)replaceAll:(id)sender;
- (IBAction)replaceAndFind:(id)sender;
- (IBAction)highlight:(id)sender;
- (IBAction)unhighlight:(id)sender;

@end
