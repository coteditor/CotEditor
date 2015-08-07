/*
 
 CEFindPanelController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-30.

 ------------------------------------------------------------------------------
 
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
- (IBAction)showFindPanel:(nullable id)sender;
- (IBAction)findNext:(nullable id)sender;
- (IBAction)findPrevious:(nullable id)sender;
- (IBAction)findSelectedText:(nullable id)sender;
- (IBAction)findAll:(nullable id)sender;
- (IBAction)useSelectionForFind:(nullable id)sender;
- (IBAction)useSelectionForReplace:(nullable id)sender;
- (IBAction)replace:(nullable id)sender;
- (IBAction)replaceAll:(nullable id)sender;
- (IBAction)replaceAndFind:(nullable id)sender;
- (IBAction)highlight:(nullable id)sender;
- (IBAction)unhighlight:(nullable id)sender;

@end
