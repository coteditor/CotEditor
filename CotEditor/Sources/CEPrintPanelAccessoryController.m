/*
 =================================================
 CEPrintAccessoryViewController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-24 by 1024jp
 
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

#import "CEPrintPanelAccessoryController.h"
#import "constants.h"


@interface CEPrintPanelAccessoryController ()

@property (nonatomic, readwrite) CEColorPrintMode colorMode;
@property (nonatomic, readwrite) CELineNumberPrintMode lineNumberMode;
@property (nonatomic, readwrite) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (nonatomic, readwrite) BOOL printsHeader;
@property (nonatomic, readwrite) CEPrintInfoType headerOneInfoType;
@property (nonatomic, readwrite) CEAlignmentType headerOneAlignmentType;
@property (nonatomic, readwrite) CEPrintInfoType headerTwoInfoType;
@property (nonatomic, readwrite) CEAlignmentType headerTwoAlignmentType;
@property (nonatomic, readwrite) BOOL printsHeaderSeparator;

@property (nonatomic, readwrite) BOOL printsFooter;
@property (nonatomic, readwrite) CEPrintInfoType footerOneInfoType;
@property (nonatomic, readwrite) CEAlignmentType footerOneAlignmentType;
@property (nonatomic, readwrite) CEPrintInfoType footerTwoInfoType;
@property (nonatomic, readwrite) CEAlignmentType footerTwoAlignmentType;
@property (nonatomic, readwrite) BOOL printsFooterSeparator;

@end




#pragma mark -

@implementation CEPrintPanelAccessoryController

#pragma mark Superclass Methods

//=======================================================
// Superclass Methods
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithNibName:@"PrintPanelAccessory" bundle:nil];
    if (self) {
        // マージンに関わるキー値を監視する
        for (NSString *key in [self keyPathsForValuesAffectingHeaderMargin]) {
            [self addObserver:self forKeyPath:key options:0 context:NULL];
        }
        for (NSString *key in [self keyPathsForValuesAffectingFooterMargin]) {
            [self addObserver:self forKeyPath:key options:0 context:NULL];
        }
    }
    return self;
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    // 監視していたキー値を取り除く
    for (NSString *key in [self keyPathsForValuesAffectingHeaderMargin]) {
        [self removeObserver:self forKeyPath:key];
    }
    for (NSString *key in [self keyPathsForValuesAffectingFooterMargin]) {
        [self removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
    [self setColorMode:[defaults integerForKey:k_printColorIndex]];
    [self setLineNumberMode:[defaults integerForKey:k_printLineNumIndex]];
    [self setInvisibleCharsMode:[defaults integerForKey:k_printInvisibleCharIndex]];
    [self setPrintsHeader:[defaults boolForKey:k_printHeader]];
    [self setHeaderOneInfoType:[defaults integerForKey:k_headerOneStringIndex]];
    [self setHeaderOneAlignmentType:[defaults integerForKey:k_headerOneAlignIndex]];
    [self setHeaderTwoInfoType:[defaults integerForKey:k_headerTwoStringIndex]];
    [self setHeaderTwoAlignmentType:[defaults integerForKey:k_headerTwoAlignIndex]];
    [self setPrintsHeaderSeparator:[defaults boolForKey:k_printHeaderSeparator]];
    [self setPrintsFooter:[defaults boolForKey:k_printFooter]];
    [self setFooterOneInfoType:[defaults integerForKey:k_footerOneStringIndex]];
    [self setFooterOneAlignmentType:[defaults integerForKey:k_footerOneAlignIndex]];
    [self setFooterTwoInfoType:[defaults integerForKey:k_footerTwoStringIndex]];
    [self setFooterTwoAlignmentType:[defaults integerForKey:k_footerTwoAlignIndex]];
    [self setPrintsFooterSeparator:[defaults boolForKey:k_printFooterSeparator]];
}


// ------------------------------------------------------
/// printInfoがセットされた
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    // printInfoの値をヘッダ／フッタのマージンに反映させる
    [self updateHeaderOffset];
    [self updateFooterOffset];
}


// ------------------------------------------------------
/// 監視しているキー値が変更された
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([[self keyPathsForValuesAffectingFooterMargin] containsObject:keyPath]) {
        [self updateHeaderOffset];
    }
    if ([[self keyPathsForValuesAffectingFooterMargin] containsObject:keyPath]) {
        [self updateFooterOffset];
    }
}



#pragma mark Protocol

//=======================================================
// NSPrintPanelAccessorizing Protocol
//
//=======================================================

// ------------------------------------------------------
/// プレビューに影響するキーのセットを返す
- (NSSet *)keyPathsForValuesAffectingPreview
// ------------------------------------------------------
{
    return [NSSet setWithArray:@[@"colorMode",
                                 @"lineNumberMode",
                                 @"invisibleCharsMode",
                                 @"printsHeader",
                                 @"headerOneInfoType",
                                 @"headerOneAlignmentType",
                                 @"headerTwoInfoType",
                                 @"headerTwoAlignmentType",
                                 @"printsHeaderSeparator",
                                 @"printsFooter",
                                 @"footerOneInfoType",
                                 @"footerOneAlignmentType",
                                 @"footerTwoInfoType",
                                 @"footerTwoAlignmentType",
                                 @"printsFooterSeparator"]];
}


// ------------------------------------------------------
/// ローカライズ済みの設定説明を返す
-(NSArray *)localizedSummaryItems
// ------------------------------------------------------
{
    NSMutableArray *items = [NSMutableArray array];
    NSString *description;
    
    switch ([self colorMode]) {
        case CEBlackColorPrint:
            description = @"Black Text";
            break;
        case CESameAsDocumentColorPrint:
            description = @"Same as Document's Setting";
            break;
    }
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Color", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    
    switch ([self lineNumberMode]) {
        case CENoLinePrint:
            description = @"Don't Print";
            break;
        case CESameAsDocumentLinePrint:
            description = @"Same as Document's Setting";
            break;
        case CEDoLinePrint:
            description = @"Print";
            break;
    }
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Line Number", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    
    switch ([self invisibleCharsMode]) {
        case CENoInvisibleCharsPrint:
            description = @"Don't Print";
            break;
        case CESameAsDocumentInvisibleCharsPrint:
            description = @"Same as Document's Setting";
            break;
        case CEAllInvisibleCharsPrint:
            description = @"Print All";
            break;
    }
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Invisible Characters", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    
    
    description = [self printsHeader] ? @"On" : @"Off";
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Print Header", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    if ([self printsHeader]) {
        description = [self printInfoDescription:[self headerOneInfoType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Header Line 1", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self alignmentDescription:[self headerOneAlignmentType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Header Line 1 Alignment", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self printInfoDescription:[self headerTwoInfoType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Header Line 2", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self alignmentDescription:[self headerTwoAlignmentType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Header Line 2 Alignment", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    }
    description = [self printsHeaderSeparator] ? @"On" : @"Off";
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Print Header Separator", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    
    description = [self printsFooter] ? @"On" : @"Off";
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Print Footer", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    if ([self printsFooter]) {
        description = [self printInfoDescription:[self footerOneInfoType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Footer Line 1", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self alignmentDescription:[self footerOneAlignmentType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Footer Line 1 Alignment", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self printInfoDescription:[self footerTwoInfoType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Footer Line 2", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
        
        description = [self alignmentDescription:[self footerTwoInfoType]];
        [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Footer Line 2 Alignment", k_printLocalizeTable, nil),
                           NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    }
    description = [self printsFooterSeparator] ? @"On" : @"Off";
    [items addObject:@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(@"Print Footer Separator", k_printLocalizeTable, nil),
                       NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, k_printLocalizeTable, nil)}];
    
    return items;
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// ヘッダマージンを再計算する
- (void)updateHeaderOffset
// ------------------------------------------------------
{
    NSPrintInfo *printInfo = [self representedObject];
    
    CGFloat topMargin = k_printHFVerticalMargin;
    
    // ヘッダ／フッタの高さ（文書を印刷しない高さ）を得る
    if ([self printsHeader]) {
        if ([self headerOneInfoType] != CENoPrintInfo) {  // 行1 = 印字あり
            topMargin += k_headerFooterLineHeight;
        }
        if ([self headerTwoInfoType] != CENoPrintInfo) {  // 行2 = 印字あり
            topMargin += k_headerFooterLineHeight;
        }
    }
    // ヘッダと本文との距離をセパレータも勘案して決定する（フッタは本文との間が開くことが多いため、入れない）
    if (topMargin > k_printHFVerticalMargin) {
        topMargin += (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_headerFooterFontSize] - k_headerFooterLineHeight;
        
        if ([self printsHeaderSeparator]) {
            topMargin += k_separatorPadding;
        } else {
            topMargin += k_noSeparatorPadding;
        }
    } else {
        if ([self printsHeaderSeparator]) {
            topMargin += k_separatorPadding;
        }
    }
    
    // printView が flip しているので入れ替えている
    [printInfo setBottomMargin:topMargin];
}


// ------------------------------------------------------
/// フッタマージンを再計算する
- (void)updateFooterOffset
// ------------------------------------------------------
{
    NSPrintInfo *printInfo = [self representedObject];
    
    CGFloat bottomMargin = k_printHFVerticalMargin;
    
    if ([self printsFooter]) {
        if ([self footerOneInfoType] != CENoPrintInfo) {  // 行1 = 印字あり
            bottomMargin += k_headerFooterLineHeight;
        }
        if ([self footerTwoInfoType] != CENoPrintInfo) {  // 行2 = 印字あり
            bottomMargin += k_headerFooterLineHeight;
        }
    }
    if ((bottomMargin == k_printHFVerticalMargin) && [self printsFooterSeparator]) {
        bottomMargin += k_separatorPadding;
    }
    
    // printView が flip しているので入れ替えている
    [printInfo setTopMargin:bottomMargin];
}


// ------------------------------------------------------
/// ヘッダー／フッターの表示情報タイプから文字列を返す
- (NSString *)printInfoDescription:(CEPrintInfoType)type
// ------------------------------------------------------
{
    switch (type) {
        case CENoPrintInfo:
            return @"None";
        
        case CESyntaxNamePrintInfo:
            return @"Syntax Name";
            
        case CEDocumentNamePrintInfo:
            return @"Document Name";
            
        case CEFilePathPrintInfo:
            return @"File Path";
            
        case CEPrintDatePrintInfo:
            return @"Print Date";
            
        case CEPageNumberPrintInfo:
            return @"Page Number";
    }
}


// ------------------------------------------------------
/// 行揃えタイプから文字列を返す
- (NSString *)alignmentDescription:(CEAlignmentType)type
// ------------------------------------------------------
{
    switch (type) {
        case CEAlignLeft:
            return @"Left";
            
        case CEAlignCenter:
            return @"Center";
            
        case CEAlignRight:
            return @"Right";
    }
}


// ------------------------------------------------------
/// ヘッダマージンに影響するキーのセットを返す
- (NSSet *)keyPathsForValuesAffectingHeaderMargin
// ------------------------------------------------------
{
    return [NSSet setWithArray:@[@"printsHeader",
                                 @"headerOneInfoType",
                                 @"headerTwoInfoType",
                                 @"printsHeaderSeparator"]];
}


// ------------------------------------------------------
/// フッタマージンに影響するキーのセットを返す
- (NSSet *)keyPathsForValuesAffectingFooterMargin
// ------------------------------------------------------
{
    return [NSSet setWithArray:@[@"printsFooter",
                                 @"footerOneInfoType",
                                 @"footerTwoInfoType",
                                 @"printsFooterSeparator"]];
}

@end
