/*
 
 CETextView+Transformation.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
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

#import "CETextView.h"
#import "NSString+JapaneseTransform.h"
#import "NSString+Normalization.h"


@implementation CETextView (Transformation)

#pragma mark Action Messages

// ------------------------------------------------------
/// transform half-width roman characters in selection to full-width
- (IBAction)exchangeFullwidthRoman:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"To Fullwidth Roman", nil)
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring fullWidthRomanString];
     }];
}


// ------------------------------------------------------
/// transform full-width roman characters in selection to half-width
- (IBAction)exchangeHalfwidthRoman:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"To Halfwidth Roman", nil)
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring halfWidthRomanString];
     }];
}


// ------------------------------------------------------
/// transform Hiragana in selection to Katakana
- (IBAction)exchangeKatakana:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Hiragana to Katakana", nil)
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring katakanaString];
     }];
}


// ------------------------------------------------------
/// transform Katakana in selection to Hiragana
- (IBAction)exchangeHiragana:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Katakana to Hiragana", nil)
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring hiraganaString];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFD)
- (IBAction)normalizeUnicodeWithNFD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFD"
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring decomposedStringWithCanonicalMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFC)
- (IBAction)normalizeUnicodeWithNFC:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFC"
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring precomposedStringWithCanonicalMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFKD)
- (IBAction)normalizeUnicodeWithNFKD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKD"
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring decomposedStringWithCompatibilityMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFKC)
- (IBAction)normalizeUnicodeWithNFKC:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKC"
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring precomposedStringWithCompatibilityMapping];
     }];
}

// ------------------------------------------------------
/// Unicode normalization (NFKC_Casefold)
- (IBAction)normalizeUnicodeWithNFKCCF:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKC Casefold"
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring precomposedStringWithCompatibilityMappingWithCasefold];
     }];
}

// ------------------------------------------------------
/// Unicode normalization (Modified NFD)
- (IBAction)normalizeUnicodeWithModifiedNFD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Modified NFD", @"name of an Uniocode normalization type")
                          operationHandler:^NSString *(NSString * _Nonnull substring)
     {
         return [substring decomposedStringWithHFSPlusMapping];
     }];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// transform all selected strings and register to undo manager
- (void)transformSelectionWithActionName:(nullable NSString *)actionName operationHandler:(nonnull NSString *(^)(NSString * _Nonnull substring))operationHandler
// ------------------------------------------------------
{
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSMutableArray<NSValue *> *appliedRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray array];
    BOOL success = NO;
    NSInteger deltaLocation = 0;
    
    for (NSValue *rangeValue in selectedRanges) {
        NSRange range = [rangeValue rangeValue];
        
        if (range.length == 0) { continue; }
        
        NSString *substring = [[self string] substringWithRange:range];
        NSString *string = operationHandler(substring);
        
        if (string) {
            NSRange newRange = NSMakeRange(range.location - deltaLocation, [string length]);
            
            [strings addObject:string];
            [appliedRanges addObject:rangeValue];
            [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
            deltaLocation += [substring length] - [string length];
            success = YES;
        }
    }
    
    if (!success) { return; }
    
    [self replaceWithStrings:strings ranges:appliedRanges selectedRanges:newSelectedRanges actionName:actionName];
    
    [self scrollRangeToVisible:[self selectedRange]];
}

@end
