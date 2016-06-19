/*
 
 CETextView+LineProcessing.m
 
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


@implementation CETextView (LineProcessing)

#pragma mark Action Messages

// ------------------------------------------------------
/// move selected line up
- (IBAction)moveLineUp:(nullable id)sender
// ------------------------------------------------------
{
    // get line ranges to process
    NSArray<NSValue *> *lineRanges = [self selectedLineRanges];
    
    // cannot perform Move Line Up if one of the selections is already in the first line
    if ([[lineRanges firstObject] rangeValue].location == 0) {
        NSBeep();
        return;
    }
    
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSTextStorage *textStorage = [self textStorage];
    NSString *string = [self string];
    
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray arrayWithCapacity:[lineRanges count]];
    
    // swap lines
    [textStorage beginEditing];
    for (NSValue *lineRangeValue in lineRanges) {
        NSRange lineRange = [lineRangeValue rangeValue];
        NSRange upperLineRange = [string lineRangeForRange:NSMakeRange(lineRange.location - 1, 0)];
        NSString *lineString = [string substringWithRange:lineRange];
        NSString *upperLineString = [string substringWithRange:upperLineRange];
        
        // last line
        if (![lineString hasSuffix:@"\n"]) {
            lineString = [lineString stringByAppendingString:@"\n"];
            upperLineString = [upperLineString substringToIndex:upperLineRange.length - 1];
        }
        
        NSString *replacementString = [NSString stringWithFormat:@"%@%@", lineString, upperLineString];
        NSRange editRange = NSMakeRange(upperLineRange.location, [replacementString length]);
        
        // swap
        if ([self shouldChangeTextInRange:editRange replacementString:replacementString]) {
            [[textStorage mutableString] replaceCharactersInRange:editRange withString:replacementString];
            [self didChangeText];
            
            // move selected ranges in the line to move
            for (NSValue *selectedRangeValue in selectedRanges) {
                NSRange selectedRange = [selectedRangeValue rangeValue];
                NSRange intersectionRange = NSIntersectionRange(selectedRange, editRange);
                
                if (intersectionRange.length > 0) {
                    intersectionRange.location -= upperLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:intersectionRange]];
                } else if (NSLocationInRange(selectedRange.location, editRange)) {
                    selectedRange.location -= upperLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
                }
            }
        }
    }
    [textStorage endEditing];
    
    [self setSelectedRangesWithUndo:newSelectedRanges];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Move Line", @"action name")];
}


// ------------------------------------------------------
/// move selected line down
- (IBAction)moveLineDown:(nullable id)sender
// ------------------------------------------------------
{
    // get line ranges to process
    NSArray<NSValue *> *lineRanges = [self selectedLineRanges];
    
    // cannot perform Move Line Down if one of the selections is already in the last line
    if (NSMaxRange([[lineRanges lastObject] rangeValue]) == [[self string] length]) {
        NSBeep();
        return;
    }
    
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSTextStorage *textStorage = [self textStorage];
    NSString *string = [self string];
    
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray arrayWithCapacity:[lineRanges count]];
    
    // swap lines
    [textStorage beginEditing];
    for (NSValue *lineRangeValue in [lineRanges reverseObjectEnumerator]) {  // reverse order
        NSRange lineRange = [lineRangeValue rangeValue];
        NSRange lowerLineRange = [string lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
        NSString *lineString = [string substringWithRange:lineRange];
        NSString *lowerLineString = [string substringWithRange:lowerLineRange];
        
        // last line
        if (![lowerLineString hasSuffix:@"\n"]) {
            lineString = [lineString substringToIndex:lineRange.length - 1];
            lowerLineString = [lowerLineString stringByAppendingString:@"\n"];
            lowerLineRange.length += 1;
        }
        
        NSString *replacementString = [NSString stringWithFormat:@"%@%@", lowerLineString, lineString];
        NSRange editRange = NSMakeRange(lineRange.location, [replacementString length]);
        
        // swap
        if ([self shouldChangeTextInRange:editRange replacementString:replacementString]) {
            [[textStorage mutableString] replaceCharactersInRange:editRange withString:replacementString];
            [self didChangeText];
            
            // move selected ranges in the line to move
            for (NSValue *selectedRangeValue in selectedRanges) {
                NSRange selectedRange = [selectedRangeValue rangeValue];
                NSRange intersectionRange = NSIntersectionRange(selectedRange, editRange);
                
                if (intersectionRange.length > 0) {
                    intersectionRange.location += lowerLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:intersectionRange]];
                } else if (NSLocationInRange(selectedRange.location, editRange)) {
                    selectedRange.location += lowerLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
                }
            }
        }
    }
    [textStorage endEditing];
    
    [self setSelectedRangesWithUndo:newSelectedRanges];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Move Line", @"action name")];
}


// ------------------------------------------------------
/// sort selected lines (only in the first selection) ascending
- (IBAction)sortLinesAscending:(nullable id)sender
// ------------------------------------------------------
{
    // process whole document if no text selected
    if ([self selectedRange].length == 0) {
        [self setSelectedRange:NSMakeRange(0, [self string].length)];
    }
    
    NSRange lineRange = [[self string] lineRangeForRange:[self selectedRange]];
    
    if (lineRange.length == 0) { return; }
    
    BOOL endsWithNewline = ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n');
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    
    [[self string] enumerateSubstringsInRange:lineRange
                                      options:NSStringEnumerationByLines
                                   usingBlock:^(NSString * _Nullable substring,
                                                NSRange substringRange,
                                                NSRange enclosingRange,
                                                BOOL * _Nonnull stop)
     {
         [lines addObject:substring];
     }];
    
    // do nothing with single line
    if ([lines count] < 2) { return; }
    
    // sort alphabetically ignoring case
    [lines sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // make new string
    NSString *newString = [lines componentsJoinedByString:@"\n"];
    if (endsWithNewline) {
        newString = [newString stringByAppendingString:@"\n"];
    }
    
    [self replaceWithString:newString range:lineRange selectedRange:NSMakeRange(lineRange.location, [newString length])
                 actionName:NSLocalizedString(@"Sort Lines", @"action name")];
}


// ------------------------------------------------------
/// reverse selected lines (only in the first selection)
- (IBAction)reverseLines:(nullable id)sender
// ------------------------------------------------------
{
    // process whole document if no text selected
    if ([self selectedRange].length == 0) {
        [self setSelectedRange:NSMakeRange(0, [self string].length)];
    }
    
    NSRange lineRange = [[self string] lineRangeForRange:[self selectedRange]];
    
    if (lineRange.length == 0) { return; }
    
    BOOL endsWithNewline = ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n');
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    
    [[self string] enumerateSubstringsInRange:lineRange
                                      options:NSStringEnumerationByLines | NSStringEnumerationReverse
                                   usingBlock:^(NSString * _Nullable substring,
                                                NSRange substringRange,
                                                NSRange enclosingRange,
                                                BOOL * _Nonnull stop)
     {
         [lines addObject:substring];
     }];
    
    // do nothing with single line
    if ([lines count] < 2) { return; }
    
    // make new string
    NSString *newString = [lines componentsJoinedByString:@"\n"];
    if (endsWithNewline) {
        newString = [newString stringByAppendingString:@"\n"];
    }
    
    [self replaceWithString:newString range:lineRange selectedRange:NSMakeRange(lineRange.location, [newString length])
                 actionName:NSLocalizedString(@"Reverse Lines", @"action name")];
}


// ------------------------------------------------------
/// delete duplicate lines in selection
- (IBAction)deleteDuplicateLine:(nullable id)sender
// ------------------------------------------------------
{
    // process whole document if no text selected
    if ([self selectedRange].length == 0) {
        [self setSelectedRange:NSMakeRange(0, [self string].length)];
    }
    
    if ([self selectedRange].length == 0) { return; }
    
    NSMutableArray<NSValue *> *replacementRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray array];
    NSMutableOrderedSet<NSString *> *uniqueLines = [NSMutableOrderedSet orderedSet];
    NSUInteger processedCount = 0;
    
    // collect duplicate lines
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange range = [rangeValue rangeValue];
        NSRange lineRange = [[self string] lineRangeForRange:range];
        NSString *targetString = [[self string] substringWithRange:lineRange];
        NSArray<NSString *> *lines = [targetString componentsSeparatedByString:@"\n"];
        
        // filter duplicate lines
        [uniqueLines addObjectsFromArray:lines];
        
        NSRange targetLinesRange = NSMakeRange(processedCount, [uniqueLines count] - processedCount);
        processedCount += targetLinesRange.length;
        
        // do nothing if no duplicate line exists
        if (targetLinesRange.length == [lines count]) { continue; }
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:targetLinesRange];
        NSString *replacementString = [[uniqueLines objectsAtIndexes:indexSet] componentsJoinedByString:@"\n"];
        
        // append last new line only if the original selected lineRange has a new line at the end
        if ([targetString hasSuffix:@"\n"]) {
            replacementString = [replacementString stringByAppendingString:@"\n"];
        }
        
        [replacementStrings addObject:replacementString];
        [replacementRanges addObject:[NSValue valueWithRange:lineRange]];
    }
    
    [self replaceWithStrings:replacementStrings ranges:replacementRanges selectedRanges:nil
                  actionName:NSLocalizedString(@"Delete Duplicate Lines", @"action name")];
}


// ------------------------------------------------------
/// duplicate selected lines below
- (IBAction)duplicateLine:(nullable id)sender
// ------------------------------------------------------
{
    NSMutableArray<NSValue *> *replacementRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray array];
    
    // get lines to process
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange range = [rangeValue rangeValue];
        NSRange lineRange = [[self string] lineRangeForRange:range];
        NSRange replacementRange = NSMakeRange(lineRange.location, 0);
        NSString *lineString = [[self string] substringWithRange:lineRange];
        
        // add line break if it's the last line
        if (![lineString hasSuffix:@"\n"]) {
            lineString = [lineString stringByAppendingString:@"\n"];
        }
        
        [replacementRanges addObject:[NSValue valueWithRange:replacementRange]];
        [replacementStrings addObject:lineString];
    }
    
    [self replaceWithStrings:replacementStrings ranges:replacementRanges selectedRanges:nil
                  actionName:NSLocalizedString(@"Duplicate Line", @"action name")];
}


// ------------------------------------------------------
/// remove selected lines
- (IBAction)deleteLine:(nullable id)sender
// ------------------------------------------------------
{
    NSArray<NSValue *> *replacementRanges = [self selectedLineRanges];
    
    // on empty last line
    if ([replacementRanges count] == 0) { return; }
    
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray arrayWithCapacity:[replacementRanges count]];
    
    for (NSUInteger _ = 0; _ < [replacementRanges count]; _++) {
        [replacementStrings addObject:@""];
    }
    
    [self replaceWithStrings:replacementStrings ranges:replacementRanges selectedRanges:nil
                  actionName:NSLocalizedString(@"Delete Line", @"action name")];
}


// ------------------------------------------------------
/// trim all trailing whitespace
- (IBAction)trimTrailingWhitespace:(nullable id)sender
// ------------------------------------------------------
{
    [self trimTrailingWhitespaceKeepingEditingPoint:NO];
}



#pragma mark - Private Methods

// ------------------------------------------------------
/// extract line by line line ranges which selected ranges include
- (nonnull NSArray<NSValue *> *)selectedLineRanges
// ------------------------------------------------------
{
    NSMutableOrderedSet<NSValue *> *lineRanges = [NSMutableOrderedSet orderedSet];
    NSString *string = [self string];
    
    // get line ranges to process
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange selectedRange = [rangeValue rangeValue];
        
        NSRange linesRange = [string lineRangeForRange:selectedRange];
        
        // store each line to process
        [string enumerateSubstringsInRange:linesRange
                                   options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                usingBlock:^(NSString * _Nullable substring,
                                             NSRange substringRange,
                                             NSRange enclosingRange,
                                             BOOL * _Nonnull stop)
         {
             [lineRanges addObject:[NSValue valueWithRange:enclosingRange]];
         }];
    }
    
    return [lineRanges array];
}

@end
