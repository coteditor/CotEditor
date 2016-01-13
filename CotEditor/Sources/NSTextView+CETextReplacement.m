/*
 
 NSTextView+CETextReplacement.m
 
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

#import "NSTextView+CETextReplacement.h"


@implementation NSTextView (CETextReplacement)

#pragma mark Public Methods

// ------------------------------------------------------
/// treat programmatic text insertion
- (void)insertString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = [self selectedRange];
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        NSString *actionName = (replacementRange.length > 0) ? @"Replace Text" : @"Insert Text";
        [[self undoManager] setActionName:NSLocalizedString(actionName, nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// insert given string just after current selection and select inserted range
- (void)insertStringAfterSelection:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange(NSMaxRange([self selectedRange]), 0);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// swap whole current string with given string and select inserted range
- (void)replaceAllStringWithString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange(0, [[self string] length]);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Replace Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// append string at the end of the whole string and select inserted range
- (void)appendString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange([[self string] length], 0);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// 置換を実行
- (void)replaceWithString:(nullable NSString *)string range:(NSRange)range selectedRange:(NSRange)selectedRange actionName:(nullable NSString *)actionName
// ------------------------------------------------------
{
    if (!string) { return; }
    
    [self replaceWithStrings:@[string]
                      ranges:@[[NSValue valueWithRange:range]]
              selectedRanges:@[[NSValue valueWithRange:selectedRange]]
                  actionName:actionName];
}


// ------------------------------------------------------
/// perform multiple replacements
- (void)replaceWithStrings:(nonnull NSArray<NSString *> *)strings ranges:(nonnull NSArray<NSValue *> *)ranges selectedRanges:(nullable NSArray<NSValue *> *)selectedRanges actionName:(nullable NSString *)actionName
// ------------------------------------------------------
{
    NSAssert([strings count] == [ranges count], @"unbalanced number of strings and ranges for multiple replacement");
    
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    // tell textEditor about beginning of the text processing
    if (![self shouldChangeTextInRanges:ranges replacementStrings:strings]) { return; }
    
    // set action name
    if (actionName) {
        [[self undoManager] setActionName:actionName];
    }
    
    // process text
    NSTextStorage *textStorage = [self textStorage];
    NSDictionary<NSString *, id> *attributes = [self typingAttributes];
    
    [textStorage beginEditing];
    // use backwards enumeration to skip adjustment of applying location
    [strings enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:^(NSString * _Nonnull string, NSUInteger idx, BOOL * _Nonnull stop)
     {
         NSRange range = [ranges[idx] rangeValue];
         NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
         
         [textStorage replaceCharactersInRange:range withAttributedString:attrString];
     }];
    [textStorage endEditing];
    
    // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
    [self didChangeText];
    
    // apply new selection ranges
    selectedRanges = selectedRanges ?: [self selectedRanges];
    [self setSelectedRangesWithUndo:selectedRanges];
}


// ------------------------------------------------------
/// undoable selection change
- (void)setSelectedRangesWithUndo:(nonnull NSArray<NSValue *> *)ranges;
// ------------------------------------------------------
{
    [self setSelectedRanges:ranges];
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:ranges];
}

@end
