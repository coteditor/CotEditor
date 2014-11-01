/*
 ==============================================================================
 CEPrintAccessoryViewController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CEPrintPanelAccessoryController.h"
#import "CEThemeManager.h"


@interface CEPrintPanelAccessoryController ()

@property (nonatomic) IBOutlet NSPopUpButton *themePopup;


@property (readwrite, nonatomic) NSString *theme;
@property (readwrite, nonatomic) CELineNumberPrintMode lineNumberMode;
@property (readwrite, nonatomic) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (readwrite, nonatomic) BOOL printsHeader;
@property (readwrite, nonatomic) CEPrintInfoType headerOneInfoType;
@property (readwrite, nonatomic) CEAlignmentType headerOneAlignmentType;
@property (readwrite, nonatomic) CEPrintInfoType headerTwoInfoType;
@property (readwrite, nonatomic) CEAlignmentType headerTwoAlignmentType;
@property (readwrite, nonatomic) BOOL printsHeaderSeparator;

@property (readwrite, nonatomic) BOOL printsFooter;
@property (readwrite, nonatomic) CEPrintInfoType footerOneInfoType;
@property (readwrite, nonatomic) CEAlignmentType footerOneAlignmentType;
@property (readwrite, nonatomic) CEPrintInfoType footerTwoInfoType;
@property (readwrite, nonatomic) CEAlignmentType footerTwoAlignmentType;
@property (readwrite, nonatomic) BOOL printsFooterSeparator;

/// printInfoのマージンが更新されたことを知らせるフラグ
@property (nonatomic) BOOL readyToDraw;

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
        [self updateThemeList];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
        [self setLineNumberMode:[defaults integerForKey:CEDefaultPrintLineNumIndexKey]];
        [self setInvisibleCharsMode:[defaults integerForKey:CEDefaultPrintInvisibleCharIndexKey]];
        [self setPrintsHeader:[defaults boolForKey:CEDefaultPrintHeaderKey]];
        [self setHeaderOneInfoType:[defaults integerForKey:CEDefaultHeaderOneStringIndexKey]];
        [self setHeaderOneAlignmentType:[defaults integerForKey:CEDefaultHeaderOneAlignIndexKey]];
        [self setHeaderTwoInfoType:[defaults integerForKey:CEDefaultHeaderTwoStringIndexKey]];
        [self setHeaderTwoAlignmentType:[defaults integerForKey:CEDefaultHeaderTwoAlignIndexKey]];
        [self setPrintsHeaderSeparator:[defaults boolForKey:CEDefaultPrintHeaderSeparatorKey]];
        [self setPrintsFooter:[defaults boolForKey:CEDefaultPrintFooterKey]];
        [self setFooterOneInfoType:[defaults integerForKey:CEDefaultFooterOneStringIndexKey]];
        [self setFooterOneAlignmentType:[defaults integerForKey:CEDefaultFooterOneAlignIndexKey]];
        [self setFooterTwoInfoType:[defaults integerForKey:CEDefaultFooterTwoStringIndexKey]];
        [self setFooterTwoAlignmentType:[defaults integerForKey:CEDefaultFooterTwoAlignIndexKey]];
        [self setPrintsFooterSeparator:[defaults boolForKey:CEDefaultPrintFooterSeparatorKey]];
        
        // テーマを使用する場合はセットしておく
        switch ([defaults integerForKey:CEDefaultPrintColorIndexKey]) {
            case CEBlackColorPrint:
                [self setTheme:NSLocalizedStringFromTable(@"Black and White", CEPrintLocalizeTable, nil)];
                break;
            case CESameAsDocumentColorPrint:
                [self setTheme:[defaults stringForKey:CEDefaultThemeKey]];
                break;
            default:
                [self setTheme:[defaults stringForKey:CEDefaultPrintThemeKey]];
        }
        
        // マージンに関わるキー値を監視する
        for (NSString *key in [self keyPathsForValuesAffectingMargin]) {
            [self addObserver:self forKeyPath:key options:0 context:NULL];
        }
        
        [self updateThemeList];
    }
    return self;
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    // 監視していたキー値を取り除く
    for (NSString *key in [self keyPathsForValuesAffectingMargin]) {
        [self removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// printInfoがセットされた （新たにプリントシートが表示される）
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    // printInfoの値をヘッダ／フッタのマージンに反映させる
    [self updateVerticalOffset];
    
    // 現在のテーマラインナップを反映させる
    [self updateThemeList];
}


// ------------------------------------------------------
/// 監視しているキー値が変更された
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([[self keyPathsForValuesAffectingMargin] containsObject:keyPath]) {
        [self updateVerticalOffset];
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
    return [NSSet setWithArray:@[@"theme",
                                 @"lineNumberMode",
                                 @"invisibleCharsMode",
                                 @"printsHeader",
                                 @"headerOneAlignmentType",
                                 @"headerTwoAlignmentType",
                                 @"footerOneAlignmentType",
                                 @"footerTwoAlignmentType",
                                 
                                 // ヘッダ／フッタの設定に合わせてprintInfoのマージンを書き換えるため、
                                 // 直接設定の変更を監視するのではなくマージンの書き換え完了フラグを監視する
                                 @"readyToDraw"
                                 ]];
}


// ------------------------------------------------------
/// ローカライズ済みの設定説明を返す
-(NSArray *)localizedSummaryItems
// ------------------------------------------------------
{
    // 現時点ではこのアクセサリビューでの設定値はプリントパネルにあるプリセットに対応していない (2014-03-29 1024jp)
    // (ただし、リストに表示はされる)
    // プリセットにアプリケーション独自の設定を保存するためには、KVOに準拠しつつ[printInfo printSettings]で全ての値を管理する必要がある。
    
    NSMutableArray *items = [NSMutableArray array];
    NSString *description = @"";
    
    [items addObject:[self localizedSummaryItemWithName:@"Color"
                                            description:[self theme]]];
    
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
    [items addObject:[self localizedSummaryItemWithName:@"Line Number"
                                            description:description]];
    
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
    [items addObject:[self localizedSummaryItemWithName:@"Invisible Characters"
                                            description:description]];
    
    [items addObject:[self localizedSummaryItemWithName:@"Header Footer"
                                            description:([self printsHeader] ? @"On" : @"Off")]];
    
    if ([self printsHeader]) {
        [items addObject:[self localizedSummaryItemWithName:@"Header Line 1"
                                                description:[self printInfoDescription:[self headerOneInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Header Line 1 Alignment"
                                                description:[self alignmentDescription:[self headerOneAlignmentType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Header Line 2"
                                                description:[self printInfoDescription:[self headerTwoInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Header Line 2 Alignment"
                                                description:[self alignmentDescription:[self headerTwoAlignmentType]]]];
    }
    [items addObject:[self localizedSummaryItemWithName:@"Print Header Separator"
                                            description:([self printsHeaderSeparator] ? @"On" : @"Off")]];
    
    [items addObject:[self localizedSummaryItemWithName:@"Print Footer"
                                            description:([self printsFooter] ? @"On" : @"Off")]];
    if ([self printsFooter]) {
        [items addObject:[self localizedSummaryItemWithName:@"Footer Line 1"
                                                description:[self printInfoDescription:[self footerOneInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Footer Line 1 Alignment"
                                                description:[self alignmentDescription:[self footerOneAlignmentType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Footer Line 2"
                                                description:[self printInfoDescription:[self footerTwoInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Footer Line 2 Alignment"
                                                description:[self alignmentDescription:[self footerTwoAlignmentType]]]];
    }
    [items addObject:[self localizedSummaryItemWithName:@"Print Footer Separator"
                                            description:([self printsFooterSeparator] ? @"On" : @"Off")]];
    
    return items;
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// localizedSummaryItems で返す辞書を生成
- (NSDictionary *)localizedSummaryItemWithName:(NSString *)name description:(NSString *)description
// ------------------------------------------------------
{
    return @{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTable(name, CEPrintLocalizeTable, nil),
             NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTable(description, CEPrintLocalizeTable, nil)};
}


// ------------------------------------------------------
/// マージンを再計算する
- (void)updateVerticalOffset
// ------------------------------------------------------
{
    // ヘッダの高さ（文書を印刷しない高さ）を得る
    CGFloat headerHeight = 0;
    if ([self printsHeader]) {
        if ([self headerOneInfoType] != CENoPrintInfo) {
            headerHeight += kHeaderFooterLineHeight;
        }
        if ([self headerTwoInfoType] != CENoPrintInfo) {
            headerHeight += kHeaderFooterLineHeight;
        }
    }
    // ヘッダと本文との距離をセパレータも勘案して決定する（フッタは本文との間が開くことが多いため、入れない）
    if (headerHeight > 0) {
        headerHeight += (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultHeaderFooterFontSizeKey] - kHeaderFooterLineHeight;
        
        headerHeight += [self printsHeaderSeparator] ? kSeparatorPadding : kNoSeparatorPadding;
    } else {
        if ([self printsHeaderSeparator]) {
            headerHeight += kSeparatorPadding;
        }
    }
    
    // フッタの高さ（同）を得る
    CGFloat footerHeight = 0;
    if ([self printsFooter]) {
        if ([self footerOneInfoType] != CENoPrintInfo) {
            footerHeight += kHeaderFooterLineHeight;
        }
        if ([self footerTwoInfoType] != CENoPrintInfo) {
            footerHeight += kHeaderFooterLineHeight;
        }
    }
    if ((footerHeight == 0) && [self printsFooterSeparator]) {
        footerHeight += kSeparatorPadding;
    }
    
    // printView が flip しているので入れ替えている
    NSPrintInfo *printInfo = [self representedObject];
    [printInfo setTopMargin:kPrintHFVerticalMargin + footerHeight];
    [printInfo setBottomMargin:kPrintHFVerticalMargin + headerHeight];
    
    // プレビューの更新を依頼
    [self setReadyToDraw:YES];
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
/// マージンに影響するキーのセットを返す
- (NSSet *)keyPathsForValuesAffectingMargin
// ------------------------------------------------------
{
    return [NSSet setWithArray:@[@"printsHeader",
                                 @"headerOneInfoType",
                                 @"headerTwoInfoType",
                                 @"printsHeaderSeparator",
                                 @"printsFooter",
                                 @"footerOneInfoType",
                                 @"footerTwoInfoType",
                                 @"printsFooterSeparator"]];
}


// ------------------------------------------------------
/// テーマの一覧を更新する
- (void)updateThemeList
// ------------------------------------------------------
{
    [[self themePopup] removeAllItems];
    
    [[self themePopup] addItemWithTitle:NSLocalizedStringFromTable(@"Black and White", CEPrintLocalizeTable, nil)];
    
    [[[self themePopup] menu] addItem:[NSMenuItem separatorItem]];
    
    [[self themePopup] addItemWithTitle:NSLocalizedString(@"Theme", nil)];
    [[[self themePopup] itemWithTitle:NSLocalizedString(@"Theme", nil)] setAction:nil];
    
    NSArray *themeNames = [[CEThemeManager sharedManager] themeNames];
    for (NSString *themeName in themeNames) {
        [[self themePopup] addItemWithTitle:themeName];
        [[[self themePopup] lastItem] setIndentationLevel:1];
    }
    
    // 選択すべきテーマがなかったら白黒にする
    if (![themeNames containsObject:[self theme]]) {
        [[self themePopup] selectItemAtIndex:0];
    } else {
        [[self themePopup] selectItemWithTitle:[self theme]];
    }
}

@end
