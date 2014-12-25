/*
 ==============================================================================
 CEPanelController
 
 This class is an abstract class for panels related to document.
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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
#import "CEWindowController.h"


@interface CEPanelController : NSWindowController <NSWindowDelegate>

@property (readonly, nonatomic, weak) CEWindowController *documentWindowController;


// singleton
+ (instancetype)sharedController;


// (abstract) invoke when frontmost document window changed
- (void)keyDocumentDidChange;

@end
