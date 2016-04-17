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


// convenient function
CTLineRef createCTLineRefWithString(NSString *string, NSDictionary *attributes)
{
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    return CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
}


@interface CELayoutManager ()

@property (nonatomic) BOOL showsSpace;
@property (nonatomic) BOOL showsTab;
@property (nonatomic) BOOL showsNewLine;
@property (nonatomic) BOOL showsFullwidthSpace;

@property (nonatomic, nonnull, copy) NSArray<NSString *> *invisibles;
@property (nonatomic, nullable) NSArray<id> *invisibleLines;  // array of CTLineRef

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
        
        _invisiblesColor = [NSColor disabledControlTextColor];
        
        _invisibles = @[[CEInvisibles stringWithType:CEInvisibleSpace Index:[defaults integerForKey:CEDefaultInvisibleSpaceKey]],
                        [CEInvisibles stringWithType:CEInvisibleTab Index:[defaults integerForKey:CEDefaultInvisibleTabKey]],
                        [CEInvisibles stringWithType:CEInvisibleNewLine Index:[defaults integerForKey:CEDefaultInvisibleNewLineKey]],
                        [CEInvisibles stringWithType:CEInvisibleFullWidthSpace Index:[defaults integerForKey:CEDefaultInvisibleFullwidthSpaceKey]],
                        [CEInvisibles stringWithType:CEInvisibleVerticalTab Index:NULL],
                        [CEInvisibles stringWithType:CEInvisibleReplacement Index:NULL],
                        ];
        
        // （setShowsInvisibles: は CEEditorViewController から実行される。プリント時は CEPrintView から実行される）
        _showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        _showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        _showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        _showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        _showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        
        // Since NSLayoutManager's showsControlCharacters flag is totally buggy (at least on El Capitan),
        // we stopped using it since CotEditor 2.3.3 released in 2016-01.
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
/// draw invisible characters
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    // set anti-alias state on screen drawing
    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self usesAntialias]];
    }
    
    // draw invisibles
    if ([self showsInvisibles] || [[self invisibleLines] count] > 0) {
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        NSString *completeString = [[self textStorage] string];
        CGFloat baselineOffset = [self defaultBaselineOffsetForFont:[self textFont]];
        
        // flip coordinate if needed
        if ([[NSGraphicsContext currentContext] isFlipped]) {
            CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0));
        }
        
        // draw invisibles glyph by glyph
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < NSMaxRange(glyphsToShow); glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeString characterAtIndex:charIndex];
            
            CEInvisibleType invisibleType;
            switch (character) {
                case ' ':
                case 0x00A0:
                    if (![self showsSpace]) { continue; }
                    invisibleType = CEInvisibleSpace;
                    break;
                    
                case '\t':
                    if (![self showsTab]) { continue; }
                    invisibleType = CEInvisibleTab;
                    break;
                    
                case '\n':
                    if (![self showsNewLine]) { continue; }
                    invisibleType = CEInvisibleNewLine;
                    break;
                    
                case 0x3000:  // fullwidth-space (JP)
                    if (![self showsFullwidthSpace]) { continue; }
                    invisibleType = CEInvisibleFullWidthSpace;
                    break;
                    
                case '\v':
                    if (![self showsOtherInvisibles]) { continue; }  // Vertical tab belongs to the other invisibles.
                    invisibleType = CEInvisibleVerticalTab;
                    break;
                    
                default:
                    if (![self showsOtherInvisibles] || ([self glyphAtIndex:glyphIndex isValidIndex:NULL] != NSControlGlyph)) { continue; }
                    // skip the second glyph if character is a surrogate-pair
                    if (CFStringIsSurrogateLowCharacter(character) &&
                        ((charIndex > 0) && CFStringIsSurrogateHighCharacter([completeString characterAtIndex:charIndex - 1])))
                    {
                        continue;
                    }
                    invisibleType = CEInvisibleReplacement;
            }
            
            CTLineRef line = (__bridge CTLineRef)[self invisibleLines][invisibleType];
            
            // calcurate position to draw glyph
            NSPoint point = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL withoutAdditionalLayout:YES].origin;
            NSPoint glyphLocation = [self locationForGlyphAtIndex:glyphIndex];
            point.x += glyphLocation.x + origin.x;
            point.y += baselineOffset + origin.y;
            
            // draw character
            CGContextSetTextPosition(context, point.x, point.y);
            CTLineDraw(line, context);
        }
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
/// set text font to use and cache values
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
    
    [self invalidateInvisiblesStyle];
}


// ------------------------------------------------------
/// update invisibles color
- (void)setInvisiblesColor:(NSColor *)invisiblesColor
// ------------------------------------------------------
{
    _invisiblesColor = invisiblesColor;
    
    [self invalidateInvisiblesStyle];
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
    NSTextStorage *textStorage = [self textStorage];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[ \\t]+(?!$)" options:0 error:nil];
    
    NSMutableArray<NSDictionary<NSString *, id> *> *newIndents = [NSMutableArray array];
    
    // get dummy attributes to make calcuration of indent width the same as CElayoutManager's calcuration (2016-04)
    NSMutableDictionary *indentAttributes = [[[self firstTextView] typingAttributes] mutableCopy];
    NSMutableParagraphStyle *typingParagraphStyle = [indentAttributes[NSParagraphStyleAttributeName] mutableCopy];
    [typingParagraphStyle setHeadIndent:1.0];  // dummy indent value for size calcuration (2016-04)
    indentAttributes[NSParagraphStyleAttributeName] = [typingParagraphStyle copy];
    
    // invalidate line by line
    NSRange lineRange = [[textStorage string] lineRangeForRange:range];
    [[textStorage string] enumerateSubstringsInRange:lineRange
                                             options:NSStringEnumerationByLines
                                          usingBlock:^(NSString *substring,
                                                       NSRange substringRange,
                                                       NSRange enclosingRange,
                                                       BOOL *stop)
     {
         CGFloat indent = hangingIndent;
         
         // add base indent
         NSRange baseIndentRange = [regex rangeOfFirstMatchInString:substring options:0 range:NSMakeRange(0, substring.length)];
         if (baseIndentRange.location != NSNotFound) {
             NSString *indentString = [substring substringWithRange:baseIndentRange];
             indent += [indentString sizeWithAttributes:indentAttributes].width;
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
/// cache CTLineRefs for invisible characters drawing
- (void)invalidateInvisiblesStyle
// ------------------------------------------------------
{
    NSFont *font;
    if (usesTextFontForInvisibles) {
        font = [self textFont];
    } else {
        CGFloat fontSize = [[self textFont] pointSize];
        font = [[NSFont fontWithName:@"LucidaGrande" size:fontSize] screenFont] ?: [NSFont systemFontOfSize:fontSize];
    }
    NSFont *fullWidthFont = [[NSFont fontWithName:HiraginoSansName size:[font pointSize]] screenFont];
    
    NSDictionary<NSString *, id> *attributes = @{NSForegroundColorAttributeName: [self invisiblesColor],
                                                 NSFontAttributeName: font};
    NSDictionary<NSString *, id> *fullWidthAttributes = @{NSForegroundColorAttributeName: [self invisiblesColor],
                                                          NSFontAttributeName: fullWidthFont ?: font};
    
    [self setInvisibleLines:@[(__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleSpace], attributes),
                              (__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleTab], attributes),
                              (__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleNewLine], attributes),
                              (__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleFullWidthSpace], fullWidthAttributes),
                              (__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleVerticalTab], fullWidthAttributes),
                              (__bridge_transfer id)createCTLineRefWithString([self invisibles][CEInvisibleReplacement], fullWidthAttributes),
                              ]];
}

@end
