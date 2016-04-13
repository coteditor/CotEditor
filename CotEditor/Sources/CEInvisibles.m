/*
 
 CEInvisibles.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
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

#import "CEInvisibles.h"


// Substitutes for invisible characters
static unichar const kInvisibleSpaceCharList[] = {0x00B7, 0x00B0, 0x02D0, 0x2423};
static NSUInteger const kSizeOfInvisibleSpaceCharList = sizeof(kInvisibleSpaceCharList) / sizeof(unichar);

static unichar const kInvisibleTabCharList[] = {0x00AC, 0x21E5, 0x2023, 0x25B9};
static NSUInteger const kSizeOfInvisibleTabCharList = sizeof(kInvisibleTabCharList) / sizeof(unichar);

static unichar const kInvisibleNewLineCharList[] = {0x00B6, 0x21A9, 0x21B5, 0x23CE};
static NSUInteger const kSizeOfInvisibleNewLineCharList = sizeof(kInvisibleNewLineCharList) / sizeof(unichar);

static unichar const kInvisibleFullwidthSpaceCharList[] = {0x25A1, 0x22A0, 0x25A0, 0x25B3};
static NSUInteger const kSizeOfInvisibleFullwidthSpaceCharList = sizeof(kInvisibleFullwidthSpaceCharList) / sizeof(unichar);

static unichar const kVerticalTabChar = 0x240B;  // symbol for vertical tablation
static unichar const kReplacementChar = 0xFFFD;  // symbol for "Other Invisibles" (NSControlGlyph)


@implementation CEInvisibles

#pragma mark Public Methods

// ------------------------------------------------------
/// returns substitute character as NSString
+ (nonnull NSString *)stringWithType:(CEInvisibleType)type Index:(NSUInteger)index
// ------------------------------------------------------
{
    unichar character;
    switch (type) {
        case CEInvisibleSpace:
            character = [self spaceCharWithIndex:index];
            break;
        case CEInvisibleTab:
            character = [self tabCharWithIndex:index];
            break;
        case CEInvisibleNewLine:
            character = [self newLineCharWithIndex:index];
            break;
        case CEInvisibleFullWidthSpace:
            character = [self fullwidthSpaceCharWithIndex:index];
            break;
        case CEInvisibleVerticalTab:
            character = [self verticalTabChar];
            break;
        case CEInvisibleReplacement:
            character = [self replacementChar];
            break;
    }
    
    return [NSString stringWithCharacters:&character length:1];
}


// ------------------------------------------------------
/// returns substitute character for invisible space
+ (unichar)spaceCharWithIndex:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleSpaceCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleSpaceCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible tab character
+ (unichar)tabCharWithIndex:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleTabCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleTabCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible new line character
+ (unichar)newLineCharWithIndex:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleNewLineCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleNewLineCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible full-width space
+ (unichar)fullwidthSpaceCharWithIndex:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleFullwidthSpaceCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleFullwidthSpaceCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible vertical tab to display
+ (unichar)verticalTabChar
// ------------------------------------------------------
{
    return kVerticalTabChar;
}


// ------------------------------------------------------
/// returns substitute character for general invisible character
+ (unichar)replacementChar
// ------------------------------------------------------
{
    return kReplacementChar;
}


// ------------------------------------------------------
/// all available substitution characters for space
+ (nonnull NSArray<NSString *> *)spaceStrings
// ------------------------------------------------------
{
    static NSArray<NSString *> *strings = nil;
    if (!strings) {
        strings = stringArrayFromChars(kInvisibleSpaceCharList);
    }
    
    return strings;
}


// ------------------------------------------------------
/// all available substitution characters for tab
+ (nonnull NSArray<NSString *> *)tabStrings
// ------------------------------------------------------
{
    static NSArray<NSString *> *strings = nil;
    if (!strings) {
        strings = stringArrayFromChars(kInvisibleTabCharList);
    }
    
    return strings;
}


// ------------------------------------------------------
/// all available substitution characters for new line character
+ (nonnull NSArray<NSString *> *)newLineStrings
// ------------------------------------------------------
{
    static NSArray<NSString *> *strings = nil;
    if (!strings) {
        strings = stringArrayFromChars(kInvisibleNewLineCharList);
    }
    
    return strings;
}


// ------------------------------------------------------
/// all available substitution characters for full-width space
+ (nonnull NSArray<NSString *> *)fullwidthSpaceStrings
// ------------------------------------------------------
{
    static NSArray<NSString *> *strings = nil;
    if (!strings) {
        strings = stringArrayFromChars(kInvisibleFullwidthSpaceCharList);
    }
    
    return strings;
}



#pragma mark Private Functions

//------------------------------------------------------
/// create array of single-length-NSString from unichars
NSArray<NSString *> *stringArrayFromChars(const unichar *characters)
//------------------------------------------------------
{
    NSUInteger length = sizeof(characters) / sizeof(unichar);
    NSMutableArray<NSString *> *mutableStrings = [NSMutableArray arrayWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        NSUInteger max = length - 1;
        NSUInteger sanitizedIndex = MIN(max, i);
        unichar character = characters[sanitizedIndex];
        
        [mutableStrings addObject:[NSString stringWithFormat:@"%C", character]];
    }
    return [NSArray arrayWithArray:mutableStrings];
}

@end
