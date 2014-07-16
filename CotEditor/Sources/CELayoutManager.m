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
arranged by 1024jp, Mar 2014.
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

@import CoreText;
#import "CELayoutManager.h"
#import "CETextViewProtocol.h"
#import "CEATSTypesetter.h"
#import "CEUtils.h"
#import "constants.h"


@interface CELayoutManager ()

@property (nonatomic) unichar spaceChar;
@property (nonatomic) unichar tabChar;
@property (nonatomic) unichar newLineChar;
@property (nonatomic) unichar fullwidthSpaceChar;

// readonly properties
@property (nonatomic, readwrite) CGFloat textFontPointSize;
@property (nonatomic, readwrite) CGFloat defaultLineHeightForTextFont;
@property (nonatomic, readwrite) CGFloat textFontGlyphY;

@end




#pragma mark -

@implementation CELayoutManager

#pragma mark NSLayoutManager Methods

//=======================================================
// NSLayoutManager method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        _spaceChar = [CEUtils invisibleSpaceChar:[defaults integerForKey:k_key_invisibleSpace]];
        _tabChar = [CEUtils invisibleTabChar:[defaults integerForKey:k_key_invisibleTab]];
        _newLineChar = [CEUtils invisibleNewLineChar:[defaults integerForKey:k_key_invisibleNewLine]];
        _fullwidthSpaceChar = [CEUtils invisibleFullwidthSpaceChar:[defaults integerForKey:k_key_invisibleFullwidthSpace]];

        // （setShowInvisibles: は CEEditorView から実行される。プリント時は CEPrintView から実行される）
        _showSpace = [defaults boolForKey:k_key_showInvisibleSpace];
        _showTab = [defaults boolForKey:k_key_showInvisibleTab];
        _showNewLine = [defaults boolForKey:k_key_showInvisibleNewLine];
        _showFullwidthSpace = [defaults boolForKey:k_key_showInvisibleFullwidthSpace];
        _showOtherInvisibles = [defaults boolForKey:k_key_showOtherInvisibleChars];
        
        [self setShowsControlCharacters:_showOtherInvisibles];
        [self setTypesetter:[CEATSTypesetter sharedSystemTypesetter]];
    }
    return self;
}


// ------------------------------------------------------
/// 行描画矩形をセット
- (void)setLineFragmentRect:(NSRect)fragmentRect 
        forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
// ------------------------------------------------------
{
    if (![self isPrinting] && [self fixLineHeight]) {
        // 複合フォントで行の高さがばらつくのを防止する
        // （CETextView で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じる）
        // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグで印刷中を確認）
        fragmentRect.size.height = [self lineHeight];
        usedRect.size.height = [self lineHeight];
    }

    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}


// ------------------------------------------------------
/// 最終行描画矩形をセット
- (void)setExtraLineFragmentRect:(NSRect)aRect
        usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)aTextContainer
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    aRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:aRect usedRect:usedRect textContainer:aTextContainer];
}


// ------------------------------------------------------
/// グリフ位置を返す
- (NSPoint)locationForGlyphAtIndex:(NSUInteger)glyphIndex
// ------------------------------------------------------
{
    if (![self isPrinting] && [self fixLineHeight]) {
        // 複合フォントで描画位置Y座標が変わるのを防止する
        // （[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグで印刷中を確認）
        
        if ([[self firstTextView] layoutOrientation] != NSTextLayoutOrientationVertical) {
            // フォントサイズは随時変更されるため、表示時に取得する
            NSPoint point = [super locationForGlyphAtIndex:glyphIndex];
            point.y = [self textFontGlyphY];
            
            return point;
        }
    }

    return [super locationForGlyphAtIndex:glyphIndex];
}


// ------------------------------------------------------
/// 不可視文字の表示
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    // （印刷中の判定は、このメソッド内では [NSGraphicsContext currentContextDrawingToScreen] が使えるが、
    // 他のメソッドでは真を返す時があるため、他にそろえて専用フラグで印刷中を確認するようにしている）
    
    // スクリーン描画の時、アンチエイリアス制御
    if (![self isPrinting]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self useAntialias]];
    }
    
    // draw invisibles
    if ([self showInvisibles]) {
        NSTextView<CETextViewProtocol> *textView = (NSTextView<CETextViewProtocol> *)[self firstTextView];
        NSString *completeStr = [[self textStorage] string];
        NSUInteger lengthToRedraw = NSMaxRange(glyphsToShow);
        
        // フォントサイズは随時変更されるため、表示時に取得する
        NSFont *font = [self textFont];
        NSColor *color = [[textView theme] invisiblesColor];
        
        // for other invisibles
        NSFont *replaceFont;
        NSGlyph replaceGlyph;
        
        // prepare glyphs
        CGGlyph spaceGlyph = [self glyphWithCharacter:[self spaceChar] font:font];
        CGGlyph tabGlyph = [self glyphWithCharacter:[self tabChar] font:font];
        CGGlyph newLineGlyph = [self glyphWithCharacter:[self newLineChar] font:font];
        CGGlyph fullwidthSpaceGlyph = [self glyphWithCharacter:[self fullwidthSpaceChar] font:font];

        // set graphics context
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextSetFont(context, CTFontCopyGraphicsFont((CTFontRef)font, NULL));
        CGContextSetFontSize(context, [font pointSize]);
        
        // adjust drawing coordinate
        NSPoint inset = [textView textContainerOrigin];
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
        transform = CGAffineTransformTranslate(transform, inset.x, - inset.y - CTFontGetAscent((CTFontRef)font));
        CGContextSetTextMatrix(context, transform);
        
        // store value to avoid accessing properties each time  (2014-07 by 1024jp)
        BOOL showSpace = [self showSpace];
        BOOL showTab = [self showTab];
        BOOL showNewLine = [self showNewLine];
        BOOL showFullwidthSpace = [self showFullwidthSpace];
        BOOL showOtherInvisibles = [self showOtherInvisibles];
        
        // draw invisibles glyph by glyph
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < lengthToRedraw; glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeStr characterAtIndex:charIndex];

            if (showSpace && ((character == ' ') || (character == 0x00A0))) {
                CGPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGContextShowGlyphsAtPositions(context, &spaceGlyph, &point, 1);

            } else if (showTab && (character == '\t')) {
                CGPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGContextShowGlyphsAtPositions(context, &tabGlyph, &point, 1);
                
            } else if (showNewLine && (character == '\n')) {
                CGPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGContextShowGlyphsAtPositions(context, &newLineGlyph, &point, 1);

            } else if (showFullwidthSpace && (character == 0x3000)) { // Fullwidth-space (JP)
                CGPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGContextShowGlyphsAtPositions(context, &fullwidthSpaceGlyph, &point, 1);

            } else if (showOtherInvisibles && ([self glyphAtIndex:glyphIndex] == NSControlGlyph)) {
                if (!replaceFont) {  // delay creating font/glyph till they are really needed
                    replaceFont = [NSFont fontWithName:@"Lucida Grande" size:[font pointSize]];
                    replaceGlyph = [replaceFont glyphWithName:@"replacement"];
                }
                NSUInteger charLength = CFStringIsSurrogateHighCharacter(character) ? 2 : 1;
                NSRange charRange = NSMakeRange(charIndex, charLength);
                NSString *baseStr = [completeStr substringWithRange:charRange];
                NSGlyphInfo *glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:replaceGlyph forFont:replaceFont baseString:baseStr];
                
                if (glyphInfo) {
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
        CGContextRestoreGState(context);
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 不可視文字を表示するかどうかを設定する
- (void)setShowInvisibles:(BOOL)showInvisibles
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
/// その他の不可視文字を表示するかどうかを設定する
- (void)setShowOtherInvisibles:(BOOL)showOtherInvisibles
// ------------------------------------------------------
{
    [self setShowsControlCharacters:showOtherInvisibles];
    _showOtherInvisibles = showOtherInvisibles;
}


// ------------------------------------------------------
/// 表示フォントをセット
- (void)setTextFont:(NSFont *)textFont
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、自前でフォントを持っておく。
// （[[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、使わない）

    _textFont = textFont;
    [self setValuesForTextFont:textFont];
}


// ------------------------------------------------------
/// 表示フォントの各種値をキャッシュする
- (void)setValuesForTextFont:(NSFont *)textFont
// ------------------------------------------------------
{
    if (textFont) {
        [self setDefaultLineHeightForTextFont:[self defaultLineHeightForFont:textFont] * k_defaultLineHeightMultiple];
        [self setTextFontPointSize:[textFont pointSize]];
        [self setTextFontGlyphY:[textFont pointSize]];
        // （textFontGlyphYは「複合フォントでも描画位置Y座標を固定」する時のみlocationForGlyphAtIndex:内で使われる。
        // 本来の値は[textFont ascender]か？ 2009.03.28）

        // [textFont pointSize]は通常、([textFont ascender] - [textFont descender])と一致する。例えばCourier 48ptだと、
        // ascender　=　36.187500, descender = -11.812500 となっている。 2009.03.28

    } else {
        [self setDefaultLineHeightForTextFont:0.0];
        [self setTextFontPointSize:0.0];
        [self setTextFontGlyphY:0.0];
    }
}


// ------------------------------------------------------
/// 複合フォントで行の高さがばらつくのを防止するため、規定した行の高さを返す
- (CGFloat)lineHeight
// ------------------------------------------------------
{
    CGFloat lineSpacing = [(NSTextView<CETextViewProtocol> *)[self firstTextView] lineSpacing];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return floor([self defaultLineHeightForTextFont] + lineSpacing * [self textFontPointSize] + 0.5);
}



#pragma mark - Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// グリフを描画する位置を返す
- (CGPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex
//------------------------------------------------------
{
    NSPoint drawPoint = [self locationForGlyphAtIndex:glyphIndex];
    NSPoint glyphPoint = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL].origin;
    
    return CGPointMake(drawPoint.x, -glyphPoint.y);
}



//------------------------------------------------------
/// 文字とフォントから CGGlyph を生成して返す
- (CGGlyph)glyphWithCharacter:(unichar)character font:(NSFont *)font
//------------------------------------------------------
{
    CGGlyph glyph;
    
    CTFontGetGlyphsForCharacters((CTFontRef)font, &character, &glyph, 1);
    
    return glyph;
}

@end
