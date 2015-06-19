/*
 ==============================================================================
 CELineHeightTransformer
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-14 by 1024jp
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

#import "CELineHeightTransformer.h"


@implementation CELineHeightTransformer

#pragma mark Superclass Methods

// ------------------------------------------------------
/// Class of transformed value
+ (nonnull Class)transformedValueClass
// ------------------------------------------------------
{
    return [NSNumber class];
}


// ------------------------------------------------------
/// Can reverse transformeation?
+ (BOOL)allowsReverseTransformation
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// From line spacing to line height (NSNumber -> NSNumber)
- (nullable id)transformedValue:(nullable id)value
// ------------------------------------------------------
{
    if (!value) { return nil; }
    
    return @([value doubleValue] + 1.0);
}


// ------------------------------------------------------
/// From line height to line spacing (NSNumber -> NSNumber)
- (nullable id)reverseTransformedValue:(nullable id)value
// ------------------------------------------------------
{
    if (!value) { return nil; }
    
    return @([value doubleValue] - 1.0);
}

@end
