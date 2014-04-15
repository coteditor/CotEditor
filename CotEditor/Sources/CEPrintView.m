/*
=================================================
CEPrintView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.10.01
 
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

#import "CEPrintView.h"
#import "CELayoutManager.h"
#import "CESyntax.h"
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
@property (nonatomic) BOOL readyToPrint;  // =ヘッダ／フッタ生成処理などの準備完了フラグ
@property (nonatomic) BOOL printsLineNum;
@property (nonatomic) BOOL readyToDrawPageNum;
@property (nonatomic) CGFloat xOffset;
@property (nonatomic) NSDictionary *headerFooterAttrs;
@property (nonatomic) NSDictionary *lineNumAttrs;

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
        // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
        [[self textContainer] setLineFragmentPadding:k_printHFHorizontalMargin];
        
        // layoutManager を入れ替え
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [layoutManager setFixLineHeight:NO];
        [layoutManager setIsPrinting:YES];
        [[self textContainer] replaceLayoutManager:layoutManager];
    }
    return self;
}

// ------------------------------------------------------
/// ヘッダ／フッタの描画
- (void)drawPageBorderWithSize:(NSSize)borderSize
// ------------------------------------------------------
{
    NSRect currentFrame = [self frame]; // 現在のフレームを退避
    NSAttributedString *pageString = nil;
    NSPoint drawPoint = NSMakePoint(0.0, k_printHFVerticalMargin);
    CGFloat headerFooterLineFontSize = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_headerFooterFontSize];

    // プリントパネルでのカスタム設定を読み取り、保持
    [self setupPrintWithBorderWidth:borderSize.width];
    
    // ページ番号の印字があるなら、準備する
    if ([self readyToDrawPageNum]) {
        NSInteger pageNum = [[NSPrintOperation currentOperation] currentPage];

        pageString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%li", (long)pageNum]
                                                     attributes:[self headerFooterAttrs]];
    }

    // フレームを設定
    [self setFrame:NSMakeRect(0, 0, borderSize.width, borderSize.height)];

    // 描画開始
    // （このビューは isFlipped が YES なので drawAtPoint: は左上が原点となる）
    [self lockFocus];

    if ([self printsHeader]) {
        if ([self headerOneString]) {
            if ([[[self headerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderOneString:pageString];
            }
            drawPoint.x = [self xValueToDrawOfAttributedString:[self headerOneString]
                                                   borderWidth:borderSize.width alignment:[self headerOneAlignment]];
            [[self headerOneString] drawAtPoint:drawPoint];
            drawPoint.y += k_headerFooterLineHeight;
        }
        
        if ([self headerTwoString]) {
            if ([[[self headerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setHeaderTwoString:pageString];
            }
            drawPoint.x = [self xValueToDrawOfAttributedString:[self headerTwoString]
                                                   borderWidth:borderSize.width alignment:[self headerTwoAlignment]];
            [[self headerTwoString] drawAtPoint:drawPoint];
            drawPoint.y += headerFooterLineFontSize;
            
        } else {
            if ([self headerOneString]) {
                drawPoint.y += headerFooterLineFontSize - k_headerFooterLineHeight;
            }
        }
    }
    if ([self printsHeaderSeparator]) {
        drawPoint.y += k_separatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - k_printHFHorizontalMargin, drawPoint.y)];
    }

    // （drawPoint.y を borderSize.height - k_printHFVerticalMargin とすると1ページに満たない書類の印刷時に
    // セパレータが印字されないので、フッタ全体を下げる。 2006.02.18）
    drawPoint.y = borderSize.height - k_printHFVerticalMargin + k_separatorPadding;
    if ([self printsFooter]) {
        if ([self footerTwoString]) {
            if ([[[self footerTwoString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterTwoString:pageString];
            }
            drawPoint.y -= k_headerFooterLineHeight;
            drawPoint.x = [self xValueToDrawOfAttributedString:[self footerTwoString]
                                                   borderWidth:borderSize.width alignment:[self footerTwoAlignment]];
            [[self footerTwoString] drawAtPoint:drawPoint];
        }
        
        if ([self footerOneString]) {
            if ([[[self footerOneString] string] isEqualToString:@"PAGENUM"]) {
                [self setFooterOneString:pageString];
            }
            drawPoint.y -= k_headerFooterLineHeight;
            drawPoint.x = [self xValueToDrawOfAttributedString:[self footerOneString]
                                                   borderWidth:borderSize.width alignment:[self footerOneAlignment]];
            [[self footerOneString] drawAtPoint:drawPoint];
        }
    }
    if ([self printsFooterSeparator]) {
        drawPoint.y -= k_separatorPadding / 2;
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, drawPoint.y)
                                  toPoint:NSMakePoint(borderSize.width - k_printHFHorizontalMargin, drawPoint.y)];
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
        CGFloat lineNumFontSize = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_lineNumFontSize];

        //文字幅を計算しておく 等幅扱い
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
        CGFloat charWidth = [@"8" sizeWithAttributes:[self lineNumAttrs]].width;

        // setup the variables we need for the loop
        NSRange range;       // a range for counting lines
        NSString *str = [self string];
        NSString *numStr;    // a temporary string for Line Number
        NSUInteger glyphIndex, theBefore, glyphCount; // glyph counter
        NSUInteger charIndex;
        NSUInteger lineNum;   // line counter
        CGFloat reqWidth;    // width calculator holder -- width needed to show string
        CGFloat xAdj = 0.0;    // adjust horizontal value for line number drawing
        CGFloat yAdj = 0.0;    // adjust vertical value for line number drawing
        NSRect numRect;      // rectange holder
        NSPoint numPoint;    // point holder
        NSLayoutManager *layoutManager = [self layoutManager]; // get _owner's layout manager.
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];

        theBefore = 0;
        lineNum = 1;
        glyphCount = 0;
        xAdj = [self textContainerOrigin].x + k_printHFHorizontalMargin - k_lineNumPadding;
        yAdj = ([[self font] pointSize] - lineNumFontSize) / 2;

        for (glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) { // count "REAL" lines
            charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[str lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                          actualCharacterRange:NULL]);
            while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
                numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
                if (NSPointInRect(numRect.origin, dirtyRect)) {
                    if (theBefore != lineNum) {
                        numStr = [NSString stringWithFormat:@"%ld:", (long)lineNum];
                        reqWidth = charWidth * [numStr length];
                    } else {
                        numStr = @"-:";
                        reqWidth = 8.0; // @"-:"のときに必要なピクセル値。変更時、注意。*****
                    }
                    numPoint = NSMakePoint(dirtyRect.origin.x - reqWidth + xAdj,
                                           numRect.origin.y + yAdj);
                    [numStr drawAtPoint:numPoint withAttributes:[self lineNumAttrs]]; // draw the line number.
                    theBefore = lineNum;
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
    [(CELayoutManager *)[self layoutManager] setShowOtherInvisibles:showsInvisibles];
    _documentShowsInvisibles = showsInvisibles;
}


// ------------------------------------------------------
/// 不可視文字の色を返す（CELayoutManager向け: テーマ機能を実装したら取り外せる予定）
- (NSColor *)invisiblesColor
// ------------------------------------------------------
{
    return [NSUnarchiver unarchiveObjectWithData:
            [[NSUserDefaults standardUserDefaults] dataForKey:k_key_invisibleCharactersColor]];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSAttributedString *attrString = nil;
    CGFloat printWidth = borderWidth - k_printHFHorizontalMargin * 2;

    // ヘッダ／フッタの文字属性辞書生成、保持
    NSFont *headerFooterFont = [NSFont fontWithName:[defaults stringForKey:k_key_headerFooterFontName]
                                               size:(CGFloat)[defaults doubleForKey:k_key_headerFooterFontSize]];
    [self setHeaderFooterAttrs:@{NSFontAttributeName: headerFooterFont,
                                 NSForegroundColorAttributeName: [NSColor textColor]}];

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

    // 行番号を印字するときは文字属性を保持、パディングを調整
    if ([self printsLineNum]) {
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:k_key_lineNumFontName]
                                       size:(CGFloat)[defaults doubleForKey:k_key_lineNumFontSize]];
        [self setLineNumAttrs:@{NSFontAttributeName:font,
                                NSForegroundColorAttributeName:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_lineNumFontColor]]}];
        [self setXOffset:k_printTextHorizontalMargin];
    }
    
    // 制御文字印字を取得
    BOOL showsControls;
    switch ([accessoryController invisibleCharsMode]) {
        case CENoInvisibleCharsPrint:
            showsControls = NO;
            break;
        case CESameAsDocumentInvisibleCharsPrint:
            showsControls = [self documentShowsInvisibles];
            break;
        case CEAllInvisibleCharsPrint:
            showsControls = YES;
            break;
    }
    [[[self textContainer] layoutManager] setShowsControlCharacters:showsControls];
    
    
    // カラーリングの設定
    switch ([accessoryController colorMode]) {
        case CEBlackColorPrint:
            [self setTextColor:[NSColor blackColor]];
            [self setBackgroundColor:[NSColor whiteColor]];
            break;
            
        case CESameAsDocumentColorPrint:
            [self setTextColor:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_textColor]]];
            [self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_backgroundColor]]];
            
            // カラーリング実行オブジェクトを用意して実行
            CESyntax *syntax = [[CESyntax alloc] init];
            [syntax setSyntaxStyleName:[self syntaxName]];
            [syntax setLayoutManager:(CELayoutManager *)[[self textContainer] layoutManager]];
            [syntax setIsPrinting:YES];
            [syntax colorAllString:[self string]];
            break;
    }
    
    // ヘッダを設定
    if ([accessoryController printsHeader]) {
        [self setPrintsHeader:YES];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController headerOneInfoType]
                                                    maxWidth:printWidth];
        [self setHeaderOneString:attrString];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController headerTwoInfoType]
                                                    maxWidth:printWidth];
        [self setHeaderTwoString:attrString];
        [self setHeaderOneAlignment:[accessoryController headerOneAlignmentType]];
        [self setHeaderTwoAlignment:[accessoryController headerTwoAlignmentType]];
    } else {
        [self setPrintsHeader:NO];
    }
    [self setPrintsHeaderSeparator:[accessoryController printsHeaderSeparator]];

    // フッタを設定
    if ([accessoryController printsFooter]) {
        [self setPrintsFooter:YES];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController footerOneInfoType]
                                                    maxWidth:printWidth];
        [self setFooterOneString:attrString];
        attrString = [self attributedStringFromPrintInfoType:[accessoryController footerTwoInfoType]
                                                    maxWidth:printWidth];
        [self setFooterTwoString:attrString];
        [self setFooterOneAlignment:[accessoryController footerOneAlignmentType]];
        [self setFooterTwoAlignment:[accessoryController footerTwoAlignmentType]];
    } else {
        [self setPrintsFooter:NO];
    }
    [self setPrintsFooterSeparator:[accessoryController printsFooterSeparator]];
    [self setReadyToPrint:YES];
}


// ------------------------------------------------------
/// ヘッダ／フッタに印字する文字列をポップアップメニューインデックスから生成し、返す
- (NSAttributedString *)attributedStringFromPrintInfoType:(CEPrintInfoType)selectedTag maxWidth:(CGFloat)maxWidth
// ------------------------------------------------------
{
    NSAttributedString *outString = nil;
    NSString *dateString;
    NSString *filePath = [self filePath];
            
    switch (selectedTag) {
        case CEDocumentNamePrintInfo:
            if ([self filePath]) {
                outString = [[NSAttributedString alloc] initWithString:[self documentName]
                                                            attributes:[self headerFooterAttrs]];
            }
            break;

        case CESyntaxNamePrintInfo:
            outString = [[NSAttributedString alloc] initWithString:[self syntaxName]
                                                        attributes:[self headerFooterAttrs]];
            break;
            
        case CEFilePathPrintInfo:
            if (filePath) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_headerFooterPathAbbreviatingWithTilde]) {
                    filePath = [[self filePath] stringByAbbreviatingWithTildeInPath];
                }
            } else {
                filePath = [self documentName];  // パスがない場合は書類名をプリント
            }
            outString = [[NSAttributedString alloc] initWithString:filePath
                                                        attributes:[self headerFooterAttrs]];
            break;

        case CEPrintDatePrintInfo:
            dateString = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults]
                                                                                       stringForKey:k_key_headerFooterDateTimeFormat]];
            if (dateString && ([dateString length] > 0)) {
                outString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Printed: %@", nil),
                                                                         dateString]
                                                            attributes:[self headerFooterAttrs]];
            }
            break;

        case CEPageNumberPrintInfo:
            outString = [[NSAttributedString alloc] initWithString:@"PAGENUM"
                                                        attributes:[self headerFooterAttrs]];
            [self setReadyToDrawPageNum:YES];
            break;

        case CENoPrintInfo:
            break;
    }

    // 印字があふれる場合、中ほどを省略する
    if ([outString size].width > maxWidth) {
        NSMutableAttributedString *attrStr = [outString mutableCopy];
        NSUInteger length = [attrStr length];
        CGFloat width = [attrStr size].width;
        if (length > 0) {
            CGFloat average = width / length;
            NSInteger deleteCount = (width - maxWidth) / average + 5; // 置き換える5文字の幅をみる
            NSRange replaceRange = NSMakeRange((NSUInteger)((length - deleteCount) / 2), deleteCount);
            [attrStr replaceCharactersInRange:replaceRange withString:@" ... "];
        }
        return attrStr;
    }

    return outString;
}


// ------------------------------------------------------
/// X軸方向の印字開始位置を返す
- (CGFloat)xValueToDrawOfAttributedString:(NSAttributedString *)attrString
                              borderWidth:(CGFloat)borderWidth
                                alignment:(CEAlignmentType)alignmentType
// ------------------------------------------------------
{
    switch (alignmentType) {
        case CEAlignLeft:
            return k_printHFHorizontalMargin;
            break;
        case CEAlignCenter:
            return (borderWidth - [attrString size].width) / 2;
            break;
        case CEAlignRight:
            return (borderWidth - [attrString size].width) - k_printHFHorizontalMargin;
            break;
    }
}

@end
