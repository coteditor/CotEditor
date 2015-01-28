/*
 ==============================================================================
 CEUtils
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-20 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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
+ (NSStringEncoding)encodingFromName:(NSString *)encodingName;

/// whether Yen sign (U+00A5) can be converted to the given encoding
+ (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding;

/// returns string form keyEquivalent (keyboard shortcut) for menu item
+ (NSString *)keyEquivalentAndModifierMask:(NSUInteger *)modifierMask
                                fromString:(NSString *)string
                       includingCommandKey:(BOOL)needsIncludingCommandKey;

@end
