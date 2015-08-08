/*
 
 CEPrintView.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-10-01.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEPrintView.h"
#import "CELayoutManager.h"
#import "CESyntaxParser.h"
#import "NSString+Sandboxing.h"
#import "Constants.h"


// constants
CGFloat const kVerticalPrintMargin = 58.0;    // default 90.0
CGFloat const kHorizontalPrintMargin = 24.0;  // default 72.0

static CGFloat const kHorizontalHeaderFooterMargin = 20.0;

static NSString *const PageNumberPlaceholder = @"PAGENUM";


@interface CEPrintView () <NSLayoutManagerDelegate>

@property (nonatomic, nullable, copy) NSString *headerOneString;
@property (nonatomic, nullable, copy) NSString *headerTwoString;
@property (nonatomic, nullable, copy) NSString *footerOneString;
@property (nonatomic, nullable, copy) NSString *footerTwoString;
@property (nonatomic) CEAlignmentType headerOneAlignment;
@property (nonatomic) CEAlignmentType headerTwoAlignment;
@property (nonatomic) CEAlignmentType footerOneAlignment;
@property (nonatomic) CEAlignmentType footerTwoAlignment;
@property (nonatomic) BOOL printsHeader;  // ヘッダ印刷の有無
@property (nonatomic) BOOL printsFooter;  // フッタ印刷の有無
@property (nonatomic) BOOL printsLineNum;
@property (nonatomic) CGFloat xOffset;
@property (nonatomic, nullable) CESyntaxParser *syntaxParser;
@property (nonatomic, nonnull) NSDateFormatter *dateFormatter;

@end




#pragma mark -

@implementation CEPrintView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // 日時のフォーマットを生成、保持
        NSString *dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultHeaderFooterDateFormatKey];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:dateFormat];
        
        // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
        [[self textContainer] setLineFragmentPadding:kHorizontalHeaderFooterMargin];
        
        // layoutManager を入れ替え
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [layoutManager setDelegate:self];
        [layoutManager setFixesLineHeight:NO];
        [layoutManager setPrinting:YES];
        [[self textContainer] replaceLayoutManager:layoutManager];
    }
    return self;
}


// ------------------------------------------------------
/// draw
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];

    // draw line numbers if needed
    if ([self printsLineNum]) {
        // prepare text attributes for line numbers
        CGFloat masterFontSize = [[self font] pointSize];
        CGFloat fontSize = round(0.9 * masterFontSize);
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLineNumFontNameKey] size:fontSize] ? :
                       [NSFont userFixedPitchFontOfSize:fontSize];
        NSDictionary *attrs = @{NSFontAttributeName: font,
                                NSForegroundColorAttributeName: [NSColor textColor]};
        
        //文字幅を計算しておく 等幅扱い
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく (hetima)
        CGFloat charWidth = [@"8" sizeWithAttributes:attrs].width;
        
        // setup the variables we need for the loop
        NSString *string = [self string];
        NSLayoutManager *layoutManager = [self layoutManager];
        
        // adjust values for line number drawing
        CGFloat xAdj = [self textContainerOrigin].x + kHorizontalHeaderFooterMargin - kLineNumPadding;
        CGFloat yAdj = (fontSize - masterFontSize);
        
        // counters
        NSUInteger lastLineNum = 0;
        NSUInteger lineNum = 1;
        NSUInteger glyphCount = 0;
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
        
        for (NSUInteger glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) {  // count "REAL" lines
            NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                          actualCharacterRange:NULL]);
            while (glyphCount < glyphIndex) {  // handle "DRAWN" (wrapped) lines
                NSRange range;
                NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
                if (NSPointInRect(numRect.origin, dirtyRect)) {
                    NSString *numStr = (lastLineNum != lineNum) ? [NSString stringWithFormat:@"%tu:", lineNum] : @"-:";
                    CGFloat requiredWidth = charWidth * [numStr length];
                    NSPoint point = NSMakePoint(dirtyRect.origin.x - requiredWidth + xAdj,
                                           numRect.origin.y + yAdj);
                    [numStr drawAtPoint:point withAttributes:attrs];  // draw the line number
                    lastLineNum = lineNum;
                }
                glyphCount = NSMaxRange(range);
            }
        }
    }
}


// ------------------------------------------------------
/// return page header attributed string
- (nonnull NSAttributedString *)pageHeader
// ------------------------------------------------------
{
    [self setupPrint];
    
    if (![self printsHeader]) { return [[NSAttributedString alloc] init]; }
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    
    if ([self headerOneString]) {
        [attrString appendAttributedString:[self attributedHeaderFooterStringWithString:[self headerOneString]
                                                                              alignment:[self headerOneAlignment]]];
    }
    if ([self headerOneString] && [self headerTwoString]) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    if ([self headerTwoString]) {
        [attrString appendAttributedString:[self attributedHeaderFooterStringWithString:[self headerTwoString]
                                                                              alignment:[self headerTwoAlignment]]];
    }
    
    return attrString;
}


// ------------------------------------------------------
/// return page footer attributed string
- (nonnull NSAttributedString *)pageFooter
// ------------------------------------------------------
{
    [self setupPrint];
    
    if (![self printsFooter]) { return [[NSAttributedString alloc] init]; }
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    
    if ([self footerOneString]) {
        [attrString appendAttributedString:[self attributedHeaderFooterStringWithString:[self footerOneString]
                                                                              alignment:[self footerOneAlignment]]];
    }
    if ([self footerOneString] && [self footerTwoString]) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    if ([self footerTwoString]) {
        [attrString appendAttributedString:[self attributedHeaderFooterStringWithString:[self footerTwoString]
                                                                              alignment:[self footerTwoAlignment]]];
    }
    
    return attrString;
}


// ------------------------------------------------------
/// flip Y axis
- (BOOL)isFlipped
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// the top/left point of text container.
- (NSPoint)textContainerOrigin
// ------------------------------------------------------
{
    return NSMakePoint([self xOffset], 0);
}


// ------------------------------------------------------
/// ページ分割を自前でやるかを返す
-(BOOL)knowsPageRange:(NSRangePointer)aRange
// ------------------------------------------------------
{
    // テキストビューのサイズをマージンに合わせて更新
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    CGFloat scale = [printInfo scalingFactor];
    NSSize frameSize;
    if ([self layoutOrientation] == NSTextLayoutOrientationVertical) {
        frameSize = NSMakeSize([self maxSize].width,
                               [printInfo paperSize].height - ([printInfo leftMargin] + [printInfo rightMargin]));
    } else {
        frameSize = NSMakeSize([printInfo paperSize].width - ([printInfo leftMargin] + [printInfo rightMargin]),
                               [self maxSize].height);
    }
    [self setFrameSize:frameSize];
    [self sizeToFit];
    
    return [super knowsPageRange:aRange];
}


// ------------------------------------------------------
/// set printing font
- (void)setFont:(nullable NSFont *)font
// ------------------------------------------------------
{
    // set tab width
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    NSUInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultTabWidthKey];
    CGFloat spaceWidth = [font advancementForGlyph:(NSGlyph)' '].width;
    
    [paragraphStyle setTabStops:@[]];
    [paragraphStyle setDefaultTabInterval:tabWidth * spaceWidth];
    [self setDefaultParagraphStyle:paragraphStyle];
    
    // apply to current string
    [[self textStorage] addAttribute:NSParagraphStyleAttributeName
                               value:paragraphStyle
                               range:NSMakeRange(0, [[self textStorage] length])];
    
    // set font also to layout manager
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    
    [super setFont:font];
}



#pragma mark LayoutManager Delegate

// ------------------------------------------------------
/// apply temporaly attributes for sytnax highlighting
- (nullable NSDictionary *)layoutManager:(nonnull NSLayoutManager *)layoutManager shouldUseTemporaryAttributes:(nonnull NSDictionary *)attrs forDrawingToScreen:(BOOL)toScreen atCharacterIndex:(NSUInteger)charIndex effectiveRange:(NSRangePointer)effectiveCharRange
// ------------------------------------------------------
{
    // apply syntax highlighting
    if ([attrs dictionaryWithValuesForKeys:@[NSForegroundColorAttributeName]]) {
        return attrs;
    } else {
        return nil;
    }
}



#pragma mark Public Accessors

// ------------------------------------------------------
/// 実際のドキュメントで不可視文字を表示しているかをセット
- (void)setDocumentShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    // layoutManagerにも設定する
    [(CELayoutManager *)[self layoutManager] setShowsInvisibles:showsInvisibles];
    
    _documentShowsInvisibles = showsInvisibles;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// プリント開始の準備
- (void)setupPrint
// ------------------------------------------------------
{
    NSDictionary *settings = [[[NSPrintOperation currentOperation] printInfo] printSettings];

    // 行番号印字の有無をチェック
    if ([self layoutOrientation] == NSTextLayoutOrientationVertical) { // do not draw line number on vertical mode anyway
        [self setPrintsLineNum:NO];
    } else {
        switch ((CELineNumberPrintMode)[settings[CEDefaultPrintLineNumIndexKey] unsignedIntegerValue]) {
            case CENoLinePrint:
                [self setPrintsLineNum:NO];
                break;
            case CESameAsDocumentLinePrint:
                [self setPrintsLineNum:[self documentShowsLineNum]];
                break;
            case CEDoLinePrint:
                [self setPrintsLineNum:YES];
                break;
        }
    }

    // 行番号表示の有無によってパディングを調整
    if ([self printsLineNum]) {
        [self setXOffset:kHorizontalHeaderFooterMargin];
    } else {
        [self setXOffset:0];
    }
    
    // 不可視文字の扱いを取得
    BOOL showsInvisibles;
    switch ((CEInvisibleCharsPrintMode)[settings[CEDefaultPrintInvisibleCharIndexKey] unsignedIntegerValue]) {
        case CENoInvisibleCharsPrint:
            showsInvisibles = NO;
            break;
        case CESameAsDocumentInvisibleCharsPrint:
            showsInvisibles = [self documentShowsInvisibles];
            break;
        case CEAllInvisibleCharsPrint:
            showsInvisibles = YES;
            break;
    }
    [(CELayoutManager *)[self layoutManager] setShowsInvisibles:showsInvisibles];
    
    
    // カラーリングの設定
    if ([settings[CEDefaultPrintThemeKey] isEqualToString:NSLocalizedString(@"Black and White",  nil)]) {
        [self setTextColor:[NSColor blackColor]];
        [self setBackgroundColor:[NSColor whiteColor]];
        
    } else {
        [self setTheme:[CETheme themeWithName:settings[CEDefaultPrintThemeKey]]];
        [self setTextColor:[[self theme] textColor]];
        [self setBackgroundColor:[[self theme] backgroundColor]];
        
        // カラーリング実行オブジェクトを用意して実行
        if (![self syntaxParser]) {
            [self setSyntaxParser:[[CESyntaxParser alloc] initWithStyleName:[self syntaxName]]];
        }
        [[self syntaxParser] colorWholeStringInTextStorage:[self textStorage]];
    }
    
    // ヘッダ・フッタを設定
    [self setPrintsHeader:[settings[CEDefaultPrintHeaderKey] boolValue]];
    [self setHeaderOneString:[self stringForPrintInfoType:[settings[CEDefaultHeaderOneStringIndexKey] unsignedIntegerValue]]];
    [self setHeaderOneAlignment:[settings[CEDefaultHeaderOneAlignIndexKey] unsignedIntegerValue]];
    [self setHeaderTwoString:[self stringForPrintInfoType:[settings[CEDefaultHeaderTwoStringIndexKey] unsignedIntegerValue]]];
    [self setHeaderTwoAlignment:[settings[CEDefaultHeaderTwoAlignIndexKey] unsignedIntegerValue]];
    [self setPrintsFooter:[settings[CEDefaultPrintFooterKey] boolValue]];
    [self setFooterOneString:[self stringForPrintInfoType:[settings[CEDefaultFooterOneStringIndexKey] unsignedIntegerValue]]];
    [self setFooterOneAlignment:[settings[CEDefaultFooterOneAlignIndexKey] unsignedIntegerValue]];
    [self setFooterTwoString:[self stringForPrintInfoType:[settings[CEDefaultFooterTwoStringIndexKey] unsignedIntegerValue]]];
    [self setFooterTwoAlignment:[settings[CEDefaultFooterTwoAlignIndexKey] unsignedIntegerValue]];
}


// ------------------------------------------------------
/// return attributed string for given header/footer contents applying page numbers
- (NSAttributedString *)attributedHeaderFooterStringWithString:(nonnull NSString *)string alignment:(CEAlignmentType)alignment
// ------------------------------------------------------
{
    if ([string isEqualToString:PageNumberPlaceholder]) {
        NSInteger pageNumber = [[NSPrintOperation currentOperation] currentPage];
        string = [NSString stringWithFormat:@"%zd", pageNumber];
    }
    return [[NSAttributedString alloc] initWithString:string
                                           attributes:[self headerFooterAttributesForAlignment:alignment]];
}


// ------------------------------------------------------
/// return attributes for header/footer string
- (nonnull NSDictionary *)headerFooterAttributesForAlignment:(CEAlignmentType)alignmentType
// ------------------------------------------------------
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    // alignment
    NSTextAlignment alignment;
    switch (alignmentType) {
        case CEAlignLeft:
            alignment = NSLeftTextAlignment;
            break;
        case CEAlignCenter:
            alignment = NSCenterTextAlignment;
            break;
        case CEAlignRight:
            alignment = NSRightTextAlignment;
            break;
    }
    [paragraphStyle setAlignment:alignment];
    
    return @{NSParagraphStyleAttributeName: paragraphStyle};
}


// ------------------------------------------------------
/// ヘッダ／フッタに印字する文字列を生成し、返す
- (nullable NSString *)stringForPrintInfoType:(CEPrintInfoType)selectedTag
// ------------------------------------------------------
{
    switch (selectedTag) {
        case CEDocumentNamePrintInfo:
            return [self documentName];
            
        case CESyntaxNamePrintInfo:
            return [self syntaxName];
            
        case CEFilePathPrintInfo:
            if (![self filePath]) {  // パスがない場合は書類名をプリント
                return [self documentName];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHeaderFooterPathAbbreviatingWithTildeKey]) {
                return [[self filePath]  stringByAbbreviatingWithTildeInSandboxedPath];
            } else {
                return [self filePath];
            }
            
        case CEPrintDatePrintInfo:
            return [NSString stringWithFormat:NSLocalizedString(@"Printed on %@", nil),
                    [[self dateFormatter] stringFromDate:[NSDate date]]];
            
        case CEPageNumberPrintInfo:
            return PageNumberPlaceholder;
            
        case CENoPrintInfo:
            return nil;
    }
    
    return nil;
}

@end
