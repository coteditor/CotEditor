/*
=================================================
CEPrintView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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

//=======================================================
// Private method
//
//=======================================================

@interface CEPrintView (Private)
- (void)setupPrintWithBorderWidth:(float)inBorderWidth;
- (void)setHeaderOneString:(NSAttributedString *)inAttrString;
- (void)setHeaderTwoString:(NSAttributedString *)inAttrString;
- (void)setFooterOneString:(NSAttributedString *)inAttrString;
- (void)setFooterTwoString:(NSAttributedString *)inAttrString;
- (void)setHeaderOneAlignment:(int)inAlingnType;
- (void)setHeaderTwoAlignment:(int)inAlingnType;
- (void)setFooterOneAlignment:(int)inAlingnType;
- (void)setFooterTwoAlignment:(int)inAlingnType;
- (void)setPrintHeader:(BOOL)inBool;
- (void)setPrintFooter:(BOOL)inBool;
- (void)setPrintHeaderSeparator:(BOOL)inBool;
- (void)setPrintFooterSeparator:(BOOL)inBool;
- (NSAttributedString *)attributedStringFromPrintInfoSelectedIndex:(int)inIndex maxWidth:(float)inWidth;
- (float)xValueToDrawOfAttributedString:(NSAttributedString *)inAttrString 
        borderWidth:(float)inBorderWidth alignment:(int)inAlignType;
@end


//------------------------------------------------------------------------------------------




@implementation CEPrintView

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];

    if (self) {
        _filePath = nil;
        _lineNumAttrs = nil;
        _headerFooterAttrs = nil;
        _printValues = nil;
        _headerOneString = nil;
        _headerTwoString = nil;
        _footerOneString = nil;
        _footerTwoString = nil;
        _headerOneAlignment = 0;
        _headerTwoAlignment = 0;
        _footerOneAlignment = 0;
        _footerTwoAlignment = 0;
        _xOffset = 0.0;
        _readyToPrint = NO; // =ヘッダ／フッタ生成処理などの準備完了フラグ
        _printLineNum = NO;
        _printHeader = NO;
        _printFooter = NO;
        _printHeaderSeparator = NO;
        _printFooterSeparator = NO;
        _readyToDrawPageNum = NO;
        _showingLineNum = NO;
    }

    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片づけ
// ------------------------------------------------------
{
    [_filePath release];
    [_lineNumAttrs release];
    [_printValues release];
    [_headerFooterAttrs release];
    [_headerOneString release];
    [_headerTwoString release];
    [_footerOneString release];
    [_footerTwoString release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)drawPageBorderWithSize:(NSSize)inBorderSize
// ヘッダ／フッタの描画
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSRect theCurrentFrame = [self frame]; // 現在のフレームを退避
    NSAttributedString *thePageString = nil;
    NSPoint thePoint;
    float theHeaderFooterLineFontSize = [[theValues valueForKey:k_key_headerFooterFontSize] floatValue];
    float thePadding = k_printHFVerticalMargin;

    // プリントパネルでのカスタム設定を読み取り、保持
    if (_readyToPrint == NO) {
        [self setupPrintWithBorderWidth:inBorderSize.width];
    }
    // ページ番号の印字があるなら、準備する
    if (_readyToDrawPageNum) {
        int thePageNum = [[NSPrintOperation currentOperation] currentPage];

        thePageString = [[[NSAttributedString alloc] 
                initWithString:[NSString stringWithFormat:@"- %i -", thePageNum] 
                attributes:_headerFooterAttrs] autorelease];
    }

    // フレームを設定
    [self setFrame:NSMakeRect(0, 0, inBorderSize.width, inBorderSize.height)];
    // さらに、10.3.x ではフレームを重ねてセットしなければ印字されない ... バグ？（10.4.x では問題なし）
    // 下記の情報を参考にさせていただきました (2005.09.05)
    // http://www.cocoabuilder.com/archive/message/cocoa/2005/4/28/134100
    [self setFrameOrigin:NSZeroPoint];
    [self setFrameSize:inBorderSize];

    // 描画開始
    // （このビューは isFlipped が YES なので drawAtPoint: は左上が原点となる）
    [self lockFocus];

    if (_printHeader) {
        if ((_headerOneString != nil) && ([[_headerOneString string] isEqualToString:@"PAGENUM"])) {
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:thePageString 
                    borderWidth:inBorderSize.width alignment:_headerOneAlignment], thePadding);
            [thePageString drawAtPoint:thePoint];
            thePadding += k_headerFooterLineHeight;
        } else if (_headerOneString != nil) {
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:_headerOneString 
                    borderWidth:inBorderSize.width alignment:_headerOneAlignment], thePadding);
            [_headerOneString drawAtPoint:thePoint];
            thePadding += k_headerFooterLineHeight;
        }
        if (_headerTwoString == nil) {
            if (_headerOneString != nil) {
                thePadding += theHeaderFooterLineFontSize - k_headerFooterLineHeight;
            }
        } else if ((_headerTwoString != nil) && ([[_headerTwoString string] isEqualToString:@"PAGENUM"])) {
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:thePageString 
                    borderWidth:inBorderSize.width alignment:_headerTwoAlignment], thePadding);
            [thePageString drawAtPoint:thePoint];
            thePadding += theHeaderFooterLineFontSize;
        } else if (_headerTwoString != nil) {
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:_headerTwoString 
                    borderWidth:inBorderSize.width alignment:_headerTwoAlignment], thePadding);
            [_headerTwoString drawAtPoint:thePoint];
            thePadding += theHeaderFooterLineFontSize;
        }
    }
    if (_printHeaderSeparator) {
        thePadding += (k_separatorPadding / 2);
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, thePadding) 
            toPoint:NSMakePoint(inBorderSize.width - k_printHFHorizontalMargin, thePadding)];
    }

    // （thePadding を inBorderSize.height - k_printHFVerticalMargin とすると1ページに満たない書類の印刷時に
    // セパレータが印字されないので、フッタ全体を下げる。 2006.02.18）
    thePadding = inBorderSize.height - k_printHFVerticalMargin + k_separatorPadding;
    if (_printFooter) {
        if ((_footerTwoString != nil) && ([[_footerTwoString string] isEqualToString:@"PAGENUM"])) {
            thePadding -= k_headerFooterLineHeight;
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:thePageString 
                    borderWidth:inBorderSize.width alignment:_footerTwoAlignment], 
                    thePadding);
            [thePageString drawAtPoint:thePoint];
        } else if (_footerTwoString != nil) {
            thePadding -= k_headerFooterLineHeight;
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:_footerTwoString 
                    borderWidth:inBorderSize.width alignment:_footerTwoAlignment], 
                    thePadding);
            [_footerTwoString drawAtPoint:thePoint];
        }
        if (_footerOneString == nil) {
            if (_footerTwoString == nil) {
            }
        } else if ((_footerOneString != nil) && ([[_footerOneString string] isEqualToString:@"PAGENUM"])) {
            thePadding -= k_headerFooterLineHeight;
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:thePageString 
                    borderWidth:inBorderSize.width alignment:_footerOneAlignment], 
                    thePadding);
            [thePageString drawAtPoint:thePoint];
        } else if (_footerOneString != nil) {
            thePadding -= k_headerFooterLineHeight;
            thePoint = NSMakePoint([self xValueToDrawOfAttributedString:_footerOneString 
                    borderWidth:inBorderSize.width alignment:_footerOneAlignment], 
                    thePadding);
            [_footerOneString drawAtPoint:thePoint];
        }
    }
    if (_printFooterSeparator) {
        thePadding -= (k_separatorPadding / 2);
        [[NSColor controlShadowColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(k_printHFHorizontalMargin, thePadding) 
                toPoint:NSMakePoint(inBorderSize.width - k_printHFHorizontalMargin, thePadding)];
    }
    [self unlockFocus];

    // フレームをもとに戻す
    [self setFrame:theCurrentFrame];
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// プリント
// ------------------------------------------------------
{
    [super drawRect:inRect];

    // 行番号を印字
    if (_printLineNum) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        float theLineNumFontSize = [[theValues valueForKey:k_key_lineNumFontSize] floatValue];

        //文字幅を計算しておく 等幅扱い
        //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
        float charWidth = [@"8" sizeWithAttributes:_lineNumAttrs].width;

        // setup the variables we need for the loop
        NSRange theRange;       // a range for counting lines
        NSString *theStr = [self string];
        NSString *theNumStr;    // a temporary string for Line Number
        NSString *theWrapedLineMark = ([[theValues valueForKey:k_key_showWrappedLineMark] boolValue]) ? 
                [NSString stringWithString:@"-:"] : [NSString stringWithString:@" "];
        int theGlyphIndex, theBefore, theGlyphCount; // glyph counter
        int theCharIndex;
        int theLineNum;     // line counter
        float theReqWidth;      // width calculator holder -- width needed to show string
        float theXAdj = 0;       // adjust horizontal value for line number drawing
        float theYAdj = 0;       // adjust vertical value for line number drawing
        NSRect theNumRect;      // rectange holder
        NSPoint theNumPoint;    // point holder
        NSLayoutManager *theManager = [self layoutManager]; // get _owner's layout manager.
        unsigned theNumOfGlyphs = [theManager numberOfGlyphs];

        theBefore = 0;
        theLineNum = 1;
        theGlyphCount = 0;
        theXAdj = [self textContainerOrigin].x + k_printHFHorizontalMargin - k_lineNumPadding;
        theYAdj = ([[self font] pointSize] - theLineNumFontSize) / 2;

        for (theGlyphIndex = 0; theGlyphIndex < theNumOfGlyphs; theLineNum++) { // count "REAL" lines
            theCharIndex = [theManager characterIndexForGlyphAtIndex:theGlyphIndex];
            theGlyphIndex = NSMaxRange([theManager glyphRangeForCharacterRange:
                                [theStr lineRangeForRange:NSMakeRange(theCharIndex, 0)] 
                                actualCharacterRange:NULL]);
            while (theGlyphCount < theGlyphIndex) { // handle "DRAWN" (wrapped) lines
                theNumRect = [theManager lineFragmentRectForGlyphAtIndex:theGlyphCount effectiveRange:&theRange];
                if (NSPointInRect(theNumRect.origin, inRect)) {
                    if (theBefore != theLineNum) {
                        theNumStr = [NSString stringWithFormat:@"%d:", theLineNum];
                        theReqWidth = charWidth * [theNumStr length];
                    } else {
                        theNumStr = theWrapedLineMark;
                        theReqWidth = 8.0; // @"-:"のときに必要なピクセル値。変更時、注意。*****
                    }
                    theNumPoint = 
                            NSMakePoint(
                                (inRect.origin.x - theReqWidth + theXAdj), 
                                theNumRect.origin.y + theYAdj);
                    [theNumStr drawAtPoint:theNumPoint withAttributes:_lineNumAttrs]; // draw the line number.
                    theBefore = theLineNum;
                }
                theGlyphCount = NSMaxRange(theRange);
            }
        }
    }
}


// ------------------------------------------------------
- (BOOL)isFlipped
// Y軸を逆転させる
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
- (NSPoint)textContainerOrigin
// the top/left point of text container.
// ------------------------------------------------------
{
    return (NSMakePoint(_xOffset, 0.0));
}


// ------------------------------------------------------
- (void)setFilePath:(NSString *)inFilePath
// ファイルパスをセット
// ------------------------------------------------------
{
    [inFilePath retain]; // ===== retain
    [_filePath release];
    _filePath = inFilePath;
}


// ------------------------------------------------------
- (float)lineSpacing
// 行間値を返す
// ------------------------------------------------------
{
    return _lineSpacing;
}


// ------------------------------------------------------
- (void)setLineSpacing:(float)inLineSpacing
// 行間値をセット
// ------------------------------------------------------
{
    _lineSpacing = inLineSpacing;
}


// ------------------------------------------------------
- (id)printValues
// プリンタダイアログでの設定オブジェクトを返す
// ------------------------------------------------------
{
    return _printValues;
}


// ------------------------------------------------------
- (void)setPrintValues:(id)inValues
// プリンタダイアログでの設定オブジェクトをセット
// ------------------------------------------------------
{
    [inValues retain];
    [_printValues release];
    _printValues = inValues;
}


// ------------------------------------------------------
- (BOOL)isShowingLineNum
// CETextViewCoreが行番号を表示しているかを返す
// ------------------------------------------------------
{
    return _showingLineNum;
}


// ------------------------------------------------------
- (void)setIsShowingLineNum:(BOOL)inValue
// CETextViewCoreが行番号を表示しているかをセット
// ------------------------------------------------------
{
    _showingLineNum = inValue;
}



@end



@implementation CEPrintView (Private)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setupPrintWithBorderWidth:(float)inBorderWidth
// プリント開始の準備
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSAttributedString *theAttrString = nil;
    float thePrintWidth = inBorderWidth - k_printHFHorizontalMargin * 2;
    int theLineNumMenuIndex = [[[self printValues] valueForKey:k_printLineNumIndex] intValue];

    // ヘッダ／フッタの文字属性辞書生成、保持
    NSFont *theHeaderFooterFont = [NSFont fontWithName:[theValues valueForKey:k_key_headerFooterFontName] 
                size:[[theValues valueForKey:k_key_headerFooterFontSize] floatValue]];
    _headerFooterAttrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                    theHeaderFooterFont, NSFontAttributeName, 
                    [NSColor textColor], NSForegroundColorAttributeName, 
                    nil] retain]; // ===== retain

    // 行番号印字の有無をチェック
    if (theLineNumMenuIndex == 1) { // same to view
        _printLineNum = [self isShowingLineNum];
    } else if (theLineNumMenuIndex == 2) { // print
        _printLineNum = YES;
    } else {
        _printLineNum = NO;
    }

    // 行番号を印字するときは文字属性を保持、パディングを調整
    if (_printLineNum) {
        NSFont *theFont = [NSFont fontWithName:[theValues valueForKey:k_key_lineNumFontName] 
                            size:[[theValues valueForKey:k_key_lineNumFontSize] floatValue]];
        _lineNumAttrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                        theFont, NSFontAttributeName, 
                        [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_lineNumFontColor]], 
                            NSForegroundColorAttributeName, 
                        nil] retain]; // ===== retain
        _xOffset = k_printTextHorizontalMargin;
    }
    // ヘッダを設定
    if ([[[self printValues] valueForKey:k_printHeader] boolValue]) {
        [self setPrintHeader:YES];
        theAttrString = [self attributedStringFromPrintInfoSelectedIndex:
                        [[[self printValues] valueForKey:k_headerOneStringIndex] intValue] 
                        maxWidth:thePrintWidth];
        [self setHeaderOneString:theAttrString];
        theAttrString = [self attributedStringFromPrintInfoSelectedIndex:
                        [[[self printValues] valueForKey:k_headerTwoStringIndex] intValue] 
                        maxWidth:thePrintWidth];
        [self setHeaderTwoString:theAttrString];
        [self setHeaderOneAlignment:[[[self printValues] valueForKey:k_headerOneAlignIndex] intValue]];
        [self setHeaderTwoAlignment:[[[self printValues] valueForKey:k_headerTwoAlignIndex] intValue]];
    } else {
        [self setPrintHeader:NO];
    }
    [self setPrintHeaderSeparator:[[[self printValues] valueForKey:k_printHeaderSeparator] boolValue]];

    // フッタを設定
    if ([[[self printValues] valueForKey:k_printFooter] boolValue]) {
        [self setPrintFooter:YES];
        theAttrString = [self attributedStringFromPrintInfoSelectedIndex:
                        [[[self printValues] valueForKey:k_footerOneStringIndex] intValue] 
                        maxWidth:thePrintWidth];
        [self setFooterOneString:theAttrString];
        theAttrString = [self attributedStringFromPrintInfoSelectedIndex:
                    [[[self printValues] valueForKey:k_footerTwoStringIndex] intValue] 
                    maxWidth:thePrintWidth];
        [self setFooterTwoString:theAttrString];
        [self setFooterOneAlignment:[[[self printValues] valueForKey:k_footerOneAlignIndex] intValue]];
        [self setFooterTwoAlignment:[[[self printValues] valueForKey:k_footerTwoAlignIndex] intValue]];
    } else {
        [self setPrintFooter:NO];
    }
    [self setPrintFooterSeparator:[[[self printValues] valueForKey:k_printFooterSeparator] boolValue]];
    _readyToPrint = YES;
}


// ------------------------------------------------------
- (void)setHeaderOneString:(NSAttributedString *)inAttrString
// ヘッダ1の属性付き文字列をセット
// ------------------------------------------------------
{
    [inAttrString retain]; // ===== retain
    [_headerOneString release];
    _headerOneString = inAttrString;
}


// ------------------------------------------------------
- (void)setHeaderTwoString:(NSAttributedString *)inAttrString
// ヘッダ2の属性付き文字列をセット
// ------------------------------------------------------
{
    [inAttrString retain]; // ===== retain
    [_headerTwoString release];
    _headerTwoString = inAttrString;
}


// ------------------------------------------------------
- (void)setFooterOneString:(NSAttributedString *)inAttrString
// フッタ1の属性付き文字列をセット
// ------------------------------------------------------
{
    [inAttrString retain]; // ===== retain
    [_footerOneString release];
    _footerOneString = inAttrString;
}


// ------------------------------------------------------
- (void)setFooterTwoString:(NSAttributedString *)inAttrString
// フッタ2の属性付き文字列をセット
// ------------------------------------------------------
{
    [inAttrString retain]; // ===== retain
    [_footerTwoString release];
    _footerTwoString = inAttrString;
}


// ------------------------------------------------------
- (void)setHeaderOneAlignment:(int)inAlingnType
// ヘッダ1の文字位置タイプをセット
// ------------------------------------------------------
{
    _headerOneAlignment = inAlingnType;
}


// ------------------------------------------------------
- (void)setHeaderTwoAlignment:(int)inAlingnType
// ヘッダ2の文字位置タイプをセット
// ------------------------------------------------------
{
    _headerTwoAlignment = inAlingnType;
}


// ------------------------------------------------------
- (void)setFooterOneAlignment:(int)inAlingnType
// フッタ1の文字位置タイプをセット
// ------------------------------------------------------
{
    _footerOneAlignment = inAlingnType;
}


// ------------------------------------------------------
- (void)setFooterTwoAlignment:(int)inAlingnType
// フッタ2の文字位置タイプをセット
// ------------------------------------------------------
{
    _footerTwoAlignment = inAlingnType;
}


// ------------------------------------------------------
- (void)setPrintHeader:(BOOL)inBool
// ヘッダ印刷の有無をセット
// ------------------------------------------------------
{
    _printHeader = inBool;
}


// ------------------------------------------------------
- (void)setPrintFooter:(BOOL)inBool
// フッタ印刷の有無をセット
// ------------------------------------------------------
{
    _printFooter = inBool;
}


// ------------------------------------------------------
- (void)setPrintHeaderSeparator:(BOOL)inBool
// ヘッダセパレータ印刷の有無をセット
// ------------------------------------------------------
{
    _printHeaderSeparator = inBool;
}


// ------------------------------------------------------
- (void)setPrintFooterSeparator:(BOOL)inBool
// フッタセパレータ印刷の有無をセット
// ------------------------------------------------------
{
    _printFooterSeparator = inBool;
}


// ------------------------------------------------------
- (NSAttributedString *)attributedStringFromPrintInfoSelectedIndex:(int)inIndex maxWidth:(float)inWidth
// ヘッダ／フッタに印字する文字列をポップアップメニューインデックスから生成し、返す
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSAttributedString *outString = nil;
    NSString *theDateString;
            
    switch(inIndex) {

    case 2: // == Document Name
        if (_filePath != nil) {
            outString = [[[NSAttributedString alloc] 
                    initWithString:[_filePath lastPathComponent] attributes:_headerFooterAttrs] autorelease];
        }
        break;

    case 3: // == File Path
        if (_filePath != nil) {
            outString = [[[NSAttributedString alloc] 
                    initWithString:_filePath attributes:_headerFooterAttrs] autorelease];
        }
        break;

    case 4: // == Print Date
        theDateString = [[NSCalendarDate calendarDate] 
                descriptionWithCalendarFormat:[theValues valueForKey:k_key_headerFooterDateTimeFormat]];
        if ((theDateString != nil) && ([theDateString length] > 0)) {
            outString = [[[NSAttributedString alloc] initWithString:
                    [NSString stringWithFormat:NSLocalizedString(@"Printed: %@",@""), theDateString] 
                    attributes:_headerFooterAttrs] autorelease];
        }
        break;

    case 5: // == Page num
        outString = [[[NSAttributedString alloc] initWithString:[NSString stringWithString:@"PAGENUM"] 
                        attributes:_headerFooterAttrs] autorelease];
        _readyToDrawPageNum = YES;
        break;

    default:
        break;
    }

    // 印字があふれる場合、中ほどを省略する
    if ([outString size].width > inWidth) {
        NSMutableAttributedString *theAttrStr = [[outString mutableCopy] autorelease];
        int theLength = [theAttrStr length];
        float theWidth = [theAttrStr size].width;
        if (theLength > 0) {
            float theAverage = theWidth / theLength;
            int theDeleteCount = (theWidth - inWidth) / theAverage + 5; // 置き換える5文字の幅をみる
            NSRange theReplaceRange = 
                    NSMakeRange((unsigned int)((theLength - theDeleteCount) / 2), theDeleteCount);
            [theAttrStr replaceCharactersInRange:theReplaceRange withString:@" ... "];
        }
        return theAttrStr;
    }

    return outString;
}


// ------------------------------------------------------
- (float)xValueToDrawOfAttributedString:(NSAttributedString *)inAttrString 
        borderWidth:(float)inBorderWidth alignment:(int)inAlignType
// X軸方向の印字開始位置を返す
// ------------------------------------------------------
{
    float outFloat = k_printHFHorizontalMargin;

    switch(inAlignType) {
    
    case 1: // == center
        outFloat = (inBorderWidth - [inAttrString size].width) / 2;
        break;
    case 2: // == right
        outFloat = inBorderWidth - [inAttrString size].width - k_printHFHorizontalMargin;
        break;
    default:
        break;
    }
    return outFloat;
}

@end
