/*
 
 CEPrintView.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-10-01.

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

#import "CEPrintView.h"

#import "CotEditor-Swift.h"

#import "CEPrintPanelAccessoryController.h"
#import "CESyntaxManager.h"
#import "CESyntaxStyle.h"
#import "CEDefaults.h"

#import "NSString+Sandboxing.h"
#import "NSString+CECounting.h"
#import "NSFont+CESize.h"


// constants
CGFloat const kVerticalPrintMargin = 56.0;    // default 90.0
CGFloat const kHorizontalPrintMargin = 24.0;  // default 72.0

static CGFloat const kLineFragmentPadding = 20.0;
static CGFloat const kLineNumberPadding = 10.0;
static CGFloat const kHeaderFooterFontSize = 9.0;

static NSString * _Nonnull const kLineNumberFontName = @"AvenirNextCondensed-Regular";

static NSString *_Nonnull const PageNumberPlaceholder = @"PAGENUM";


@interface CEPrintView () <NSLayoutManagerDelegate>

@property (nonatomic) CGFloat lineHeight;
@property (nonatomic) BOOL printsLineNumber;
@property (nonatomic) CGFloat xOffset;
@property (nonatomic, nullable) CESyntaxStyle *syntaxStyle;
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
        
        _lineHeight = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultLineHeightKey];
        
        // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
        [[self textContainer] setLineFragmentPadding:kLineFragmentPadding];
        
        // replace layoutManager
        LayoutManager *layoutManager = [[LayoutManager alloc] init];
        [layoutManager setDelegate:self];
        [layoutManager setUsesScreenFonts:NO];
        [[self textContainer] replaceLayoutManager:layoutManager];
    }
    return self;
}


// ------------------------------------------------------
/// job title
- (nonnull NSString *)printJobTitle
// ------------------------------------------------------
{
    return [self documentName] ?: [super printJobTitle];
}


// ------------------------------------------------------
/// draw
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [self loadPrintSettings];
    
    // store graphics state to keep line number area drawable
    //   -> Otherwise, line numbers can be cropped. (2016-03 by 1024jp)
    [NSGraphicsContext saveGraphicsState];
    
    [super drawRect:dirtyRect];
    
    [NSGraphicsContext restoreGraphicsState];
    
    // draw line numbers if needed
    if ([self printsLineNumber]) {
        // prepare text attributes for line numbers
        CGFloat fontSize = round(0.9 * [[self font] pointSize]);
        NSFont *font = [NSFont fontWithName:kLineNumberFontName size:fontSize] ? : [NSFont userFixedPitchFontOfSize:fontSize];
        NSDictionary<NSString *, id> *attrs = @{NSFontAttributeName: font,
                                                NSForegroundColorAttributeName: [self textColor]};
        
        // calculate character width by treating the font as a mono-space font
        NSSize charSize = [@"8" sizeWithAttributes:attrs];
        
        // setup the variables we need for the loop
        NSString *string = [self string];
        NSLayoutManager *layoutManager = [self layoutManager];
        
        // adjust values for line number drawing
        CGFloat horizontalOrigin = [self textContainerOrigin].x + kLineFragmentPadding - kLineNumberPadding;
        
        // vertical text
        BOOL isVerticalText = [self layoutOrientation] == NSTextLayoutOrientationVertical;
        if (isVerticalText) {
            // rotate axis
            [NSGraphicsContext saveGraphicsState];
            CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
            CGContextConcatCTM(context, CGAffineTransformMakeRotation(-M_PI_2));
        }
        
        // get glyph range of which line number should be drawn
        NSRange glyphRangeToDraw = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:dirtyRect
                                                                                   inTextContainer:[self textContainer]];
        
        // counters
        NSUInteger glyphCount = glyphRangeToDraw.location;
        NSUInteger lineNumber = 1;
        NSUInteger lastLineNumber = 0;
        
        // count lines until visible
        lineNumber = [string numberOfLinesInRange:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:glyphRangeToDraw.location])
                             includingLastNewLine:YES] ?: 1;  // start with 1
        
        for (NSUInteger glyphIndex = glyphRangeToDraw.location; glyphIndex < NSMaxRange(glyphRangeToDraw); lineNumber++) {  // count "real" lines
            NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            NSRange lineRange = [string lineRangeForRange:NSMakeRange(charIndex, 0)];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL]);
            
            while (glyphCount < glyphIndex) {  // handle wrapped lines
                NSRange range;
                NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
                BOOL isWrappedLine = (lastLineNumber == lineNumber);
                lastLineNumber = lineNumber;
                glyphCount = NSMaxRange(range);
                
                if (isVerticalText && isWrappedLine) { continue; }
                
                NSString *numStr = isWrappedLine ? @"-" : [NSString stringWithFormat:@"%tu", lineNumber];
                
                // adjust position to draw
                NSPoint point = NSMakePoint(horizontalOrigin, NSMaxY(lineRect) - charSize.height);
                if (isVerticalText) {
                    numStr = (lineNumber == 1 || lineNumber % 5 == 0) ? numStr : @"·";  // draw real number only in every 5 times
                    
                    point = NSMakePoint(-point.y - (charSize.width * [numStr length] + charSize.height) / 2,
                                        point.x - charSize.height);
                } else {
                    point.x -= charSize.width * [numStr length];  // align right
                }
                
                // draw number
                [numStr drawAtPoint:point withAttributes:attrs];
            }
        }
        
        if (isVerticalText) {
            [NSGraphicsContext restoreGraphicsState];
        }
    }
}


// ------------------------------------------------------
/// return page header attributed string
- (nonnull NSAttributedString *)pageHeader
// ------------------------------------------------------
{
    NSDictionary *settings = [[[NSPrintOperation currentOperation] printInfo] dictionary];
    
    if (![settings[CEPrintHeaderKey] boolValue]) { return [[NSAttributedString alloc] init]; }
    
    CEPrintInfoType primaryInfoType = [settings[CEPrimaryHeaderContentKey] unsignedIntegerValue];
    CEAlignmentType primaryAlignment = [settings[CEPrimaryHeaderAlignmentKey] unsignedIntegerValue];
    CEPrintInfoType secondaryInfoType = [settings[CESecondaryHeaderContentKey] unsignedIntegerValue];
    CEAlignmentType secondaryAlignment = [settings[CESecondaryHeaderAlignmentKey] unsignedIntegerValue];
    
    return [self headerFooterWithPrimaryString:[self stringForPrintInfoType:primaryInfoType]
                              primaryAlignment:primaryAlignment
                               secondaryString:[self stringForPrintInfoType:secondaryInfoType]
                            secondaryAlignment:secondaryAlignment];
}


// ------------------------------------------------------
/// return page footer attributed string
- (nonnull NSAttributedString *)pageFooter
// ------------------------------------------------------
{
    NSDictionary *settings = [[[NSPrintOperation currentOperation] printInfo] dictionary];
    
    if (![settings[CEPrintFooterKey] boolValue]) { return [[NSAttributedString alloc] init]; }
    
    CEPrintInfoType primaryInfoType = [settings[CEPrimaryFooterContentKey] unsignedIntegerValue];
    CEAlignmentType primaryAlignment = [settings[CEPrimaryFooterAlignmentKey] unsignedIntegerValue];
    CEPrintInfoType secondaryInfoType = [settings[CESecondaryFooterContentKey] unsignedIntegerValue];
    CEAlignmentType secondaryAlignment = [settings[CESecondaryFooterAlignmentKey] unsignedIntegerValue];
    
    return [self headerFooterWithPrimaryString:[self stringForPrintInfoType:primaryInfoType]
                              primaryAlignment:primaryAlignment
                               secondaryString:[self stringForPrintInfoType:secondaryInfoType]
                            secondaryAlignment:secondaryAlignment];
}


// ------------------------------------------------------
/// flip Y axis
- (BOOL)isFlipped
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// view's opacity
- (BOOL)isOpaque
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
-(BOOL)knowsPageRange:(NSRangePointer)range
// ------------------------------------------------------
{
    [self setupPrintSize];
    
    return [super knowsPageRange:range];
}


// ------------------------------------------------------
/// set printing font
- (void)setFont:(nullable NSFont *)font
// ------------------------------------------------------
{
    // set tab width
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    NSUInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultTabWidthKey];
    
    [paragraphStyle setTabStops:@[]];
    [paragraphStyle setDefaultTabInterval:tabWidth * [font advancementForCharacter:' ']];
    [paragraphStyle setLineHeightMultiple:[self lineHeight]];
    [self setDefaultParagraphStyle:paragraphStyle];
    
    // apply to current string
    [[self textStorage] addAttribute:NSParagraphStyleAttributeName
                               value:paragraphStyle
                               range:NSMakeRange(0, [[self textStorage] length])];
    
    // set font also to layout manager
    [(LayoutManager *)[self layoutManager] setTextFont:font];
    
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
    }
    
    return nil;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// parse current print settings in printInfo
- (void)loadPrintSettings
// ------------------------------------------------------
{
    NSDictionary *settings = [[[NSPrintOperation currentOperation] printInfo] dictionary];

    // check whether print line numbers
    switch ((CELineNumberPrintMode)[settings[CEPrintLineNumberKey] unsignedIntegerValue]) {
        case CELinePrintNo:
            [self setPrintsLineNumber:NO];
            break;
        case CELinePrintSameAsDocument:
            [self setPrintsLineNumber:[self documentShowsLineNumber]];
            break;
        case CELinePrintYes:
            [self setPrintsLineNumber:YES];
            break;
    }
    
    // adjust paddings considering the line numbers
    if ([self printsLineNumber]) {
        [self setXOffset:kLineFragmentPadding];
    } else {
        [self setXOffset:0];
    }
    
    // check whether print invisibles
    BOOL showsInvisibles;
    switch ((CEInvisibleCharsPrintMode)[settings[CEPrintInvisiblesKey] unsignedIntegerValue]) {
        case CEInvisibleCharsPrintNo:
            showsInvisibles = NO;
            break;
        case CEInvisibleCharsPrintSameAsDocument:
            showsInvisibles = [self documentShowsInvisibles];
            break;
        case CEInvisibleCharsPrintAll:
            showsInvisibles = YES;
            break;
    }
    [(LayoutManager *)[self layoutManager] setShowsInvisibles:showsInvisibles];
    
    // setup syntax highlighting with theme
    if ([settings[CEPrintThemeKey] isEqualToString:NSLocalizedString(@"Black and White",  nil)]) {
        [[self layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName
                                     forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
        [self setTextColor:[NSColor blackColor]];
        [self setBackgroundColor:[NSColor whiteColor]];
        [(LayoutManager *)[self layoutManager] setInvisiblesColor:[NSColor grayColor]];
        
    } else {
        [self setTheme:[[ThemeManager shared] themeWithName:settings[CEPrintThemeKey]]];
        [self setTextColor:[[self theme] textColor]];
        [self setBackgroundColor:[[self theme] backgroundColor]];
        [(LayoutManager *)[self layoutManager] setInvisiblesColor:[[self theme] invisiblesColor]];
        
        // perform coloring
        if (![self syntaxStyle]) {
            [self setSyntaxStyle:[[CESyntaxManager sharedManager] styleWithName:[self syntaxName]]];
            [[self syntaxStyle] setTextStorage:[self textStorage]];
        }
        CEPrintPanelAccessoryController *controller = [[[[NSPrintOperation currentOperation] printPanel] accessoryControllers] firstObject];
        [[self syntaxStyle] highlightWholeStringWithCompletionHandler:^ {
            if (![[controller view] isHidden]) {
                [controller setNeedsPreview:YES];
            }
        }];
    }
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
- (nonnull NSDictionary<NSString *, id> *)headerFooterAttributesForAlignment:(CEAlignmentType)alignmentType
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
    
    // tab stops for double-sided alignment (imitation of [super pageHeader])
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
        case CEPrintInfoDocumentName:
            return [self documentName];
            
        case CEPrintInfoSyntaxName:
            return [self syntaxName];
            
        case CEPrintInfoFilePath:
            if (![self filePath]) {  // print document name instead if document doesn't have file path yet
                return [self documentName];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHeaderFooterPathAbbreviatingWithTildeKey]) {
                return [[self filePath] stringByAbbreviatingWithTildeInSandboxedPath];
            } else {
                return [self filePath];
            }
            
        case CEPrintInfoPrintDate:
            return [NSString stringWithFormat:NSLocalizedString(@"Printed on %@", nil),
                    [[self dateFormatter] stringFromDate:[NSDate date]]];
            
        case CEPrintInfoPageNumber:
            return PageNumberPlaceholder;
            
        case CEPrintInfoNone:
            return nil;
    }
    
    return nil;
}


// ------------------------------------------------------
/// update text view size considering text orientation
- (void)setupPrintSize
// ------------------------------------------------------
{
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    
    NSSize frameSize = [printInfo paperSize];
    if ([self layoutOrientation] == NSTextLayoutOrientationVertical) {
        frameSize.height -= [printInfo leftMargin] + [printInfo rightMargin];
        frameSize.height /= [printInfo scalingFactor];
    } else {
        frameSize.width -= [printInfo leftMargin] + [printInfo rightMargin];
        frameSize.width /= [printInfo scalingFactor];
    }
    
    [self setFrameSize:frameSize];
    [self sizeToFit];
}

@end
