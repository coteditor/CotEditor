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
#import "CEPrintPanelAccessoryController.h"
#import "CELayoutManager.h"
#import "CESyntaxParser.h"
#import "NSString+Sandboxing.h"
#import "Constants.h"


// constants
CGFloat const kVerticalPrintMargin = 56.0;    // default 90.0
CGFloat const kHorizontalPrintMargin = 24.0;  // default 72.0

static CGFloat const kHorizontalHeaderFooterMargin = 20.0;
static CGFloat const kLineNumberPadding = 10.0;
static CGFloat const kHeaderFooterFontSize = 9.0;

static NSString *_Nonnull const PageNumberPlaceholder = @"PAGENUM";


@interface CEPrintView () <NSLayoutManagerDelegate>

@property (nonatomic, nullable, copy) NSString *primaryHeaderString;
@property (nonatomic, nullable, copy) NSString *secondaryHeaderString;
@property (nonatomic, nullable, copy) NSString *primaryFooterString;
@property (nonatomic, nullable, copy) NSString *secondaryFooterString;
@property (nonatomic) CEAlignmentType primaryHeaderAlignment;
@property (nonatomic) CEAlignmentType secondaryHeaderAlignment;
@property (nonatomic) CEAlignmentType primaryFooterAlignment;
@property (nonatomic) CEAlignmentType secondaryFooterAlignment;
@property (nonatomic) BOOL printsHeader;
@property (nonatomic) BOOL printsFooter;
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
        // prepare date formatter
        NSString *dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultHeaderFooterDateFormatKey];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:dateFormat];
        
        // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
        [[self textContainer] setLineFragmentPadding:kHorizontalHeaderFooterMargin];
        
        // replace layoutManager
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
        
        // calculate character width as mono-space font
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく (hetima)
        NSSize charSize = [@"8" sizeWithAttributes:attrs];
        
        // setup the variables we need for the loop
        NSString *string = [self string];
        NSLayoutManager *layoutManager = [self layoutManager];
        
        // adjust values for line number drawing
        CGFloat xAdj = [self textContainerOrigin].x + kHorizontalHeaderFooterMargin - kLineNumberPadding;
        CGFloat yAdj = (fontSize - masterFontSize);
        
        // vertical text
        BOOL isVertical = [self layoutOrientation] == NSTextLayoutOrientationVertical;
        CGContextRef context;
        if (isVertical) {
            // rotate axis
            context = [[NSGraphicsContext currentContext] CGContext];
            CGContextSaveGState(context);
            CGContextConcatCTM(context, CGAffineTransformMakeRotation(-M_PI_2));
        }
        
        // counters
        NSUInteger lastLineNumber = 0;
        NSUInteger lineNumber = 1;
        NSUInteger glyphCount = 0;
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
        
        for (NSUInteger glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNumber++) {  // count "REAL" lines
            NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                          actualCharacterRange:NULL]);
            while (glyphCount < glyphIndex) {  // handle "DRAWN" (wrapped) lines
                NSRange range;
                NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
                glyphCount = NSMaxRange(range);
                
                if (!NSPointInRect(numRect.origin, dirtyRect)) { continue; }
                
                NSString *numStr = (lastLineNumber != lineNumber) ? [NSString stringWithFormat:@"%tu", lineNumber] : @"-";
                NSPoint point = NSMakePoint(dirtyRect.origin.x + xAdj,
                                            numRect.origin.y + yAdj);
                
                // adjust position to draw
                if (isVertical) {
                    if (lastLineNumber == lineNumber) { continue; }
                    numStr = (lineNumber == 1 || lineNumber % 5 == 0) ? numStr : @"·";  // draw real number only in every 5 times
                    
                    point = CGPointMake(-point.y - (charSize.width * [numStr length] + charSize.height) / 2,
                                        point.x - charSize.height);
                } else {
                    point.x -= charSize.width * [numStr length];  // align right
                }
                
                // draw number
                [numStr drawAtPoint:point withAttributes:attrs];
                
                lastLineNumber = lineNumber;
            }
        }
        
        if (isVertical) {
            CGContextRestoreGState(context);
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
    
    return [self headerFooterWithPrimaryString:[self primaryHeaderString]
                              primaryAlignment:[self primaryHeaderAlignment]
                               secondaryString:[self secondaryHeaderString]
                            secondaryAlignment:[self secondaryHeaderAlignment]];
}


// ------------------------------------------------------
/// return page footer attributed string
- (nonnull NSAttributedString *)pageFooter
// ------------------------------------------------------
{
    [self setupPrint];
    
    if (![self printsFooter]) { return [[NSAttributedString alloc] init]; }
    
    return [self headerFooterWithPrimaryString:[self primaryFooterString]
                              primaryAlignment:[self primaryFooterAlignment]
                               secondaryString:[self secondaryFooterString]
                            secondaryAlignment:[self secondaryFooterAlignment]];
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
/// return whether do paganation by itself
-(BOOL)knowsPageRange:(NSRangePointer)aRange
// ------------------------------------------------------
{
    // update text view size considering text orientation
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    CGFloat scale = [printInfo scalingFactor];
    NSSize frameSize;
    if ([self layoutOrientation] == NSTextLayoutOrientationVertical) {
        frameSize = NSMakeSize([self maxSize].width,
                               ([printInfo paperSize].height - ([printInfo leftMargin] + [printInfo rightMargin])) / scale);
    } else {
        frameSize = NSMakeSize(([printInfo paperSize].width - ([printInfo leftMargin] + [printInfo rightMargin])) / scale,
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
/// set-accessor for invisibles setting on the real document
- (void)setDocumentShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    // set also to layoutManager
    [(CELayoutManager *)[self layoutManager] setShowsInvisibles:showsInvisibles];
    
    _documentShowsInvisibles = showsInvisibles;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// parse current print settings in printInfo
- (void)setupPrint
// ------------------------------------------------------
{
    NSDictionary *settings = [[[NSPrintOperation currentOperation] printInfo] dictionary];

    // check whether print line numbers
    switch ((CELineNumberPrintMode)[settings[CEPrintLineNumberKey] unsignedIntegerValue]) {
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
    
    // adjust paddings considering the line numbers
    if ([self printsLineNum]) {
        [self setXOffset:kHorizontalHeaderFooterMargin];
    } else {
        [self setXOffset:0];
    }
    
    // check wheter print invisibles
    BOOL showsInvisibles;
    switch ((CEInvisibleCharsPrintMode)[settings[CEPrintInvisiblesKey] unsignedIntegerValue]) {
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
    
    
    // setup syntax highlighting with set theme
    if ([settings[CEPrintThemeKey] isEqualToString:NSLocalizedString(@"Black and White",  nil)]) {
        [self setTextColor:[NSColor blackColor]];
        [self setBackgroundColor:[NSColor whiteColor]];
        
    } else {
        [self setTheme:[CETheme themeWithName:settings[CEPrintThemeKey]]];
        [self setTextColor:[[self theme] textColor]];
        [self setBackgroundColor:[[self theme] backgroundColor]];
        
        // perform coloring
        if (![self syntaxParser]) {
            [self setSyntaxParser:[[CESyntaxParser alloc] initWithStyleName:[self syntaxName]]];
        }
        [[self syntaxParser] colorWholeStringInTextStorage:[self textStorage]];
    }
    
    // setup header/footer
    [self setPrintsHeader:[settings[CEPrintHeaderKey] boolValue]];
    [self setPrimaryHeaderString:[self stringForPrintInfoType:[settings[CEPrimaryHeaderContentKey] unsignedIntegerValue]]];
    [self setPrimaryHeaderAlignment:[settings[CEPrimaryHeaderAlignmentKey] unsignedIntegerValue]];
    [self setSecondaryHeaderString:[self stringForPrintInfoType:[settings[CESecondaryHeaderContentKey] unsignedIntegerValue]]];
    [self setSecondaryHeaderAlignment:[settings[CESecondaryHeaderAlignmentKey] unsignedIntegerValue]];
    [self setPrintsFooter:[settings[CEPrintFooterKey] boolValue]];
    [self setPrimaryFooterString:[self stringForPrintInfoType:[settings[CEPrimaryFooterContentKey] unsignedIntegerValue]]];
    [self setPrimaryFooterAlignment:[settings[CEPrimaryFooterAlignmentKey] unsignedIntegerValue]];
    [self setSecondaryFooterString:[self stringForPrintInfoType:[settings[CESecondaryFooterContentKey] unsignedIntegerValue]]];
    [self setSecondaryFooterAlignment:[settings[CESecondaryFooterAlignmentKey] unsignedIntegerValue]];
}


// ------------------------------------------------------
/// return attributed string for header/footer
- (nonnull NSAttributedString *)headerFooterWithPrimaryString:(nullable NSString *)primaryString
                                             primaryAlignment:(CEAlignmentType)primaryAlignment
                                              secondaryString:(nullable NSString *)secondaryString
                                           secondaryAlignment:(CEAlignmentType)secondaryAlignment
// ------------------------------------------------------
{
    // apply current page number
    primaryString = [self applyCurrentPageNumberToString:primaryString];
    secondaryString = [self applyCurrentPageNumberToString:secondaryString];
    
    // case: empty
    if (!primaryString && !secondaryString) {
        return [[NSMutableAttributedString alloc] init];
    }
    
    // case: single content
    if (primaryString && !secondaryString) {
        return [[NSAttributedString alloc] initWithString:primaryString
                                               attributes:[self headerFooterAttributesForAlignment:primaryAlignment]];
    }
    if (!primaryString && secondaryString) {
        return [[NSAttributedString alloc] initWithString:secondaryString
                                               attributes:[self headerFooterAttributesForAlignment:secondaryAlignment]];
    }
    
    // case: double-sided
    if (primaryAlignment == CEAlignLeft && secondaryAlignment == CEAlignRight) {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\t\t%@", primaryString, secondaryString]
                                               attributes:[self headerFooterAttributesForAlignment:CEAlignLeft]];
    }
    if (primaryAlignment == CEAlignRight && secondaryAlignment == CEAlignLeft) {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\t\t%@", secondaryString, primaryString]
                                               attributes:[self headerFooterAttributesForAlignment:CEAlignLeft]];
    }
    
    // case: two lines
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    if (primaryString) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:primaryString
                                                                           attributes:[self headerFooterAttributesForAlignment:primaryAlignment]]];
    }
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    if (secondaryString) {
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:secondaryString
                                                                           attributes:[self headerFooterAttributesForAlignment:secondaryAlignment]]];
    }
    return [attrString copy];
}


// ------------------------------------------------------
/// return string for given header/footer contents applying page numbers
- (nonnull NSString *)applyCurrentPageNumberToString:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string isEqualToString:PageNumberPlaceholder]) {
        NSInteger pageNumber = [[NSPrintOperation currentOperation] currentPage];
        string = [NSString stringWithFormat:@"%zd", pageNumber];
    }
    
    return string;
}


// ------------------------------------------------------
/// return attributes for header/footer string
- (nonnull NSDictionary *)headerFooterAttributesForAlignment:(CEAlignmentType)alignmentType
// ------------------------------------------------------
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // alignment for two lines
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
    
    // tab stops for double-sided alignment (imitation of [super paperHeader])
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    CGFloat rightTabLocation = rightTabLocation = [printInfo paperSize].width - [printInfo topMargin] / 2;
    [paragraphStyle setTabStops:@[[[NSTextTab alloc] initWithType:NSCenterTabStopType location:rightTabLocation / 2],
                                  [[NSTextTab alloc] initWithType:NSRightTabStopType location:rightTabLocation]]];
    
    // line break mode to truncate middle
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    // font
    NSFont *font = [NSFont userFontOfSize:kHeaderFooterFontSize];
    
    return @{NSParagraphStyleAttributeName: paragraphStyle,
             NSFontAttributeName: font};
}


// ------------------------------------------------------
/// create string for header/footer
- (nullable NSString *)stringForPrintInfoType:(CEPrintInfoType)selectedTag
// ------------------------------------------------------
{
    switch (selectedTag) {
        case CEDocumentNamePrintInfo:
            return [self documentName];
            
        case CESyntaxNamePrintInfo:
            return [self syntaxName];
            
        case CEFilePathPrintInfo:
            if (![self filePath]) {  // print document name instead if document doesn't have file path yet
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
