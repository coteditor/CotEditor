/*
 
 CETextView+Commenting.m
 
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
#import "CEDefaults.h"
#import "CESyntaxDictionaryKeys.h"


@implementation CETextView (Commenting)

#pragma mark Action Messages

// ------------------------------------------------------
/// toggle comment state in selection
- (IBAction)toggleComment:(nullable id)sender
// ------------------------------------------------------
{
    if ([self canUncommentRange:[self selectedRange]]) {
        [self uncomment:sender];
    } else {
        [self commentOut:sender];
    }
}


// ------------------------------------------------------
/// comment out selection appending comment delimiters
- (IBAction)commentOut:(nullable id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    // determine comment out target
    NSRange targetRange;
    if (![sender isKindOfClass:[NSScriptCommand class]] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey])
    {
        targetRange = [[self string] lineRangeForRange:[self selectedRange]];
    } else {
        targetRange = [self selectedRange];
    }
    // remove last return
    if (targetRange.length > 0 && [[self string] characterAtIndex:NSMaxRange(targetRange) - 1] == '\n') {
        targetRange.length--;
    }
    
    NSString *target = [[self string] substringWithRange:targetRange];
    NSString *beginDelimiter, *endDelimiter;
    NSString *spacer = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAppendsCommentSpacerKey] ? @" " : @"";
    NSString *newString;
    NSRange selected;
    NSUInteger addedChars = 0;
    
    // insert delimiters
    if ([self inlineCommentDelimiter]) {
        beginDelimiter = [self inlineCommentDelimiter];
        
        newString = [target stringByReplacingOccurrencesOfString:@"\n"
                                                      withString:[NSString stringWithFormat:@"\n%@%@", beginDelimiter, spacer]
                                                         options:0
                                                           range:NSMakeRange(0, [target length])];
        newString = [@[beginDelimiter, newString] componentsJoinedByString:spacer];
        addedChars = [newString length] - targetRange.length;
        
    } else if ([self blockCommentDelimiters]) {
        beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
        endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        
        newString = [@[beginDelimiter, target, endDelimiter] componentsJoinedByString:spacer];
        addedChars = [beginDelimiter length] + [spacer length];
    }
    
    // selection
    if ([self selectedRange].length > 0) {
        selected = NSMakeRange(targetRange.location, [newString length]);
    } else {
        selected = NSMakeRange([self selectedRange].location + addedChars, 0);
    }
    
    // replace
    [self replaceWithString:newString range:targetRange selectedRange:selected
                 actionName:NSLocalizedString(@"Comment Out", nil)];
}


// ------------------------------------------------------
/// uncomment selection removing comment delimiters
- (IBAction)uncomment:(nullable id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    BOOL hasUncommented = NO;
    
    // determine uncomment target
    NSRange targetRange;
    if (![sender isKindOfClass:[NSScriptCommand class]] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey])
    {
        targetRange = [[self string] lineRangeForRange:[self selectedRange]];
    } else {
        targetRange = [self selectedRange];
    }
    // remove last return
    if (targetRange.length > 0 && [[self string] characterAtIndex:NSMaxRange(targetRange) - 1] == '\n') {
        targetRange.length--;
    }
    
    NSString *target = [[self string] substringWithRange:targetRange];
    NSString *beginDelimiter, *endDelimiter;
    NSString *spacer = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAppendsCommentSpacerKey] ? @" " : @"";
    NSString *newString;
    NSUInteger removedChars = 0;
    
    // block comment
    if ([self blockCommentDelimiters]) {
        if ([target length] > 0) {
            beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
            endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
            
            // remove comment delimiters
            if ([target hasPrefix:beginDelimiter] && [target hasSuffix:endDelimiter]) {
                removedChars = [beginDelimiter length];
                newString = [target substringWithRange:NSMakeRange([beginDelimiter length],
                                                                   [target length] - [beginDelimiter length] - [endDelimiter length])];
                
                if ([spacer length] > 0 && [newString hasPrefix:spacer] && [newString hasSuffix:spacer]) {
                    newString = [newString substringWithRange:NSMakeRange(1, [newString length] - 2)];
                    removedChars++;
                }
                
                hasUncommented = YES;
            }
        }
    }
    
    // inline comment
    beginDelimiter = [self inlineCommentDelimiter];
    if (!hasUncommented && beginDelimiter) {
        
        // remove comment delimiters
        NSArray<NSString *> *lines = [target componentsSeparatedByString:@"\n"];
        NSMutableArray<NSString *> *newLines = [NSMutableArray array];
        for (NSString *line in lines) {
            NSString *newLine = [line copy];
            if ([line hasPrefix:beginDelimiter]) {
                newLine = [line substringFromIndex:[beginDelimiter length]];
                
                if ([spacer length] > 0 && [newLine hasPrefix:spacer]) {
                    newLine = [newLine substringFromIndex:[spacer length]];
                }
                
                hasUncommented = YES;
            }
            
            [newLines addObject:newLine];
            removedChars += [line length] - [newLine length];
        }
        
        newString = [newLines componentsJoinedByString:@"\n"];
    }
    
    if (!hasUncommented) { return; }
    
    // set selection
    NSRange selection;
    if ([self selectedRange].length > 0) {
        selection = NSMakeRange(targetRange.location, [newString length]);
    } else {
        selection = NSMakeRange([self selectedRange].location, 0);
        selection.location -= MIN(MIN(selection.location, selection.location - targetRange.location), removedChars);
    }
    
    [self replaceWithString:newString range:targetRange selectedRange:selection
                 actionName:NSLocalizedString(@"Uncomment", nil)];
}



#pragma mark Semi-Private Methods

// ------------------------------------------------------
/// whether given range can be uncommented
- (BOOL)canUncommentRange:(NSRange)range
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return NO; }
    
    // determine comment out target
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey]) {
        range = [[self string] lineRangeForRange:range];
    }
    // remove last return
    if (range.length > 0 && [[self string] characterAtIndex:NSMaxRange(range) - 1] == '\n') {
        range.length--;
    }
    
    NSString *target = [[self string] substringWithRange:range];
    
    if ([target length] == 0) { return NO; }
    
    if ([self blockCommentDelimiters]) {
        if ([target hasPrefix:[self blockCommentDelimiters][CEBeginDelimiterKey]] &&
            [target hasSuffix:[self blockCommentDelimiters][CEEndDelimiterKey]]) {
            return YES;
        }
    }
    
    if ([self inlineCommentDelimiter]) {
        NSArray<NSString *> *lines = [target componentsSeparatedByString:@"\n"];
        NSUInteger commentLineCount = 0;
        for (NSString *line in lines) {
            if ([line hasPrefix:[self inlineCommentDelimiter]]) {
                commentLineCount++;
            }
        }
        
        return commentLineCount == [lines count];
    }
    
    return NO;
}

@end
