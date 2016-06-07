/*
 
 CEEditorWrapper+Editor.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-07.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEEditorWrapper+Editor.h"
#import "CEDocument.h"

#import "NSTextView+CETextReplacement.h"
#import "NSString+CENewLine.h"
#import "NSString+CERange.h"


@implementation CEEditorWrapper (TextEditing)

#pragma mark Public Methods

// ------------------------------------------------------
/// textView の文字列を返す（改行コードはLF固定）
- (nonnull NSString *)string
// ------------------------------------------------------
{
    return [[self focusedTextView] string] ?: @"";
}


// ------------------------------------------------------
/// 指定された範囲の textView の文字列を返す
- (nonnull NSString *)substringWithRange:(NSRange)range
// ------------------------------------------------------
{
    return [[self string] substringWithRange:range];
}


// ------------------------------------------------------
/// メイン textView で選択された文字列を返す
- (nonnull NSString *)substringWithSelection
// ------------------------------------------------------
{
    return [[self string] substringWithRange:[[self focusedTextView] selectedRange]];
}


// ------------------------------------------------------
/// 選択文字列を置換する
- (void)insertTextViewString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertString:string];
}


// ------------------------------------------------------
/// 選択範囲の直後に文字列を挿入
- (void)insertTextViewStringAfterSelection:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertStringAfterSelection:string];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceTextViewAllStringWithString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] replaceAllStringWithString:string];
}


// ------------------------------------------------------
/// 文字列の最後に新たな文字列を追加
- (void)appendTextViewString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] appendString:string];
}


// ------------------------------------------------------
/// 選択範囲を返す
- (NSRange)selectedRange
// ------------------------------------------------------
{
    NSTextView *textView = [self focusedTextView];
    
    return [[textView string] convertRange:[textView selectedRange]
                           fromNewLineType:CENewLineLF
                             toNewLineType:[[self document] lineEnding]];
}


// ------------------------------------------------------
/// 選択範囲を変更
- (void)setSelectedRange:(NSRange)charRange
// ------------------------------------------------------
{
    NSTextView *textView = [self focusedTextView];
    NSRange range = [[textView string] convertRange:charRange
                                    fromNewLineType:[[self document] lineEnding]
                                      toNewLineType:CENewLineLF];
    
    [textView setSelectedRange:range];
}

@end




#pragma mark -

@implementation CEEditorWrapper (Locating)

#pragma mark Public Methods

// ------------------------------------------------------
/// convert minus location/length to NSRange
- (NSRange)rangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSString *documentString = [[self string] stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
    
    return [documentString rangeForLocation:location length:length];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を文字単位で選択
- (void)setSelectedCharacterRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSRange range = [self rangeWithLocation:location length:length];
    
    if (range.location == NSNotFound) { return; }
    
    [self setSelectedRange:range];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を行単位で選択
- (void)setSelectedLineRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    // you can ignore actuall line ending type and directly comunicate with textView, as this handle just lines
    NSTextView *textView = [self focusedTextView];
    
    NSRange range = [[textView string] rangeForLineLocation:location length:length];
    
    if (range.location == NSNotFound) { return; }
    
    [textView setSelectedRange:range];
}

@end
