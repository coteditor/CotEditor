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

#import "NSFont+CESize.h"


// constants
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

@property (nonatomic) CGFloat defaultLineHeight;

// readonly properties
@property (readwrite, nonatomic) CGFloat spaceWidth;
@property (readwrite, nonatomic) CGFloat defaultBaselineOffset;
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
        _invisiblesColor = [NSColor disabledControlTextColor];
        
        [self applyDefaultInvisiblesSetting];
        
        // Since NSLayoutManager's showsControlCharacters flag is totally buggy (at least on El Capitan),
        // we stopped using it since CotEditor 2.3.3 released in 2016-01.
        // Previously, CotEditor used this flag for "Other Invisible Characters."
        // However as CotEditor draws such control-glyph-alternative-characters by itself in `drawGlyphsForGlyphRange:atPoint:`,
        // this flag is actually not so necessary as I thougth. Thus, treat carefully this.
        [self setShowsControlCharacters:NO];
        
        [self setUsesScreenFonts:YES];
        [self setTypesetter:[[CEATSTypesetter alloc] init]];
        
        // observe change of defaults
        for (NSString *key in [[self class] observedDefaultKeys]) {
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:key options:0 context:NULL];
        }
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    for (NSString *key in [[self class] observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// apply change of user setting
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([[[self class] observedDefaultKeys] containsObject:keyPath]) {
        [self applyDefaultInvisiblesSetting];
        [self invalidateInvisiblesStyle];
        [self invalidateLayoutForCharacterRange:NSMakeRange(0, [[self textStorage] length]) actualCharacterRange:NULL];
    }
}


// ------------------------------------------------------
/// adjust rect of last empty line
- (void)setExtraLineFragmentRect:(NSRect)aRect usedRect:(NSRect)usedRect textContainer:(nonnull NSTextContainer *)aTextContainer
// ------------------------------------------------------
{
    // 複合フォントで行の高さがばらつくのを防止するために一般の行の高さを変更しているので、それにあわせる
    aRect.size.height = [self lineHeight];
    usedRect.size.height = [self lineHeight];

    [super setExtraLineFragmentRect:aRect usedRect:usedRect textContainer:aTextContainer];
}


// ------------------------------------------------------
/// draw invisible characters
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    [NSGraphicsContext saveGraphicsState];
    
    // set anti-alias state on screen drawing
    if ([NSGraphicsContext currentContextDrawingToScreen]) {
        [[NSGraphicsContext currentContext] setShouldAntialias:[self usesAntialias]];
    }
    
    // draw invisibles
    if ([self showsInvisibles] && [[self invisibleLines] count] > 0) {
        CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
        NSString *completeString = [[self textStorage] string];
        BOOL isVertical = ([[self firstTextView] layoutOrientation] == NSTextLayoutOrientationVertical);
        
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
            point.x += origin.x + glyphLocation.x;
            point.y += origin.y + [self defaultBaselineOffset];
            if (isVertical) {
                // [note] Probably not a good solution but better than not (2016-05-25).
                CGRect pathBounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
                point.y += CGRectGetHeight(pathBounds)/ 2;
            }
            
            // draw character
            CGContextSetTextPosition(context, point.x, point.y);
            CTLineDraw(line, context);
        }
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    
    [NSGraphicsContext restoreGraphicsState];
}


// ------------------------------------------------------
/// textStorage did update
- (void)textStorage:(nonnull NSTextStorage *)str edited:(NSTextStorageEditedOptions)editedMask range:(NSRange)newCharRange changeInLength:(NSInteger)delta invalidatedRange:(NSRange)invalidatedCharRange
// ------------------------------------------------------
{
    // invalidate wrapping line indent in editRange if needed
    if (editedMask & NSTextStorageEditedCharacters) {
        [self invalidateIndentInRange:newCharRange];
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
    //   -> [[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
    //      日本語フォント名を返してくることがあるため、使わない

    _textFont = textFont;
    
    // cache metric values to fix line height
    if (textFont) {
        [self setDefaultLineHeight:[self defaultLineHeightForFont:textFont]];
        [self setDefaultBaselineOffset:[self defaultBaselineOffsetForFont:textFont]];
    }
    
    // cache width of space char for hanging indent width calculation
    NSFont *screenFont = [textFont screenFont] ? : textFont;
    [self setSpaceWidth:[screenFont advancementForCharacter:' ']];
    
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

    return round([self defaultLineHeight] + lineSpacing * [[self textFont] pointSize]);
}


// ------------------------------------------------------
/// invalidate indent of wrapped lines
- (void)invalidateIndentInRange:(NSRange)range
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnablesHangingIndentKey]) { return; }
    
    NSTextStorage *textStorage = [self textStorage];
    NSRange lineRange = [[textStorage string] lineRangeForRange:range];
    
    if (lineRange.length == 0) { return; }
    
    CGFloat hangingIndent = [self spaceWidth] * [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultHangingIndentWidthKey];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[ \\t]+(?!$)" options:0 error:nil];
    
    // get dummy attributes to make calcuration of indent width the same as CElayoutManager's calcuration (2016-04)
    NSMutableDictionary *indentAttributes = [[[self firstTextView] typingAttributes] mutableCopy];
    NSMutableParagraphStyle *typingParagraphStyle = [indentAttributes[NSParagraphStyleAttributeName] mutableCopy];
    [typingParagraphStyle setHeadIndent:1.0];  // dummy indent value for size calcuration (2016-04)
    indentAttributes[NSParagraphStyleAttributeName] = [typingParagraphStyle copy];
    
    NSMutableDictionary<NSString *, NSNumber *> *cache = [NSMutableDictionary dictionary];
    
    // process line by line
    [textStorage beginEditing];
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
             if (cache[indentString]) {
                 indent += [cache[indentString] doubleValue];
             } else {
                 CGFloat width = ceil([indentString sizeWithAttributes:indentAttributes].width);
                 indent += width;
                 cache[indentString] = @(width);
             }
         }
         
         // apply new indent only if needed
         NSParagraphStyle *paragraphStyle = [textStorage attribute:NSParagraphStyleAttributeName
                                                           atIndex:substringRange.location
                                                    effectiveRange:NULL];
         if (indent != [paragraphStyle headIndent]) {
             NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
             [mutableParagraphStyle setHeadIndent:indent];
             
             [textStorage addAttribute:NSParagraphStyleAttributeName value:mutableParagraphStyle range:substringRange];
         }
     }];
    [textStorage endEditing];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// default keys to observe update
+ (nonnull NSArray<NSString *> *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultInvisibleSpaceKey,
             CEDefaultInvisibleTabKey,
             CEDefaultInvisibleNewLineKey,
             CEDefaultInvisibleFullwidthSpaceKey,
             
             CEDefaultShowInvisibleSpaceKey,
             CEDefaultShowInvisibleTabKey,
             CEDefaultShowInvisibleNewLineKey,
             CEDefaultShowInvisibleFullwidthSpaceKey,
             ];
}


// ------------------------------------------------------
/// apply invisible settings
- (void)applyDefaultInvisiblesSetting
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.invisibles = @[[CEInvisibles stringWithType:CEInvisibleSpace Index:[defaults integerForKey:CEDefaultInvisibleSpaceKey]],
                        [CEInvisibles stringWithType:CEInvisibleTab Index:[defaults integerForKey:CEDefaultInvisibleTabKey]],
                        [CEInvisibles stringWithType:CEInvisibleNewLine Index:[defaults integerForKey:CEDefaultInvisibleNewLineKey]],
                        [CEInvisibles stringWithType:CEInvisibleFullWidthSpace Index:[defaults integerForKey:CEDefaultInvisibleFullwidthSpaceKey]],
                        [CEInvisibles stringWithType:CEInvisibleVerticalTab Index:NULL],
                        [CEInvisibles stringWithType:CEInvisibleReplacement Index:NULL],
                        ];
    
    // （setShowsInvisibles: は CEEditorViewController から実行される。プリント時は CEPrintView から実行される）
    self.showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
    self.showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
    self.showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
    self.showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
    self.showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
}


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
