/*
 
 CEDocumentController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-14.

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

@import Cocoa;


@interface CEDocumentController : NSDocumentController

// readonly
@property (readonly, nonatomic) NSStringEncoding accessorySelectedEncoding;
@property (readonly, nonatomic, nonnull) NSURL *autosaveDirectoryURL;

// Action Message
- (IBAction)openHiddenDocument:(nullable id)sender;

@end
