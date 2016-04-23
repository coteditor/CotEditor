/*
 
 CEATSTypesetter.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-12-08.

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

#import "CEATSTypesetter.h"
#import "CELayoutManager.h"
#import "CETextViewProtocol.h"


@implementation CEATSTypesetter

#pragma mark ATSTypesetter Methods

// ------------------------------------------------------
/// フォントの leading 値を反映させるかどうかを返す
- (BOOL)usesFontLeading
// ------------------------------------------------------
{
    return ![(CELayoutManager *)[self layoutManager] fixesLineHeight];
}


// ------------------------------------------------------
/// 行間ピクセル数を返す
- (CGFloat)lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(NSRect)rect
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[self layoutManager];
    CGFloat lineSpacing = [(NSTextView<CETextViewProtocol> *)[[self currentTextContainer] textView] lineSpacing];

    if (![manager fixesLineHeight]) {
        CGFloat spacing = [super lineSpacingAfterGlyphAtIndex:glyphIndex withProposedLineFragmentRect:rect];
        CGFloat fontSize = [[[[self currentTextContainer] textView] font] pointSize];

        return (spacing + lineSpacing * fontSize);
    }
    
    // 複合フォントで行の高さがばらつくのを防止する
    // （CELayoutManager の関連メソッドをオーバーライドしてあれば、このメソッドをオーバーライドしなくても
    // 通常の入力では行間が一定になるが、フォントや行間を変更したときに適正に描画されない）
    // （CETextView で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
    // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
    // 挿入すると行間がズレる」問題が生じる）
    CGFloat defaultLineHeight = [manager defaultLineHeightForTextFont];
    CGFloat fontSize = [[manager textFont] pointSize];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return round(defaultLineHeight - rect.size.height + lineSpacing * fontSize);
}


// ------------------------------------------------------
/// customize behavior by control glyph
- (NSTypesetterControlCharacterAction)actionForControlCharacterAtIndex:(NSUInteger)charIndex
// ------------------------------------------------------
{
    NSTypesetterControlCharacterAction result = [super actionForControlCharacterAtIndex:charIndex];
    
    if (result & NSTypesetterZeroAdvancementAction) {
        NSString *string = [[self attributedString] string];
        BOOL isLowSurrogate = (CFStringIsSurrogateLowCharacter([string characterAtIndex:charIndex]) &&
                               ((charIndex > 0) && CFStringIsSurrogateHighCharacter([string characterAtIndex:charIndex - 1])));
        if (!isLowSurrogate) {
            return NSTypesetterWhitespaceAction;  // -> Then, the glyph width can be modified on `boundingBoxForControlGlyphAtIndex:...`.
        }
    }
    
    return result;
}


// ------------------------------------------------------
/// return bounding box for control glyph
- (NSRect)boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(nonnull NSTextContainer *)textContainer proposedLineFragment:(NSRect)proposedRect glyphPosition:(NSPoint)glyphPosition characterIndex:(NSUInteger)charIndex
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[self layoutManager];
    if (![manager showsOtherInvisibles] || ![manager showsInvisibles]) {
        // DON'T invoke super method here. If invoked, it can not continue drawing remaining lines any more on Mountain Lion (and possible other versions except El Capitan).
        // Just passing zero rect is enough if you dont need to draw.
        return NSZeroRect;
    }
    
    // make blank space to draw a replacement character in CELayoutManager later.
    NSFont *textFont = [manager textFont];
    NSFont *invisibleFont = [NSFont fontWithName:@"Lucida Grande" size:[textFont pointSize]] ?: textFont;  // use current text font for fallback
    NSGlyph replacementGlyph = [invisibleFont glyphWithName:@"replacement"];  // U+FFFD
    NSRect replacementGlyphBounding = [invisibleFont boundingRectForGlyph:replacementGlyph];
    proposedRect.size.width = replacementGlyphBounding.size.width;
    
    return proposedRect;
}


// ------------------------------------------------------
/// avoid soft warpping just after an indent
- (BOOL)shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
// ------------------------------------------------------
{
    if (charIndex == 0) { return YES; }
    
    // check if the character is the first non-whitespace character after indent
    NSString *string = [[self attributedString] string];
    while (charIndex > 0) {
        unichar character = [string characterAtIndex:charIndex];
        
        if (character != ' ' && character != '\t') { return YES; }  // hit to non-indent character
        if (character == '\n') { return NO; }  // the line ended
        
        charIndex--;
    }
    
    return NO;
}

@end
