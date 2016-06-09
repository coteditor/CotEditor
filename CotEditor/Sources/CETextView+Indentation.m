/*
 
 CETextView+Indentation.m
 
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
#import "NSString+Indentation.h"


@implementation CETextView (Indentation)

#pragma mark Action Messages

// ------------------------------------------------------
/// increase indent level
- (IBAction)shiftRight:(nullable id)sender
// ------------------------------------------------------
{
    if ([self tabWidth] < 1) { return; }
    
    // get range to process
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    
    // remove the last line ending
    if (lineRange.length > 0) {
        lineRange.length--;
    }
    
    // create indent string to prepend
    NSString *indent = [self isAutoTabExpandEnabled] ? [NSString stringWithSpaces:[self tabWidth]] : @"\t";
    
    // create shifted string
    NSMutableString *newString = [NSMutableString stringWithString:[[self string] substringWithRange:lineRange]];
    NSUInteger numberOfLines = [newString replaceOccurrencesOfString:@"\n"
                                                          withString:[NSString stringWithFormat:@"\n%@", indent]
                                                             options:0
                                                               range:NSMakeRange(0, [newString length])];
    [newString insertString:indent atIndex:0];
    
    // calculate new selection range
    NSRange newSelectedRange = NSMakeRange(selectedRange.location,
                                           selectedRange.length + [indent length] * numberOfLines);
    if ((lineRange.location == selectedRange.location) && (selectedRange.length > 0) &&
        ([[[self string] substringWithRange:selectedRange] hasSuffix:@"\n"]))
    {
        // 行頭から行末まで選択されていたときは、処理後も同様に選択する
        newSelectedRange.length += [indent length];
    } else {
        newSelectedRange.location += [indent length];
    }
    
    // perform replace and register to undo manager
    [self replaceWithString:newString range:lineRange selectedRange:newSelectedRange
                 actionName:NSLocalizedString(@"Shift Right", nil)];
}


// ------------------------------------------------------
/// decrease indent level
- (IBAction)shiftLeft:(nullable id)sender
// ------------------------------------------------------
{
    if ([self tabWidth] < 1) { return; }
    
    // get range to process
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    
    if (lineRange.length == 0) { return; } // do nothing with blank line
    
    // remove the last line ending
    if ((lineRange.length > 1) && ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n')) {
        lineRange.length--;
    }
    
    // create shifted string
    NSMutableArray<NSString *> *newLines = [NSMutableArray array];
    NSInteger tabWidth = [self tabWidth];
    __block NSRange newSelectedRange = selectedRange;
    __block BOOL didShift = NO;
    __block NSUInteger scanningLineLocation = lineRange.location;
    __block BOOL isFirstLine = YES;
    
    // scan selected lines and remove tab/spaces at the beginning of lines
    [[[self string] substringWithRange:lineRange] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSUInteger numberOfDeleted = 0;
        
        // count tab/spaces to delete
        BOOL isDeletingSpace = NO;
        for (NSUInteger i = 0; i < MIN(tabWidth, [line length]); i++) {
            unichar theChar = [line characterAtIndex:i];
            if (theChar == '\t' && !isDeletingSpace) {
                numberOfDeleted = 1;
                break;
            } else if (theChar == ' ') {
                numberOfDeleted++;
                isDeletingSpace = YES;
            } else {
                break;
            }
        }
        
        NSString *newLine = [line substringFromIndex:numberOfDeleted];
        
        // calculate new selection range
        NSRange deletedRange = NSMakeRange(scanningLineLocation, numberOfDeleted);
        newSelectedRange.length -= NSIntersectionRange(deletedRange, newSelectedRange).length;
        if (isFirstLine) {
            newSelectedRange.location = MAX((NSInteger)(selectedRange.location - numberOfDeleted),
                                            (NSInteger)lineRange.location);
            isFirstLine = NO;
        }
        
        // append new line
        [newLines addObject:newLine];
        
        didShift = didShift ? : (numberOfDeleted > 0);
        scanningLineLocation += [newLine length] + 1;  // +1 for line ending
    }];
    
    // cancel if not shifted
    if (!didShift) { return; }
    
    NSString *newString = [newLines componentsJoinedByString:@"\n"];
    
    // perform replace and register to undo manager
    [self replaceWithString:newString range:lineRange selectedRange:newSelectedRange
                 actionName:NSLocalizedString(@"Shift Left", nil)];
}


// ------------------------------------------------------
/// standardize inentation in selection to spaces
- (IBAction)convertIndentationToSpaces:(nullable id)sender
// ------------------------------------------------------
{
    NSArray<NSValue *> *ranges;
    if ([self selectedRange].length == 0) {
        ranges = @[[NSValue valueWithRange:NSMakeRange(0, [[self string] length])]];
    } else {
        ranges = [self selectedRanges];
    }
    
    [self convertIndentation:CEIndentStyleSpace inRanges:ranges];
}


// ------------------------------------------------------
/// standardize inentation in selection to tabs
- (IBAction)convertIndentationToTabs:(nullable id)sender
// ------------------------------------------------------
{
    NSArray<NSValue *> *ranges;
    if ([self selectedRange].length == 0) {
        ranges = @[[NSValue valueWithRange:NSMakeRange(0, [[self string] length])]];
    } else {
        ranges = [self selectedRanges];
    }
    
    [self convertIndentation:CEIndentStyleTab inRanges:ranges];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// standardize inentation of given ranges
- (void)convertIndentation:(CEIndentStyle)indentStyle inRanges:(nonnull NSArray<NSValue *> *)ranges
// ------------------------------------------------------
{
    if ([[self string] length] == 0) { return; }
    
    NSMutableArray<NSValue *> *replacementRanges = [NSMutableArray arrayWithCapacity:[ranges count]];
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray arrayWithCapacity:[ranges count]];
    
    for (NSValue *rangeValue in ranges) {
        NSRange range = [rangeValue rangeValue];
        NSString *selectedString = [[self string] substringWithRange:range];
        NSString *convertedString = [selectedString stringByStandardizingIndentStyleTo:indentStyle
                                                                              tabWidth:[self tabWidth]];
        
        if ([convertedString isEqualToString:selectedString]) { continue; }  // no need to convert
        
        [replacementRanges addObject:rangeValue];
        [replacementStrings addObject:convertedString];
    }
    
    [self replaceWithStrings:replacementStrings ranges:replacementRanges selectedRanges:nil
                  actionName:NSLocalizedString(@"Convert Indentation", @"action name")];
}

@end
