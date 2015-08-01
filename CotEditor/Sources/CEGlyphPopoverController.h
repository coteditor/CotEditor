/*
 
 CEGlyphPopoverController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-01.

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
#import "NSString+ComposedCharacter.h"


@interface CEGlyphPopoverController : NSViewController

/// default initializer (singleString must be a single character (or a surrogate-pair). If not, return nil.)
- (nullable instancetype)initWithCharacter:(nonnull NSString *)singleString;

/// show popover
- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(nonnull NSView *)parentView;

@end
