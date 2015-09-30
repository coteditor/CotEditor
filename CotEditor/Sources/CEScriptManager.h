/*
 
 CEScriptManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-12.

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


@interface CEScriptManager : NSObject

// singleton
+ (nonnull instancetype)sharedManager;


// Public method
- (void)buildScriptMenu:(nullable id)sender;
- (nullable NSMenu *)contexualMenu;


// Action Message
- (IBAction)launchScript:(nullable id)sender;
- (IBAction)openScriptFolder:(nullable id)sender;

@end
