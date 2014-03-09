/*
=================================================
CELayoutManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.01.10

------------
This class is based on Smultron - SMLLayoutManager (written by Peter Borg – http://smultron.sourceforge.net)
Smultron  Copyright (c) 2004 Peter Borg, All rights reserved.
Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
arranged by nakamuxu, Jan 2005.
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CELayoutManager.h"
#import "CEAppController.h"

//=======================================================
// Private method
//
//=======================================================

@interface CELayoutManager (Private)
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)inGlyphIndex adjust:(NSSize)inSize;
@end


//------------------------------------------------------------------------------------------




@implementation CELayoutManager

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)init
// 初期化
// ------------------------------------------------------
{
    if (self = [super init]) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

/*
// 削除しないこと！ ************* (1/12)
        NSString *theName = [theValues valueForKey:k_key_fontName];
        CGFloat theSize = (CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue];
        NSFont *theFont = [NSFont fontWithName:theName size:theSize];
        NSColor *theColor = 
                [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_invisibleCharactersColor]];
        _attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                theFont, NSFontAttributeName, 
                theColor, NSForegroundColorAttributeName, nil]; // ===== alloc

*/
//        _defaultLineHeightForTextFont = 0.0;
//        _textFontPointSize = 0.0;
        [self setTextFont:nil];

        _appController = (CEAppController *)[[NSApp delegate] retain]; // ===== retain

        _spaceCharacter = [[_appController invisibleSpaceCharacter:
                [[theValues valueForKey:k_key_invisibleSpace] unsignedIntegerValue]] retain]; // ===== retain
        _tabCharacter = [[_appController invisibleTabCharacter:
                [[theValues valueForKey:k_key_invisibleTab] unsignedIntegerValue]] retain]; // ===== retain
        _newLineCharacter = [[_appController invisibleNewLineCharacter:
                [[theValues valueForKey:k_key_invisibleNewLine] unsignedIntegerValue]] retain]; // ===== retain
        _fullwidthSpaceCharacter = [[_appController invisibleFullwidthSpaceCharacter:
                [[theValues valueForKey:k_key_invisibleFullwidthSpace] unsignedIntegerValue]] retain]; // ===== retain

        // （setShowInvisibles: は CEEditorView から実行される。プリント時は CEDocument から実行される）
        [self setFixLineHeight:NO];
        [self setIsPrinting:NO];
        [self setShowSpace:[[theValues valueForKey:k_key_showInvisibleSpace] boolValue]];
        [self setShowTab:[[theValues valueForKey:k_key_showInvisibleTab] boolValue]];
        [self setShowNewLine:[[theValues valueForKey:k_key_showInvisibleNewLine] boolValue]];
        [self setShowFullwidthSpace:[[theValues valueForKey:k_key_showInvisibleFullwidthSpace] boolValue]];
        [self setShowOtherInvisibles:[[theValues valueForKey:k_key_showOtherInvisibleChars] boolValue]];
        [self setTypesetter:[CEATSTypesetter sharedSystemTypesetter]];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    // _attributes was not retained.
    [_spaceCharacter release];
    [_tabCharacter release];
    [_newLineCharacter release];
    [_fullwidthSpaceCharacter release];
    [_textFont release];
    [_appController release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setLineFragmentRect:(NSRect)inFragmentRect 
        forGlyphRange:(NSRange)inGlyphRange usedRect:(NSRect)inUsedRect
// 行描画矩形をセット
// ------------------------------------------------------
{
    if ((![self isPrinting]) && ([self fixLineHeight])) {
        // 複合フォントで行の高さがばらつくのを防止する
        // （CETextViewCore で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じる）
        // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグで印刷中を確認）
        inFragmentRect.size.height = [self lineHeight];
        inUsedRect.size.height = [self lineHeight];
    }

    (void)[super setLineFragmentRect:(NSRect)inFragmentRect 
            forGlyphRange:(NSRange)inGlyphRange usedRect:(NSRect)inUsedRect];
}


// ------------------------------------------------------
- (void)setExtraLineFragmentRect:(NSRect)inFragmentRect 
        usedRect:(NSRect)inUsedRect textContainer:(NSTextContainer *)inTextContainer
// 最終行描画矩形をセット
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    inFragmentRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:inFragmentRect usedRect:inUsedRect textContainer:inTextContainer];
}


// ------------------------------------------------------
- (NSPoint)locationForGlyphAtIndex:(NSUInteger)glyphIndex
// グリフ位置を返す
// ------------------------------------------------------
{
    if ((![self isPrinting]) && ([self fixLineHeight])) {
        // 複合フォントで描画位置Y座標が変わるのを防止する
        // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグで印刷中を確認）

        // フォントサイズは随時変更されるため、表示時に取得する
        NSPoint outPoint = [super locationForGlyphAtIndex:glyphIndex];
        outPoint.y = [self textFontGlyphY];

        return outPoint;
    }

    return [super locationForGlyphAtIndex:glyphIndex];
}


// ------------------------------------------------------
- (void)drawGlyphsForGlyphRange:(NSRange)inGlyphRange atPoint:(NSPoint)inContainerOrigin
// 不可視文字の表示
// ------------------------------------------------------
{
    // （印刷中の判定は、このメソッド内では [NSGraphicsContext currentContextDrawingToScreen] が使えるが、
    // 他のメソッドでは真を返す時があるため、他にそろえて専用フラグで印刷中を確認するようにしている）

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theCompleteStr = [[self textStorage] string];
    NSUInteger theLengthToRedraw = NSMaxRange(inGlyphRange);
    NSUInteger theGlyphIndex, theCharIndex = 0;
    int theInvisibleCharPrintMenuIndex;

    id theView = [self firstTextView];
    if (([self isPrinting]) && ([theView respondsToSelector:@selector(printValues)])) {
        theInvisibleCharPrintMenuIndex = 
                [[[theView printValues] valueForKey:k_printInvisibleCharIndex] integerValue];
    } else {
        theInvisibleCharPrintMenuIndex = [[theValues valueForKey:k_printInvisibleCharIndex] integerValue];
    }

    // フォントサイズは随時変更されるため、表示時に取得する
    NSFont *theFont = ([self isPrinting]) ? [[self textStorage] font] : [self textFont];
    NSColor *theColor = 
            [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_invisibleCharactersColor]];
    _attributes = @{NSFontAttributeName: theFont, 
            NSForegroundColorAttributeName: theColor};

    unichar theCharacter;
    NSPoint thePointToDraw;

    // スクリーン描画の時、アンチエイリアス制御
    if (![self isPrinting]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self useAntialias]];
    }

    if ((((![self isPrinting]) || (theInvisibleCharPrintMenuIndex == 1)) && 
                    ([self showInvisibles])) || 
            (([self isPrinting]) && (theInvisibleCharPrintMenuIndex == 2))) {

        CGFloat theInsetWidth = (CGFloat)[[theValues valueForKey:k_key_textContainerInsetWidth] doubleValue];
        CGFloat theInsetHeight = (CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightTop] doubleValue];
        if ([self isPrinting]) {
            NSPoint thePoint = [[self firstTextView] textContainerOrigin];
            theInsetWidth = thePoint.x;
            theInsetHeight = thePoint.y;
        }
        NSSize theSize = NSMakeSize(theInsetWidth, theInsetHeight);
        NSFont *theReplaceFont = [NSFont fontWithName:@"Lucida Grande" size:[[self textFont] pointSize]];
        NSGlyph theGlyph = [theReplaceFont glyphWithName:@"replacement"];

        for (theGlyphIndex = inGlyphRange.location; theGlyphIndex < theLengthToRedraw; theGlyphIndex++) {
            theCharIndex = [self characterIndexForGlyphAtIndex:theGlyphIndex];
            theCharacter = [theCompleteStr characterAtIndex:theCharIndex];

            if (([self showSpace]) && ((theCharacter == ' ') || (theCharacter == 0x00A0))) {
                thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
                [_spaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];

            } else if (([self showTab]) && (theCharacter == '\t')) {
                thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
                [_tabCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];

            } else if (([self showNewLine]) && (theCharacter == '\n' )) {
                thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
                [_newLineCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];

            } else if (([self showFullwidthSpace]) && (theCharacter == 0x3000)) { // Fullwidth-space (JP)
                thePointToDraw = [self pointToDrawGlyphAtIndex:theGlyphIndex adjust:theSize];
                [_fullwidthSpaceCharacter drawAtPoint:thePointToDraw withAttributes:_attributes];

            } else if (([self showOtherInvisibles]) && ([self glyphAtIndex:theGlyphIndex] == NSControlGlyph)) {
                NSRange theCharRange = NSMakeRange(theCharIndex, 1);
                NSString *theBaseStr = [theCompleteStr substringWithRange:theCharRange];
                NSGlyphInfo *theGlyphInfo = [NSGlyphInfo glyphInfoWithGlyph:theGlyph
                                    forFont:theReplaceFont baseString:theBaseStr];
                if (theGlyphInfo != nil) {
                    NSDictionary *theReplaceAttrs = @{NSGlyphInfoAttributeName: theGlyphInfo, 
                            NSFontAttributeName: theReplaceFont, 
                            NSForegroundColorAttributeName: theColor};
                    NSDictionary *theAttrs = 
                            [[self textStorage] attributesAtIndex:theCharIndex effectiveRange:NULL];
                    if (theAttrs[NSGlyphInfoAttributeName] == nil) {
                        [[self textStorage] addAttributes:theReplaceAttrs range:theCharRange];
                    }
                }
            }
        }
    }
    [super drawGlyphsForGlyphRange:inGlyphRange atPoint:inContainerOrigin];
}


// ------------------------------------------------------
- (BOOL)showInvisibles
// 不可視文字を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showInvisibles;
}


// ------------------------------------------------------
- (void)setShowInvisibles:(BOOL)inValue
// 不可視文字を表示するかどうかを設定する
// ------------------------------------------------------
{
    if (!inValue) {
        NSRange theRange = NSMakeRange(0, [[[self textStorage] string] length]);
        [[self textStorage] removeAttribute:NSGlyphInfoAttributeName range:theRange];
    }
    if ([self showOtherInvisibles]) {
        [self setShowsControlCharacters:inValue];
    }
    _showInvisibles = inValue;
}


// ------------------------------------------------------
- (BOOL)showSpace
// 半角スペースを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showSpace;
}


// ------------------------------------------------------
- (void)setShowSpace:(BOOL)inValue
// 半角スペースを表示するかどうかを設定する
// ------------------------------------------------------
{
    _showSpace = inValue;
}


// ------------------------------------------------------
- (BOOL)showTab
// タブを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showTab;
}


// ------------------------------------------------------
- (void)setShowTab:(BOOL)inValue
// タブを表示するかどうかを設定する
// ------------------------------------------------------
{
    _showTab = inValue;
}


// ------------------------------------------------------
- (BOOL)showNewLine
// 改行を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showNewLine;
}


// ------------------------------------------------------
- (void)setShowNewLine:(BOOL)inValue
// 改行を表示するかどうかを設定する
// ------------------------------------------------------
{
    _showNewLine = inValue;
}


// ------------------------------------------------------
- (BOOL)showFullwidthSpace
// 全角スペースを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showFullwidthSpace;
}


// ------------------------------------------------------
- (void)setShowFullwidthSpace:(BOOL)inValue
// 全角スペースを表示するかどうかを設定する
// ------------------------------------------------------
{
    _showFullwidthSpace = inValue;
}


// ------------------------------------------------------
- (BOOL)showOtherInvisibles
// その他の不可視文字を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showOtherInvisibles;
}


// ------------------------------------------------------
- (void)setShowOtherInvisibles:(BOOL)inValue
// その他の不可視文字を表示するかどうかを設定する
// ------------------------------------------------------
{
    [self setShowsControlCharacters:inValue];
    _showOtherInvisibles = inValue;
}


// ------------------------------------------------------
- (BOOL)fixLineHeight
// 行高を固定するかを返す
// ------------------------------------------------------
{
    return _fixLineHeight;
}


// ------------------------------------------------------
- (void)setFixLineHeight:(BOOL)inValue
// 行高を固定するかをセット
// ------------------------------------------------------
{
    _fixLineHeight = inValue;
}


// ------------------------------------------------------
- (BOOL)useAntialias
// アンチエイリアスを適用するかどうかを返す
// ------------------------------------------------------
{
    return _useAntialias;
}


// ------------------------------------------------------
- (void)setUseAntialias:(BOOL)inValue
// アンチエイリアスを適用するかどうかをセット
// ------------------------------------------------------
{
    _useAntialias = inValue;
}


// ------------------------------------------------------
- (BOOL)isPrinting
// プリンタ中かどうかを返す
// ------------------------------------------------------
{
    // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）
    return _isPrinting;
}


// ------------------------------------------------------
- (void)setIsPrinting:(BOOL)inValue
// プリンタ中かどうかを設定
// ------------------------------------------------------
{
    // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）
    _isPrinting = inValue;
}


// ------------------------------------------------------
- (NSFont *)textFont
// 表示フォントを返す
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、自前でフォントを持っておく。
// （[[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、使わない）

    return _textFont;
}


// ------------------------------------------------------
- (void)setTextFont:(NSFont *)inFont
// 表示フォントをセット
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、自前でフォントを持っておく。
// （[[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、使わない）

    [inFont retain];
    [_textFont release];
    _textFont = inFont;
    [self setValuesForTextFont:inFont];
}


// ------------------------------------------------------
- (void)setValuesForTextFont:(NSFont *)inFont
// 表示フォントの各種値をキャッシュする
// ------------------------------------------------------
{
    if (inFont != nil) {
        _defaultLineHeightForTextFont = [self defaultLineHeightForFont:inFont] * k_defaultLineHeightMultiple;
        _textFontPointSize = [inFont pointSize];
        _textFontGlyphY = [inFont pointSize];
        // （_textFontGlyphYは「複合フォントでも描画位置Y座標を固定」する時のみlocationForGlyphAtIndex:内で使われる。
        // 本来の値は[inFont ascender]か？ 2009.03.28）

        // [inFont pointSize]は通常、([inFont ascender] - [inFont descender])と一致する。例えばCourier 48ptだと、
        // ascender　=　36.187500, descender = -11.812500 となっている。 2009.03.28

    } else {
        _defaultLineHeightForTextFont = 0.0;
        _textFontPointSize = 0.0;
        _textFontGlyphY = 0.0;
    }
}


// ------------------------------------------------------
- (CGFloat)defaultLineHeightForTextFont
// 表示フォントでの行高を返す
// ------------------------------------------------------
{
    return _defaultLineHeightForTextFont;
}


// ------------------------------------------------------
- (CGFloat)textFontPointSize
// 表示フォントサイズを返す
// ------------------------------------------------------
{
    return _textFontPointSize;
}


// ------------------------------------------------------
- (CGFloat)textFontGlyphY
// 表示フォントグリフのY位置を返す
// ------------------------------------------------------
{
    return _textFontGlyphY;
}


// ------------------------------------------------------
- (CGFloat)lineHeight
// 複合フォントで行の高さがばらつくのを防止するため、規定した行の高さを返す
// ------------------------------------------------------
{
    CGFloat theLineSpacing = [(CETextViewCore *)[self firstTextView] lineSpacing];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return floor(_defaultLineHeightForTextFont + theLineSpacing * [self textFontPointSize] + 0.5);
}


/*
// ------------------------------------------------------
- (void)_clearTemporaryAttributesForCharacterRange:(struct _NSRange)fp8 changeInLength:(NSInteger)fp16
// 隠しメソッドをオーバーライド。
// ------------------------------------------------------
{
// 10.5.1で、大量のtemporaryAttrsが付いたテキストを削除しようとするとしばらく固まることへの対策
    // 10.5未満で実行されているときまたは小規模の変更のみ、スーパークラスで実行
    // （小規模の変更を通さないと、IMで入力中の変換前文字が直前までその場所にセットされていたattrにカラーリングされてしまう）
    if ((abs(fp16) < 65000) || (floor(NSAppKitVersionNumber) < 949)) { // 949 = LeopardのNSAppKitVersionNumber
        [super _clearTemporaryAttributesForCharacterRange:(struct _NSRange)fp8 changeInLength:(NSInteger)fp16];
    }
}
*/


@end



@implementation CELayoutManager (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)inGlyphIndex adjust:(NSSize)inSize
// グリフを描画する位置を返す
//------------------------------------------------------
{
    NSPoint outPoint = [self locationForGlyphAtIndex:inGlyphIndex];
    NSRect theGlyphRect = [self lineFragmentRectForGlyphAtIndex:inGlyphIndex effectiveRange:NULL];

    outPoint.x += inSize.width;
    outPoint.y = theGlyphRect.origin.y + inSize.height;

    return outPoint;
}



@end
