/*
 
 CELineHeightTransformer.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-14.
 
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
