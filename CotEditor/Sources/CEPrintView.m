/*
 ==============================================================================
 CEPrintView
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-10-01 by nakamuxu
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

#import "CEPrintView.h"
#import "CELayoutManager.h"
#import "CESyntaxParser.h"
#import "constants.h"


@interface CEPrintView ()

@property (nonatomic) NSAttributedString *headerOneString;
@property (nonatomic) NSAttributedString *headerTwoString;
@property (nonatomic) NSAttributedString *footerOneString;
@property (nonatomic) NSAttributedString *footerTwoString;
@property (nonatomic) CEAlignmentType headerOneAlignment;
@property (nonatomic) CEAlignmentType headerTwoAlignment;
@property (nonatomic) CEAlignmentType footerOneAlignment;
@property (nonatomic) CEAlignmentType footerTwoAlignment;
@property (nonatomic) BOOL printsHeader;  // ヘッダ印刷の有無
@property (nonatomic) BOOL printsFooter;  // フッタ印刷の有無
@property (nonatomic) BOOL printsHeaderSeparator;
@property (nonatomic) BOOL printsFooterSeparator;
@property (nonatomic) BOOL printsLineNum;
@property (nonatomic, getter=isReadyToDrawPageNum) BOOL readyToDrawPageNum;
@property (nonatomic) CGFloat xOffset;
@property (nonatomic, copy) NSDictionary *headerFooterAttrs;
@property (nonatomic) CESyntaxParser *syntaxParser;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end




#pragma mark -

@implementation CEPrintView

#pragma mark NSTextView Methods

//=======================================================
// NSTextView method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // ヘッダ／フッタの文字属性辞書生成、保持
        CGFloat fontSize = (CGFloat)[defaults doubleForKey:CEDefaultHeaderFooterFontSizeKey];
        NSFont *headerFooterFont = [NSFont fontWithName:[defaults stringForKey:CEDefaultHeaderFooterFontNameKey] size:fontSize];
        if (!headerFooterFont) {
            headerFooterFont = [NSFont systemFontOfSize:fontSize];
        }
        _headerFooterAttrs = @{NSFontAttributeName: headerFooterFont,
                               NSForegroundColorAttributeName: [NSColor textColor]};
        
        // 日時のフォーマットを生成、保持
        NSString *dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultHeaderFooterDateFormatKey];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:dateFormat];
        
        // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
        [[self textContainer] setLineFragmentPadding:kPrintHFHorizontalMargin];
        
        // layoutManager を入れ替え
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [layoutManager setFixesLineHeight:NO];
        [layoutManager setPrinting:YES];
        [[self textContainer] replaceLayoutManager:layoutManager];
    }
    return self;
}


// ------------------------------------------------------
/// ページ分割を自前でやるかを返す
-(BOOL)knowsPageRange:(NSRangePointer)aRange
// ------------------------------------------------------
{
    // テキストビューのサイズをマージンに合わせて更新
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    [self setFrameSize:NSMakeSize([printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin],
                                  [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
    [self sizeToFit];
    
    return [super knowsPageRange:aRange];
}


// ------------------------------------------------------
/// ヘッダ／フッタの描画
- (void)drawPageBorderWithSize:(NSSize)borderSize
// ------------------------------------------------------
{
    NSRect currentFrame = [self frame]; // 現在のフレームを退避
    NSAttributedString *pageString = nil;
    NSPoint drawPoint = NSMakePoint(0.0, kPrintHFVerticalMargin);
    CGFloat headerFooterLineFontSize = [[self headerFooterAttrs][NSFontAttributeName] pointSize];

    // プリントパネルでのカスタム設定を読み取り、保持
    [self setupPrintWithBorderWidth:borderSize.width];
    
    // ページ番号の印字があるなら、準備する
    if ([self isReadyToDrawPageNum]) {
        NSInteger pageNum = [[NSPrintOperation currentOperation] currentPage];

        pageString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%zd", pageNum]
                                                     attributes:[self headerFooterAttrs]];
    }

    // フレームを設定
    [self setFrameSize:borderSize];

    // 描画開始
    // （このビューは isFlipped が YES なので drawAtPoint: は左上が原点となる）
    [self lockFocus];

    if ([self printsHeader]) {
        if ([self headerOneString]) {
            if ([[[self headerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderOneString:pageString];
            }
            drawPoint.x = [self xValueToDrawAttributedString:[self headerOneString]
                                                 borderWidth:borderSize.width alignment:[self headerOneAlignment]];
            [[self headerOneString] drawAtPoint:drawPoint];
            drawPoint.y += kHeaderFooterLineHeight;
        }
        
        if ([self headerTwoString]) {
            if ([[[self headerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderTwoString:pageString];
            }
            drawPoint.x = [self xValueToDrawAttributedString:[self headerTwoString]
                                                 borderWidth:borderSize.width alignment:[self headerTwoAlignment]];
            [[self headerTwoString] drawAtPoint:drawPoint];
            drawPoint.y += headerFooterLineFontSize;
            
        } else {
            if ([self headerOneString]) {
                drawPoint.y += headerFooterLineFontSize - kHeaderFooterLineHeight;
            }
        }
    }
    if ([self printsHeaderSeparator]) {
        drawPoint.y += kSeparatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(kPrintHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - kPrintHFHorizontalMargin, drawPoint.y)];
    }

    // （drawPoint.y を borderSize.height - kPrintHFVerticalMargin とすると1ページに満たない書類の印刷時に
    // セパレータが印字されないので、フッタ全体を下げる。 2006.02.18）
    drawPoint.y = borderSize.height - kPrintHFVerticalMargin + kSeparatorPadding;
    if ([self printsFooter]) {
        if ([self footerTwoString]) {
            if ([[[self footerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterTwoString:pageString];
            }
            drawPoint.y -= kHeaderFooterLineHeight;
            drawPoint.x = [self xValueToDrawAttributedString:[self footerTwoString]
                                                 borderWidth:borderSize.width alignment:[self footerTwoAlignment]];
            [[self footerTwoString] drawAtPoint:drawPoint];
        }
        
        if ([self footerOneString]) {
            if ([[[self footerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterOneString:pageString];
            }
            drawPoint.y -= kHeaderFooterLineHeight;
            drawPoint.x = [self xValueToDrawAttributedString:[self footerOneString]
                                                 borderWidth:borderSize.width alignment:[self footerOneAlignment]];
            [[self footerOneString] drawAtPoint:drawPoint];
        }
    }
    if ([self printsFooterSeparator]) {
        drawPoint.y -= kSeparatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(kPrintHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - kPrintHFHorizontalMargin, drawPoint.y)];
    }
    [self unlockFocus];

    // フレームをもとに戻す
    [self setFrame:currentFrame];
}


// ------------------------------------------------------
/// プリント
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];

    // 行番号を印字
    if ([self printsLineNum]) {
        // 行番号の文字属性辞書生成
        CGFloat masterFontSize = [[self font] pointSize];
        CGFloat fontSize = round(0.9 * masterFontSize);
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLineNumFontNameKey] size:fontSize] ? :
                       [NSFont userFixedPitchFontOfSize:fontSize];
        NSDictionary *attrs = @{NSFontAttributeName: font,
                                NSForegroundColorAttributeName: [NSColor textColor]};
        
        //文字幅を計算しておく 等幅扱い
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
        CGFloat charWidth = [@"8" sizeWithAttributes:attrs].width;
        
        // setup the variables we need for the loop
        NSString *string = [self string];
        NSLayoutManager *layoutManager = [self layoutManager]; // get owner's layout manager.
        
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
        
        // adjust values for line number drawing
        CGFloat xAdj = [self textContainerOrigin].x + kPrintHFHorizontalMargin - kLineNumPadding;
        CGFloat yAdj = (fontSize - masterFontSize);
        
        // counters
        NSUInteger lastLineNum = 0;
        NSUInteger lineNum = 1;
        NSUInteger glyphCount = 0;

        for (NSUInteger glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) { // count "REAL" lines
            NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                          actualCharacterRange:NULL]);
            while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
                NSRange range;
                NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
                if (NSPointInRect(numRect.origin, dirtyRect)) {
                    NSString *numStr = (lastLineNum != lineNum) ? [NSString stringWithFormat:@"%tu:", lineNum] : @"-:";
                    CGFloat requiredWidth = charWidth * [numStr length];
                    NSPoint point = NSMakePoint(dirtyRect.origin.x - requiredWidth + xAdj,
                                           numRect.origin.y + yAdj);
                    [numStr drawAtPoint:point withAttributes:attrs]; // draw the line number.
                    lastLineNum = lineNum;
                }
                glyphCount = NSMaxRange(range);
            }
        }
    }
}


// ------------------------------------------------------
/// Y軸を逆転させる
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
/// set printing font
- (void)setFont:(NSFont *)font
// ------------------------------------------------------
{
    // layoutManagerにもフォントを設定する
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    
    [super setFont:font];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 実際のドキュメントで不可視文字を表示しているかをセット
- (void)setDocumentShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    // layoutManagerにも設定する
    [(CELayoutManager *)[self layoutManager] setShowsOtherInvisibles:showsInvisibles];
    
    _documentShowsInvisibles = showsInvisibles;
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// プリント開始の準備
- (void)setupPrintWithBorderWidth:(CGFloat)borderWidth
// ------------------------------------------------------
{
    CEPrintPanelAccessoryController *accessoryController = [self printPanelAccessoryController];
    NSAttributedString *attrString = nil;
    CGFloat printWidth = borderWidth - kPrintHFHorizontalMargin * 2;

    // 行番号印字の有無をチェック
    switch ([accessoryController lineNumberMode]) {
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

    // 行番号表示の有無によってパディングを調整
    if ([self printsLineNum]) {
        [self setXOffset:kPrintTextHorizontalMargin];
    } else {
        [self setXOffset:0];
    }
    
    // 不可視文字の扱いを取得
    BOOL showsInvisibles;
    switch ([accessoryController invisibleCharsMode]) {
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
    if ([[accessoryController theme] isEqualToString:NSLocalizedStringFromTable(@"Black and White", CEPrintLocalizeTable,  nil)]) {
        [self setTextColor:[NSColor blackColor]];
        [self setBackgroundColor:[NSColor whiteColor]];
        
    } else {
        [self setTheme:[CETheme themeWithName:[accessoryController theme]]];
        [self setTextColor:[[self theme] textColor]];
        [self setBackgroundColor:[[self theme] backgroundColor]];
        
        // カラーリング実行オブジェクトを用意して実行
        if (![self syntaxParser]) {
            [self setSyntaxParser:[[CESyntaxParser alloc] initWithStyleName:[self syntaxName]
                                                              layoutManager:(CELayoutManager *)[[self textContainer] layoutManager]
                                                                 isPrinting:YES]];
        }
        [[self syntaxParser] colorAllString:[self string]];
    }
    
    // ヘッダを設定
    [self setPrintsHeader:[accessoryController printsHeader]];
    if ([self printsHeader]) {
        attrString = [self attributedStringFromPrintInfoType:[accessoryController headerOneInfoType]
                                                    maxWidth:printWidth];
        [self setHeaderOneString:attrString];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController headerTwoInfoType]
                                                    maxWidth:printWidth];
        [self setHeaderTwoString:attrString];
        [self setHeaderOneAlignment:[accessoryController headerOneAlignmentType]];
        [self setHeaderTwoAlignment:[accessoryController headerTwoAlignmentType]];
    }
    [self setPrintsHeaderSeparator:[accessoryController printsHeaderSeparator]];

    // フッタを設定
    [self setPrintsFooter:[accessoryController printsFooter]];
    if ([self printsFooter]) {
        attrString = [self attributedStringFromPrintInfoType:[accessoryController footerOneInfoType]
                                                    maxWidth:printWidth];
        [self setFooterOneString:attrString];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController footerTwoInfoType]
                                                    maxWidth:printWidth];
        [self setFooterTwoString:attrString];
        [self setFooterOneAlignment:[accessoryController footerOneAlignmentType]];
        [self setFooterTwoAlignment:[accessoryController footerTwoAlignmentType]];
    }
    [self setPrintsFooterSeparator:[accessoryController printsFooterSeparator]];
}


// ------------------------------------------------------
/// ヘッダ／フッタに印字する文字列を生成し、返す
- (NSAttributedString *)attributedStringFromPrintInfoType:(CEPrintInfoType)selectedTag maxWidth:(CGFloat)maxWidth
// ------------------------------------------------------
{
    NSString *string = @"";
    
    switch (selectedTag) {
        case CEDocumentNamePrintInfo:
            if ([self filePath]) {
                string = [self documentName];
            }
            break;
            
        case CESyntaxNamePrintInfo:
            string = [self syntaxName];
            break;
            
        case CEFilePathPrintInfo:
            if ([self filePath]) {
                string = [self filePath];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHeaderFooterPathAbbreviatingWithTildeKey]) {
                    string = [string stringByAbbreviatingWithTildeInPath];
                }
            } else {
                string = [self documentName];  // パスがない場合は書類名をプリント
            }
            break;
            
        case CEPrintDatePrintInfo:
            string = [NSString stringWithFormat:NSLocalizedString(@"Printed on %@", nil),
                      [[self dateFormatter] stringFromDate:[NSDate date]]];
            break;
            
        case CEPageNumberPrintInfo:
            string = @"PAGENUM";
            [self setReadyToDrawPageNum:YES];
            break;
            
        case CENoPrintInfo:
            return nil;
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string
                                                                           attributes:[self headerFooterAttrs]];
    
    // 印字があふれる場合、中ほどを省略する
    if (([attributedString size].width > maxWidth) && ([attributedString length] > 0)) {
        NSMutableAttributedString *attrStr = [attributedString mutableCopy];
        NSUInteger length = [attributedString length];
        CGFloat width = [attributedString size].width;
        CGFloat average = width / length;
        NSInteger deleteCount = (width - maxWidth) / average + 5; // 置き換える5文字の幅をみる
        NSRange replaceRange = NSMakeRange((NSUInteger)((length - deleteCount) / 2), deleteCount);
        
        [attrStr replaceCharactersInRange:replaceRange withString:@" ... "];
        
        attributedString = [attrStr copy];
    }

    return attributedString;
}


// ------------------------------------------------------
/// X軸方向の印字開始位置を返す
- (CGFloat)xValueToDrawAttributedString:(NSAttributedString *)attrString
                            borderWidth:(CGFloat)borderWidth
                              alignment:(CEAlignmentType)alignmentType
// ------------------------------------------------------
{
    switch (alignmentType) {
        case CEAlignLeft:
            return kPrintHFHorizontalMargin;
            break;
        case CEAlignCenter:
            return (borderWidth - [attrString size].width) / 2;
            break;
        case CEAlignRight:
            return (borderWidth - [attrString size].width) - kPrintHFHorizontalMargin;
            break;
    }
}

@end
