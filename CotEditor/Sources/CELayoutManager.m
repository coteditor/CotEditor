/*
 ==============================================================================
 CELayoutManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-01-10 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

@import CoreText;
#import "CELayoutManager.h"
#import "CETextViewProtocol.h"
#import "CEATSTypesetter.h"
#import "CEUtils.h"
#import "constants.h"


@interface CELayoutManager ()

@property (nonatomic) BOOL showsSpace;
@property (nonatomic) BOOL showsTab;
@property (nonatomic) BOOL showsNewLine;
@property (nonatomic) BOOL showsFullwidthSpace;
@property (nonatomic) BOOL showsOtherInvisibles;

@property (nonatomic) unichar spaceChar;
@property (nonatomic) unichar tabChar;
@property (nonatomic) unichar newLineChar;
@property (nonatomic) unichar fullwidthSpaceChar;

// readonly properties
@property (readwrite, nonatomic) CGFloat textFontPointSize;
@property (readwrite, nonatomic) CGFloat defaultLineHeightForTextFont;
@property (readwrite, nonatomic) CGFloat textFontGlyphY;

@end




#pragma mark -

@implementation CELayoutManager

static BOOL usesTextFontForInvisibles;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        usesTextFontForInvisibles = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultUsesTextFontForInvisiblesKey];
    });
}


// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        _spaceChar = [CEUtils invisibleSpaceChar:[defaults integerForKey:CEDefaultInvisibleSpaceKey]];
        _tabChar = [CEUtils invisibleTabChar:[defaults integerForKey:CEDefaultInvisibleTabKey]];
        _newLineChar = [CEUtils invisibleNewLineChar:[defaults integerForKey:CEDefaultInvisibleNewLineKey]];
        _fullwidthSpaceChar = [CEUtils invisibleFullwidthSpaceChar:[defaults integerForKey:CEDefaultInvisibleFullwidthSpaceKey]];

        // （setShowsInvisibles: は CEEditorView から実行される。プリント時は CEPrintView から実行される）
        _showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        _showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        _showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        _showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        _showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        
        [self setUsesScreenFonts:YES];
        [self setShowsControlCharacters:_showsOtherInvisibles];
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
    if (![self isPrinting] && [self fixesLineHeight]) {
        // 複合フォントで行の高さがばらつくのを防止する
        // （CETextView で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じる））
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
    if (![self isPrinting] && [self fixesLineHeight]) {
        // 複合フォントで描画位置Y座標が変わるのを防止する
        
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
    // スクリーン描画の時、アンチエイリアス制御
    if (![self isPrinting]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self usesAntialias]];
    }
    
    // draw invisibles
    if ([self showsInvisibles]) {
        NSTextView<CETextViewProtocol> *textView = (NSTextView<CETextViewProtocol> *)[self firstTextView];
        NSString *completeStr = [[self textStorage] string];
        NSUInteger lengthToRedraw = NSMaxRange(glyphsToShow);
        
        // フォントサイズは随時変更されるため、表示時に取得する
        CGFloat fontSize = [self textFontPointSize];
        CTFontRef font = (__bridge CTFontRef)[self textFont];
        NSColor *color = [[textView theme] invisiblesColor];
        
        // for other invisibles
        NSFont *replaceFont;
        NSGlyph replaceGlyph;
        
        // set graphics context
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGMutablePathRef paths = CGPathCreateMutable();
        
        // adjust drawing coordinate
        NSPoint inset = [textView textContainerOrigin];
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
        transform = CGAffineTransformTranslate(transform, inset.x, - inset.y - CTFontGetAscent(font));
        CGContextConcatCTM(context, transform);
        
        // prepare glyphs
        CGPathRef spaceGlyphPath = glyphPathWithCharacter([self spaceChar], font, false);
        CGPathRef tabGlyphPath = glyphPathWithCharacter([self tabChar], font, false);
        CGPathRef newLineGlyphPath = glyphPathWithCharacter([self newLineChar], font, false);
        CGPathRef fullWidthSpaceGlyphPath = glyphPathWithCharacter([self fullwidthSpaceChar], font, true);
        
        // store value to avoid accessing properties each time  (2014-07 by 1024jp)
        BOOL showsSpace = [self showsSpace];
        BOOL showsTab = [self showsTab];
        BOOL showsNewLine = [self showsNewLine];
        BOOL showsFullwidthSpace = [self showsFullwidthSpace];
        BOOL showsOtherInvisibles = [self showsOtherInvisibles];
        
        // draw invisibles glyph by glyph
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < lengthToRedraw; glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeStr characterAtIndex:charIndex];

            if (showsSpace && ((character == ' ') || (character == 0x00A0))) {
                NSPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGAffineTransform translate = CGAffineTransformMakeTranslation(point.x, point.y);
                CGPathAddPath(paths, &translate, spaceGlyphPath);

            } else if (showsTab && (character == '\t')) {
                NSPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGAffineTransform translate = CGAffineTransformMakeTranslation(point.x, point.y);
                CGPathAddPath(paths, &translate, tabGlyphPath);
                
            } else if (showsNewLine && (character == '\n')) {
                NSPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGAffineTransform translate = CGAffineTransformMakeTranslation(point.x, point.y);
                CGPathAddPath(paths, &translate, newLineGlyphPath);

            } else if (showsFullwidthSpace && (character == 0x3000)) { // Fullwidth-space (JP)
                NSPoint point = [self pointToDrawGlyphAtIndex:glyphIndex];
                CGAffineTransform translate = CGAffineTransformMakeTranslation(point.x, point.y);
                CGPathAddPath(paths, &translate, fullWidthSpaceGlyphPath);

            } else if (showsOtherInvisibles && ([self glyphAtIndex:glyphIndex isValidIndex:NULL] == NSControlGlyph)) {
                if (!replaceFont) {  // delay creating font/glyph till they are really needed
                    replaceFont = [NSFont fontWithName:@"Lucida Grande" size:fontSize];
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
        
        // draw invisible glyphs (excl. other invisibles)
        CGContextAddPath(context, paths);
        CGContextFillPath(context);
        
        // release
        CGContextRestoreGState(context);
        CGPathRelease(paths);
        CGPathRelease(spaceGlyphPath);
        CGPathRelease(tabGlyphPath);
        CGPathRelease(newLineGlyphPath);
        CGPathRelease(fullWidthSpaceGlyphPath);
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// [NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、印刷用かを保持する専用フラグを用意
- (void)setPrinting:(BOOL)printing
// ------------------------------------------------------
{
    [self setUsesScreenFonts:!printing];
    
    _printing = printing;
}

// ------------------------------------------------------
/// 不可視文字を表示するかどうかを設定する
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    if (!showsInvisibles) {
        NSRange range = NSMakeRange(0, [[[self textStorage] string] length]);
        [[self textStorage] removeAttribute:NSGlyphInfoAttributeName range:range];
    }
    if ([self showsOtherInvisibles]) {
        [self setShowsControlCharacters:showsInvisibles];
    }
    _showsInvisibles = showsInvisibles;
}


// ------------------------------------------------------
/// その他の不可視文字を表示するかどうかを設定する
- (void)setShowsOtherInvisibles:(BOOL)showsOtherInvisibles
// ------------------------------------------------------
{
    [self setShowsControlCharacters:showsOtherInvisibles];
    _showsOtherInvisibles = showsOtherInvisibles;
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
        [self setDefaultLineHeightForTextFont:[self defaultLineHeightForFont:textFont] * kDefaultLineHeightMultiple];
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
    return round([self defaultLineHeightForTextFont] + lineSpacing * [self textFontPointSize]);
}



#pragma mark Private Methods

//------------------------------------------------------
/// グリフを描画する位置を返す
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex
//------------------------------------------------------
{
    NSPoint drawPoint = [self locationForGlyphAtIndex:glyphIndex];
    NSPoint glyphPoint = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL].origin;
    
    return NSMakePoint(drawPoint.x, -glyphPoint.y);
}



//------------------------------------------------------
/// 文字とフォントからアウトラインパスを生成して返す
CGPathRef glyphPathWithCharacter(unichar character, CTFontRef font, bool prefersFullWidth)
//------------------------------------------------------
{
    CGFloat fontSize = CTFontGetSize(font);
    CGGlyph glyph;
    
    if (usesTextFontForInvisibles) {
        if (CTFontGetGlyphsForCharacters(font, &character, &glyph, 1)) {
            return CTFontCreatePathForGlyph(font, glyph, NULL);
        }
    }
    
    // try fallback fonts in cases where user font doesn't support the input charactor
    // - All invisible characters of choices can be covered with the following two fonts.
    CGPathRef path = NULL;
    NSArray *fallbackFontNames = prefersFullWidth ? @[@"HiraKakuProN-W3", @"LucidaGrande"] : @[@"LucidaGrande", @"HiraKakuProN-W3"];
    
    for (NSString *fontName in fallbackFontNames) {
        CTFontRef fallbackFont = CTFontCreateWithName((CFStringRef)fontName, fontSize, 0);
        if (CTFontGetGlyphsForCharacters(fallbackFont, &character, &glyph, 1)) {
            path = CTFontCreatePathForGlyph(fallbackFont, glyph, NULL);
            break;
        }
        CFRelease(fallbackFont);
    }
    
    return path;
}

@end
