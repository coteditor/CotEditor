/*
 ==============================================================================
 CEATSTypesetter
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-12-08 by nakamuxu
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

#import "CEATSTypesetter.h"
#import "CETextViewProtocol.h"


@implementation CEATSTypesetter

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedSystemTypesetter
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// フォントの leading 値を反映させるかどうかを返す
- (BOOL)usesFontLeading
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[self layoutManager];

    return ([manager isPrinting] || ![manager fixesLineHeight]);
}


// ------------------------------------------------------
/// 行間ピクセル数を返す
- (CGFloat)lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(NSRect)rect
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[self layoutManager];
    CGFloat lineSpacing = [(NSTextView<CETextViewProtocol> *)[[self currentTextContainer] textView] lineSpacing];
    CGFloat fontSize;

    if ([manager isPrinting] || ![manager fixesLineHeight]) {
        // 印刷時または複合フォントでの行間固定をしないときは、システム既定値に、設定された行間を追加するだけ
        // （[NSGraphicsContext currentContextDrawingToScreen] が真を返す時があるため、専用フラグで印刷中を確認）
        CGFloat spacing = [super lineSpacingAfterGlyphAtIndex:glyphIndex withProposedLineFragmentRect:rect];
        fontSize = [[[[self currentTextContainer] textView] font] pointSize];

        return (spacing + lineSpacing * fontSize);

    }
    // 複合フォントで行の高さがばらつくのを防止する
    // （CELayoutManager の関連メソッドをオーバーライドしてあれば、このメソッドをオーバーライドしなくても
    // 通常の入力では行間が一定になるが、フォントや行間を変更したときに適正に描画されない）
    // （CETextView で、NSParagraphStyle の lineSpacing を設定しても行間は制御できるが、
    // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
    // 挿入すると行間がズレる」問題が生じる）
    CGFloat defaultLineHeight = [manager defaultLineHeightForTextFont];
    fontSize = [manager textFontPointSize];

    // 小数点以下を返すと選択範囲が分離することがあるため、丸める
    return floor(defaultLineHeight - rect.size.height + lineSpacing * fontSize + 0.5);
}

@end
