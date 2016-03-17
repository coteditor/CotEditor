/*
 
 CELayoutManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-01-10.

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

@import CoreText;
#import "CELayoutManager.h"
#import "CETextViewProtocol.h"
#import "CEATSTypesetter.h"
#import "CEInvisibles.h"
#import "CEDefaults.h"


// constants
static CGFloat const kDefaultLineHeightMultiple = 1.19;
static NSString * _Nonnull const HiraginoSans = @"HiraginoSans-W3";  // since OS X 10.11 (El Capitan)
static NSString * _Nonnull const HiraKakuProN = @"HiraKakuProN-W3";


@interface CELayoutManager ()

@property (nonatomic) BOOL showsSpace;
@property (nonatomic) BOOL showsTab;
@property (nonatomic) BOOL showsNewLine;
@property (nonatomic) BOOL showsFullwidthSpace;

@property (nonatomic) unichar spaceChar;
@property (nonatomic) unichar tabChar;
@property (nonatomic) unichar newLineChar;
@property (nonatomic) unichar fullwidthSpaceChar;

@property (nonatomic) CGFloat spaceWidth;

// readonly properties
@property (readwrite, nonatomic) CGFloat defaultLineHeightForTextFont;
@property (readwrite, nonatomic) BOOL showsOtherInvisibles;

@end




#pragma mark -

@implementation CELayoutManager

static BOOL usesTextFontForInvisibles;
static NSString *HiraginoSansName;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        usesTextFontForInvisibles = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultUsesTextFontForInvisiblesKey];
        
        // check Hiragino font availability
        if ([[[NSFontManager sharedFontManager] availableFonts] containsObject:HiraginoSans]) {
            HiraginoSansName = HiraginoSans;
        } else {
            HiraginoSansName = HiraKakuProN;
        }
    });
}


// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        _spaceChar = [CEInvisibles spaceCharWithIndex:[defaults integerForKey:CEDefaultInvisibleSpaceKey]];
        _tabChar = [CEInvisibles tabCharWithIndex:[defaults integerForKey:CEDefaultInvisibleTabKey]];
        _newLineChar = [CEInvisibles newLineCharWithIndex:[defaults integerForKey:CEDefaultInvisibleNewLineKey]];
        _fullwidthSpaceChar = [CEInvisibles fullwidthSpaceCharWithIndex:[defaults integerForKey:CEDefaultInvisibleFullwidthSpaceKey]];

        // （setShowsInvisibles: は CEEditorViewController から実行される。プリント時は CEPrintView から実行される）
        _showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        _showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        _showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        _showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        _showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        
        // Since NSLayoutManager's showsControlCharacters flag is totally buggy (at leaset on El Capitan),
        // we stopped using this since CotEditor 2.3.3 that was released in 2016-01.
        // Previously, CotEditor used this flag for "Other Invisible Characters."
        // However as CotEditor draws such control-glyph-alternative-characters by itself in `drawGlyphsForGlyphRange:atPoint:`,
        // this flag is actually not so necessary as I thougth. Thus, treat carefully this.
        [self setShowsControlCharacters:NO];
        
        [self setUsesScreenFonts:YES];
        [self setTypesetter:[[CEATSTypesetter alloc] init]];
    }
    return self;
}


// ------------------------------------------------------
/// 行描画矩形をセット
- (void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
// ------------------------------------------------------
{
    if ([self fixesLineHeight]) {
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
- (void)setExtraLineFragmentRect:(NSRect)aRect usedRect:(NSRect)usedRect textContainer:(nonnull NSTextContainer *)aTextContainer
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    aRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:aRect usedRect:usedRect textContainer:aTextContainer];
}


// ------------------------------------------------------
/// 不可視文字の表示
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    // set anti-alias state on screen drawing
    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self usesAntialias]];
    }
    
    // draw invisibles
    if ([self showsInvisibles]) {
        NSString *completeString = [[self textStorage] string];
        NSUInteger lengthToRedraw = NSMaxRange(glyphsToShow);
        
        // フォントサイズは随時変更されるため、表示時に取得する
        CTFontRef font = (__bridge CTFontRef)[self textFont];
        NSColor *color = [[self theme] invisiblesColor];
        CGFloat baselineOffset = [self defaultBaselineOffsetForFont:[self textFont]];
        
        // set graphics context
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGMutablePathRef paths = CGPathCreateMutable();
        
        // adjust drawing coordinate
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
        transform = CGAffineTransformTranslate(transform, origin.x, - origin.y);
        CGContextConcatCTM(context, transform);
        
        // prepare glyphs
        CGPathRef spaceGlyphPath = glyphPathWithCharacter([self spaceChar], font, false);
        CGPathRef tabGlyphPath = glyphPathWithCharacter([self tabChar], font, false);
        CGPathRef newLineGlyphPath = glyphPathWithCharacter([self newLineChar], font, false);
        CGPathRef fullWidthSpaceGlyphPath = glyphPathWithCharacter([self fullwidthSpaceChar], font, true);
        CGPathRef verticalTabGlyphPath = glyphPathWithCharacter([CEInvisibles verticalTabChar], font, true);
        CGPathRef replacementGlyphPath = glyphPathWithCharacter([CEInvisibles replacementChar], font, true);
        
        // store value to avoid accessing properties each time  (2014-07 by 1024jp)
        BOOL showsSpace = [self showsSpace];
        BOOL showsTab = [self showsTab];
        BOOL showsNewLine = [self showsNewLine];
        BOOL showsFullwidthSpace = [self showsFullwidthSpace];
        BOOL showsVerticalTab = [self showsOtherInvisibles];  // Vertical tab belongs to other invisibles.
        BOOL showsOtherInvisibles = [self showsOtherInvisibles];
        
        // draw invisibles glyph by glyph
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < lengthToRedraw; glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeString characterAtIndex:charIndex];
            
            CGPathRef glyphPath;
            switch (character) {
                case ' ':
                case 0x00A0:
                    if (!showsSpace) { continue; }
                    glyphPath = spaceGlyphPath;
                    break;
                    
                case '\t':
                    if (!showsTab) { continue; }
                    glyphPath = tabGlyphPath;
                    break;
                    
                case '\n':
                    if (!showsNewLine) { continue; }
                    glyphPath = newLineGlyphPath;
                    break;
                    
                case 0x3000:  // fullwidth-space (JP)
                    if (!showsFullwidthSpace) { continue; }
                    glyphPath = fullWidthSpaceGlyphPath;
                    break;
                    
                case '\v':
                    if (!showsVerticalTab) { continue; }
                    glyphPath = verticalTabGlyphPath;
                    break;
                    
                default:
                    if (!showsOtherInvisibles || ([self glyphAtIndex:glyphIndex isValidIndex:NULL] != NSControlGlyph)) { continue; }
                    // Skip the second glyph if character is a surrogate-pair
                    if (CFStringIsSurrogateLowCharacter(character) &&
                        ((charIndex > 0) && CFStringIsSurrogateHighCharacter([completeString characterAtIndex:charIndex - 1])))
                    {
                        continue;
                    }
                    glyphPath = replacementGlyphPath;
            }
            
            // add invisible char path
            NSPoint point = [self pointToDrawGlyphAtIndex:glyphIndex verticalOffset:baselineOffset];
            CGAffineTransform translate = CGAffineTransformMakeTranslation(point.x, -point.y);
            CGPathAddPath(paths, &translate, glyphPath);
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
        CGPathRelease(verticalTabGlyphPath);
        CGPathRelease(replacementGlyphPath);
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}


// ------------------------------------------------------
/// textStorage did update
- (void)textStorage:(nonnull NSTextStorage *)str edited:(NSTextStorageEditedOptions)editedMask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange
// ------------------------------------------------------
{
    // invalidate wrapping line indent in editRange if needed
    if (editedMask & NSTextStorageEditedCharacters &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnablesHangingIndentKey])
    {
        // invoke after processEditing so that textStorage can be modified safety
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf invalidateIndentInRange:newCharRange];
        });
    }
    
    [super textStorage:str edited:editedMask range:newCharRange changeInLength:delta invalidatedRange:invalidatedCharRange];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 表示フォントをセット
- (void)setTextFont:(nullable NSFont *)textFont
// ------------------------------------------------------
{
    // 複合フォントで行間が等間隔でなくなる問題を回避するため、自前でフォントを持っておく。
    // （[[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
    // 日本語フォント名を返してくることがあるため、使わない）

    _textFont = textFont;
    
    // cache default line height
    CGFloat defaultLineHeight = textFont ? [self defaultLineHeightForFont:textFont] : 0.0;
    [self setDefaultLineHeightForTextFont:defaultLineHeight * kDefaultLineHeightMultiple];
    
    // store width of space char for hanging indent width calculation
    NSFont *screenFont = [textFont screenFont] ? : textFont;
    [self setSpaceWidth:[screenFont advancementForGlyph:(NSGlyph)' '].width];
}


// ------------------------------------------------------
/// update invisible characters visibility if needed
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    if (showsInvisibles == _showsInvisibles) { return; }
    
    _showsInvisibles = showsInvisibles;
    
    NSRange wholeRange = NSMakeRange(0, [[self textStorage] length]);
    if ([self showsOtherInvisibles]) {
        // -> force recaluculate layout in order to make spaces for control characters drawing
        [self invalidateGlyphsForCharacterRange:wholeRange changeInLength:0 actualCharacterRange:NULL];
        [self invalidateLayoutForCharacterRange:wholeRange actualCharacterRange:NULL];
    } else {
        [self invalidateDisplayForCharacterRange:wholeRange];
    }
}


// ------------------------------------------------------
/// 複合フォントで行の高さがばらつくのを防止するため、規定した行の高さを返す
- (CGFloat)lineHeight
// ------------------------------------------------------
{
    CGFloat lineSpacing = [(NSTextView<CETextViewProtocol> *)[self firstTextView] lineSpacing];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return round([self defaultLineHeightForTextFont] + lineSpacing * [[self textFont] pointSize]);
}


// ------------------------------------------------------
/// invalidate indent of wrapped lines
- (void)invalidateIndentInRange:(NSRange)range
// ------------------------------------------------------
{
    // !!!: quick fix avoiding crash on typing Japanese text (2015-10)
    //  -> text length can be changed while passing run-loop
    if (NSMaxRange(range) > [[self textStorage] length]) {
        NSUInteger overflow = NSMaxRange(range) - [[self textStorage] length];
        if (range.length >= overflow) {
            range.length -= overflow;
        } else {
            // nothing to do about hanging indentation if changed range has already been completely removed
            return;
        }
    }
    
    CGFloat hangingIndent = [self spaceWidth] * [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultHangingIndentWidthKey];
    CGFloat linePadding = [[[self firstTextView] textContainer] lineFragmentPadding];
    NSTextStorage *textStorage = [self textStorage];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[ \\t]+(?!$)" options:0 error:nil];
    
    NSMutableArray<NSDictionary<NSString *, id> *> *newIndents = [NSMutableArray array];
    
    // invalidate line by line
    NSRange lineRange = [[textStorage string] lineRangeForRange:range];
    __weak typeof(self) weakSelf = self;
    [[textStorage string] enumerateSubstringsInRange:lineRange
                                             options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                          usingBlock:^(NSString *substring,
                                                       NSRange substringRange,
                                                       NSRange enclosingRange,
                                                       BOOL *stop)
     {
         typeof(weakSelf) self = weakSelf;
         if (!self) {
             *stop = YES;
             return;
         }
         
         CGFloat indent = hangingIndent;
         
         // add base indent
         NSRange baseIndentRange = [regex rangeOfFirstMatchInString:[textStorage string] options:0 range:substringRange];
         if (baseIndentRange.location != NSNotFound) {
             // getting the start line of the character jsut after the last indent character
             //   -> This is actually better in terms of performance than getting whole bounding rect using `boundingRectForGlyphRange:inTextContainer:`
             NSUInteger firstGlyphIndex = [self glyphIndexForCharacterAtIndex:NSMaxRange(baseIndentRange)];
             NSPoint firstGlyphLocation = [self locationForGlyphAtIndex:firstGlyphIndex];  // !!!: performance critical
             indent += firstGlyphLocation.x - linePadding;
         }
         
         // apply new indent only if needed
         NSParagraphStyle *paragraphStyle = [textStorage attribute:NSParagraphStyleAttributeName
                                                           atIndex:substringRange.location
                                                    effectiveRange:NULL];
         if (indent != [paragraphStyle headIndent]) {
             NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
             [mutableParagraphStyle setHeadIndent:indent];
             
             // store the result
             //   -> Don't apply to the textStorage at this moment.
             [newIndents addObject:@{@"paragraphStyle": [mutableParagraphStyle copy],
                                     @"range": [NSValue valueWithRange:substringRange]}];
         }
     }];
    
    if ([newIndents count] == 0) { return; }
    
    // apply new paragraph styles at once
    //   -> This avoids letting layoutManager calculate glyph location each time.
    [textStorage beginEditing];
    for (NSDictionary<NSString *, id> *indent in newIndents) {
        NSRange range = [indent[@"range"] rangeValue];
        NSParagraphStyle *paragraphStyle = indent[@"paragraphStyle"];
        
        [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    }
    [textStorage endEditing];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// current theme
- (nullable CETheme *)theme
// ------------------------------------------------------
{
    return [(NSTextView<CETextViewProtocol> *)[self firstTextView] theme];
}


//------------------------------------------------------
/// グリフを描画する位置を返す
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex verticalOffset:(CGFloat)offset
//------------------------------------------------------
{
    NSPoint origin = [self lineFragmentRectForGlyphAtIndex:glyphIndex
                                            effectiveRange:NULL
                                   withoutAdditionalLayout:YES].origin;
    NSPoint glyphLocation = [self locationForGlyphAtIndex:glyphIndex];
    
    origin.x += glyphLocation.x;
    origin.y += offset;
    
    return origin;
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
    // - Monaco for vertical tab
    CGPathRef path = NULL;
    NSArray<NSString *> *fallbackFontNames = (prefersFullWidth
                                              ? @[HiraginoSansName, @"LucidaGrande", @"Monaco"]
                                              : @[@"LucidaGrande", HiraginoSansName, @"Monaco"]);
    
    for (NSString *fontName in fallbackFontNames) {
        CTFontRef fallbackFont = CTFontCreateWithName((CFStringRef)fontName, fontSize, 0);
        if (CTFontGetGlyphsForCharacters(fallbackFont, &character, &glyph, 1)) {
            path = CTFontCreatePathForGlyph(fallbackFont, glyph, NULL);
            CFRelease(fallbackFont);
            break;
        }
        CFRelease(fallbackFont);
    }
    
    return path;
}

@end
