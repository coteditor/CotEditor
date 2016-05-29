/*
 
 CEProgressSheetController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-06-07.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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


@interface CEProgressSheetController : NSWindowController <NSWindowDelegate>

- (nonnull instancetype)initWithProgress:(nonnull NSProgress *)progress message:(nonnull NSString *)message;


- (void)beginSheetForWindow:(nonnull NSWindow *)window;

// change button to done
- (void)doneWithButtonTitle:(nullable NSString *)title;


// action messages
- (IBAction)close:(nullable id)sender;
- (IBAction)cancel:(nullable id)sender;

@end
