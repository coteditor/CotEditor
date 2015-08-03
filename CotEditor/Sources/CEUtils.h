/*
 
 CEUtils.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2014-04-20.
 
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

@import Foundation;


@interface CEUtils : NSObject

/// returns substitute character for invisible space to display
+ (unichar)invisibleSpaceChar:(NSUInteger)index;

/// returns substitute character for invisible tab character to display
+ (unichar)invisibleTabChar:(NSUInteger)index;

/// returns substitute character for invisible new line character to display
+ (unichar)invisibleNewLineChar:(NSUInteger)index;

/// returns substitute character for invisible full-width to display
+ (unichar)invisibleFullwidthSpaceChar:(NSUInteger)index;

/// returns corresponding NSStringEncoding from a encoding name
+ (NSStringEncoding)encodingFromName:(nonnull NSString *)encodingName;

/// whether Yen sign (U+00A5) can be converted to the given encoding
+ (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding;

/// returns string form keyEquivalent (keyboard shortcut) for menu item
+ (nonnull NSString *)keyEquivalentAndModifierMask:(nonnull NSUInteger *)modifierMask
                                fromString:(nonnull NSString *)string
                       includingCommandKey:(BOOL)needsIncludingCommandKey;

@end
