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
#import "CEATSTypesetter.h"
#import "constants.h"


@interface CELayoutManager ()

@property (nonatomic, retain) NSString *spaceCharacter;
@property (nonatomic, retain) NSString *tabCharacter;
@property (nonatomic, retain, getter=theNewLineCharacter) NSString *newLineCharacter;  // newから始まるproperty名が使えないためgetterにtheを付けている
@property (nonatomic, retain) NSString *fullwidthSpaceCharacter;
@property (nonatomic, retain) CEAppController *appController;
@property (nonatomic, assign) NSDictionary *attributes;  // not retained

// readonly properties
@property (nonatomic, assign, readwrite) CGFloat textFontPointSize;
@property (nonatomic, assign, readwrite) CGFloat defaultLineHeightForTextFont;
@property (nonatomic, assign, readwrite) CGFloat textFontGlyphY;

@end


//------------------------------------------------------------------------------------------


#pragma mark -

@implementation CELayoutManager

@synthesize showInvisibles = _showInvisibles;
@synthesize showOtherInvisibles = _showOtherInvisibles;
@synthesize textFont = _textFont;


#pragma mark Public Methods

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
        id values = [[NSUserDefaultsController sharedUserDefaultsController] values];

/*
// 削除しないこと！ ************* (1/12)
        NSString *fontName = [values valueForKey:k_key_fontName];
        CGFloat fontSize = (CGFloat)[[values valueForKey:k_key_fontSize] doubleValue];
        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
        NSColor *color = [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_invisibleCharactersColor]];
        [self setAttributes:@{NSFontAttributeName:font,
                              NSForegroundColorAttributeName:color}]; // ===== alloc

*/
//        [self setDefaultLineHeightForTextFont:0.0];
//        [self setTextFontPointSize:0.0];
        [self setTextFont:nil];

        [self setAppController:(CEAppController *)[NSApp delegate]]; // ===== retain

        [self setSpaceCharacter:[[self appController] invisibleSpaceCharacter:
                                 [[values valueForKey:k_key_invisibleSpace] unsignedIntegerValue]]]; // ===== retain
        [self setTabCharacter:[[self appController] invisibleTabCharacter:
                               [[values valueForKey:k_key_invisibleTab] unsignedIntegerValue]]]; // ===== retain
        [self setNewLineCharacter:[[self appController] invisibleNewLineCharacter:
                                   [[values valueForKey:k_key_invisibleNewLine] unsignedIntegerValue]]]; // ===== retain
        [self setFullwidthSpaceCharacter:[[self appController] invisibleFullwidthSpaceCharacter:
                                          [[values valueForKey:k_key_invisibleFullwidthSpace] unsignedIntegerValue]]]; // ===== retain

        // （setShowInvisibles: は CEEditorView から実行される。プリント時は CEDocument から実行される）
        [self setFixLineHeight:NO];
        [self setIsPrinting:NO];
        [self setShowSpace:[[values valueForKey:k_key_showInvisibleSpace] boolValue]];
        [self setShowTab:[[values valueForKey:k_key_showInvisibleTab] boolValue]];
        [self setShowNewLine:[[values valueForKey:k_key_showInvisibleNewLine] boolValue]];
        [self setShowFullwidthSpace:[[values valueForKey:k_key_showInvisibleFullwidthSpace] boolValue]];
        [self setShowOtherInvisibles:[[values valueForKey:k_key_showOtherInvisibleChars] boolValue]];
        [self setTypesetter:[CEATSTypesetter sharedSystemTypesetter]];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    // attributes was not retained.
    [[self spaceCharacter] release];
    [[self tabCharacter] release];
    [[self theNewLineCharacter] release];
    [[self fullwidthSpaceCharacter] release];
    [[self textFont] release];
    [[self appController] release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setLineFragmentRect:(NSRect)fragmentRect 
        forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
// 行描画矩形をセット
// ------------------------------------------------------
{
    if (![self isPrinting] && [self fixLineHeight]) {
        // 複合フォントで行の高さがばらつくのを防止する
        // （CETextViewCore で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じる）
        // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグで印刷中を確認）
        fragmentRect.size.height = [self lineHeight];
        usedRect.size.height = [self lineHeight];
    }

    (void)[super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}


// ------------------------------------------------------
- (void)setExtraLineFragmentRect:(NSRect)aRect
        usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)aTextContainer
// 最終行描画矩形をセット
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    aRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:aRect usedRect:usedRect textContainer:aTextContainer];
}


// ------------------------------------------------------
- (NSPoint)locationForGlyphAtIndex:(NSUInteger)glyphIndex
// グリフ位置を返す
// ------------------------------------------------------
{
    if (![self isPrinting] && [self fixLineHeight]) {
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
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// 不可視文字の表示
// ------------------------------------------------------
{
    // （印刷中の判定は、このメソッド内では [NSGraphicsContext currentContextDrawingToScreen] が使えるが、
    // 他のメソッドでは真を返す時があるため、他にそろえて専用フラグで印刷中を確認するようにしている）

    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *completeStr = [[self textStorage] string];
    NSUInteger rengthToRedraw = NSMaxRange(glyphsToShow);
    NSUInteger glyphIndex, charIndex = 0;
    NSInteger invisibleCharPrintMenuIndex;

    id view = [self firstTextView];
    if ([self isPrinting] && [view respondsToSelector:@selector(printValues)]) {
        invisibleCharPrintMenuIndex = [[[view printValues] valueForKey:k_printInvisibleCharIndex] integerValue];
    } else {
        invisibleCharPrintMenuIndex = [[values valueForKey:k_printInvisibleCharIndex] integerValue];
    }

    // フォントサイズは随時変更されるため、表示時に取得する
    NSFont *font = [self isPrinting] ? [[self textStorage] font] : [self textFont];
    NSColor *color = [NSUnarchiver unarchiveObjectWithData:[values valueForKey:k_key_invisibleCharactersColor]];
    [self setAttributes:@{NSFontAttributeName: font,
                          NSForegroundColorAttributeName: color}];

    unichar character;
    NSPoint pointToDraw;

    // スクリーン描画の時、アンチエイリアス制御
    if (![self isPrinting]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self useAntialias]];
    }

    if (((![self isPrinting] || (invisibleCharPrintMenuIndex == 1)) && [self showInvisibles]) ||
        ([self isPrinting] && (invisibleCharPrintMenuIndex == 2))) {

        CGFloat insetWidth = (CGFloat)[[values valueForKey:k_key_textContainerInsetWidth] doubleValue];
        CGFloat insetHeight = (CGFloat)[[values valueForKey:k_key_textContainerInsetHeightTop] doubleValue];
        if ([self isPrinting]) {
            NSPoint thePoint = [[self firstTextView] textContainerOrigin];
            insetWidth = thePoint.x;
            insetHeight = thePoint.y;
        }
        NSSize size = NSMakeSize(insetWidth, insetHeight);
        NSFont *replaceFont = [NSFont fontWithName:@"Lucida Grande" size:[[self textFont] pointSize]];
        NSGlyph glyph = [replaceFont glyphWithName:@"replacement"];

        for (glyphIndex = glyphsToShow.location; glyphIndex < rengthToRedraw; glyphIndex++) {
            charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            character = [completeStr characterAtIndex:charIndex];

            if ([self showSpace] && ((character == ' ') || (character == 0x00A0))) {
                pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:size];
                [[self spaceCharacter] drawAtPoint:pointToDraw withAttributes:[self attributes]];

            } else if ([self showTab] && (character == '\t')) {
                pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:size];
                [[self tabCharacter] drawAtPoint:pointToDraw withAttributes:[self attributes]];

            } else if ([self showNewLine] && (character == '\n')) {
                pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:size];
                [[self theNewLineCharacter] drawAtPoint:pointToDraw withAttributes:[self attributes]];

            } else if ([self showFullwidthSpace] && (character == 0x3000)) { // Fullwidth-space (JP)
                pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:size];
                [[self fullwidthSpaceCharacter] drawAtPoint:pointToDraw withAttributes:[self attributes]];

            } else if ([self showOtherInvisibles] && ([self glyphAtIndex:glyphIndex] == NSControlGlyph)) {
                NSRange charRange = NSMakeRange(charIndex, 1);
                NSString *baseStr = [completeStr substringWithRange:charRange];
                NSGlyphInfo *glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:glyph forFont:replaceFont baseString:baseStr];
                if (glyphInfo != nil) {
                    NSDictionary *replaceAttrs = @{NSGlyphInfoAttributeName: glyphInfo,
                                                   NSFontAttributeName: replaceFont,
                                                   NSForegroundColorAttributeName: color};
                    NSDictionary *attrs = [[self textStorage] attributesAtIndex:charIndex effectiveRange:NULL];
                    if (attrs[NSGlyphInfoAttributeName] == nil) {
                        [[self textStorage] addAttributes:replaceAttrs range:charRange];
                    }
                }
            }
        }
    }
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}


// ------------------------------------------------------
- (BOOL)showInvisibles
// 不可視文字を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showInvisibles;
}


// ------------------------------------------------------
- (void)setShowInvisibles:(BOOL)showInvisibles
// 不可視文字を表示するかどうかを設定する
// ------------------------------------------------------
{
    if (!showInvisibles) {
        NSRange range = NSMakeRange(0, [[[self textStorage] string] length]);
        [[self textStorage] removeAttribute:NSGlyphInfoAttributeName range:range];
    }
    if ([self showOtherInvisibles]) {
        [self setShowsControlCharacters:showInvisibles];
    }
    _showInvisibles = showInvisibles;
}


// ------------------------------------------------------
- (BOOL)showOtherInvisibles
// その他の不可視文字を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showOtherInvisibles;
}


// ------------------------------------------------------
- (void)setShowOtherInvisibles:(BOOL)showOtherInvisibles
// その他の不可視文字を表示するかどうかを設定する
// ------------------------------------------------------
{
    [self setShowsControlCharacters:showOtherInvisibles];
    _showOtherInvisibles = showOtherInvisibles;
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
- (void)setTextFont:(NSFont *)textFont
// 表示フォントをセット
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、自前でフォントを持っておく。
// （[[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、使わない）

    [textFont retain];
    [_textFont release];
    _textFont = textFont;
    [self setValuesForTextFont:textFont];
}


// ------------------------------------------------------
- (void)setValuesForTextFont:(NSFont *)textFont
// 表示フォントの各種値をキャッシュする
// ------------------------------------------------------
{
    if (textFont) {
        [self setDefaultLineHeightForTextFont:[self defaultLineHeightForFont:textFont] * k_defaultLineHeightMultiple];
        [self setTextFontPointSize:[textFont pointSize]];
        [self setTextFontGlyphY:[textFont pointSize]];
        // （textFontGlyphYは「複合フォントでも描画位置Y座標を固定」する時のみlocationForGlyphAtIndex:内で使われる。
        // 本来の値は[inFont ascender]か？ 2009.03.28）

        // [textFont pointSize]は通常、([textFont ascender] - [textFont descender])と一致する。例えばCourier 48ptだと、
        // ascender　=　36.187500, descender = -11.812500 となっている。 2009.03.28

    } else {
        [self setDefaultLineHeightForTextFont:0.0];
        [self setTextFontPointSize:0.0];
        [self setTextFontGlyphY:0.0];
    }
}


// ------------------------------------------------------
- (CGFloat)lineHeight
// 複合フォントで行の高さがばらつくのを防止するため、規定した行の高さを返す
// ------------------------------------------------------
{
    CGFloat lineSpacing = [(CETextViewCore *)[self firstTextView] lineSpacing];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return floor([self defaultLineHeightForTextFont] + lineSpacing * [self textFontPointSize] + 0.5);
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



#pragma mark -
#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex adjust:(NSSize)size
// グリフを描画する位置を返す
//------------------------------------------------------
{
    NSPoint drawPoint = [self locationForGlyphAtIndex:glyphIndex];
    NSRect theGlyphRect = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];

    drawPoint.x += size.width;
    drawPoint.y = theGlyphRect.origin.y + size.height;

    return drawPoint;
}

@end
