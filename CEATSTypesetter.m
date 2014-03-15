/*
=================================================
CEATSTypesetter
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.12.08

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

#import "CEATSTypesetter.h"
#import "CETextViewCore.h"


@implementation CEATSTypesetter

static CEATSTypesetter *sharedInstance = nil;

#pragma mark ===== Class method =====

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (CEATSTypesetter *)sharedSystemTypesetter
// 共有インスタンスを返す
// ------------------------------------------------------
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    if (sharedInstance == nil) {
        sharedInstance = [super init];
    }
    return sharedInstance;
}


// ------------------------------------------------------
- (BOOL)usesFontLeading
// フォントの leading 値を反映させるかどうかを返す
// ------------------------------------------------------
{
    CELayoutManager *theManager = (CELayoutManager *)[self layoutManager];

    return ([theManager isPrinting] || (!([theManager fixLineHeight])));
}


// ------------------------------------------------------
- (CGFloat)lineSpacingAfterGlyphAtIndex:(NSUInteger)inGlyphIndex withProposedLineFragmentRect:(NSRect)inRect
// 行間ピクセル数を返す
// ------------------------------------------------------
{
    CELayoutManager *theManager = (CELayoutManager *)[self layoutManager];
    CGFloat theLineSpacing = [(CETextViewCore *)[[self currentTextContainer] textView] lineSpacing];
    CGFloat theFontSize;

    if (([theManager isPrinting]) || (![theManager fixLineHeight])) {
        // 印刷時または複合フォントでの行間固定をしないときは、システム既定値に、設定された行間を追加するだけ
        // （[NSGraphicsContext currentContextDrawingToScreen] が真を返す時があるため、専用フラグで印刷中を確認）
        CGFloat theSpacing = [super lineSpacingAfterGlyphAtIndex:inGlyphIndex withProposedLineFragmentRect:inRect];
        theFontSize = [[[[self currentTextContainer] textView] font] pointSize];

        return (theSpacing + theLineSpacing * theFontSize);

    }
    // 複合フォントで行の高さがばらつくのを防止する
    // （CELayoutManager の関連メソッドをオーバーライドしてあれば、このメソッドをオーバーライドしなくても
    // 通常の入力では行間が一定になるが、フォントや行間を変更したときに適正に描画されない）
    // （CETextViewCore で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
    // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
    // 挿入すると行間がズレる」問題が生じる）
    CGFloat theDefaultLineHeight = [theManager defaultLineHeightForTextFont];
    theFontSize = [theManager textFontPointSize];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return floor(theDefaultLineHeight - inRect.size.height + theLineSpacing * theFontSize + 0.5);
}


@end
