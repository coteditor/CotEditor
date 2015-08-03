/*
 
 CEPrintAccessoryViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-24.

 ------------------------------------------------------------------------------
 
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

#import "CEPrintPanelAccessoryController.h"
#import "CEThemeManager.h"


@interface CEPrintPanelAccessoryController ()

@property (nonatomic, nullable) IBOutlet NSPopUpButton *themePopup;


@property (readwrite, nonatomic, nonnull) NSString *theme;
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

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithNibName:@"PrintPanelAccessory" bundle:nil];
    if (self) {
        [self updateThemeList];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
        _lineNumberMode = [defaults integerForKey:CEDefaultPrintLineNumIndexKey];
        _invisibleCharsMode = [defaults integerForKey:CEDefaultPrintInvisibleCharIndexKey];
        _printsHeader = [defaults boolForKey:CEDefaultPrintHeaderKey];
        _headerOneInfoType = [defaults integerForKey:CEDefaultHeaderOneStringIndexKey];
        _headerOneAlignmentType = [defaults integerForKey:CEDefaultHeaderOneAlignIndexKey];
        _headerTwoInfoType = [defaults integerForKey:CEDefaultHeaderTwoStringIndexKey];
        _headerTwoAlignmentType = [defaults integerForKey:CEDefaultHeaderTwoAlignIndexKey];
        _printsHeaderSeparator = [defaults boolForKey:CEDefaultPrintHeaderSeparatorKey];
        _printsFooter = [defaults boolForKey:CEDefaultPrintFooterKey];
        _footerOneInfoType = [defaults integerForKey:CEDefaultFooterOneStringIndexKey];
        _footerOneAlignmentType = [defaults integerForKey:CEDefaultFooterOneAlignIndexKey];
        _footerTwoInfoType = [defaults integerForKey:CEDefaultFooterTwoStringIndexKey];
        _footerTwoAlignmentType = [defaults integerForKey:CEDefaultFooterTwoAlignIndexKey];
        _printsFooterSeparator = [defaults boolForKey:CEDefaultPrintFooterSeparatorKey];
        
        // テーマを使用する場合はセットしておく
        switch ([defaults integerForKey:CEDefaultPrintColorIndexKey]) {
            case CEBlackColorPrint:
                _theme = NSLocalizedString(@"Black and White", nil);
                break;
            case CESameAsDocumentColorPrint:
                _theme = [defaults stringForKey:CEDefaultThemeKey];
                break;
            default:
                _theme = [defaults stringForKey:CEDefaultPrintThemeKey];
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
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
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



#pragma mark Protocol

//=======================================================
// NSKeyValueObserving Protocol
//=======================================================

// ------------------------------------------------------
/// 監視しているキー値が変更された
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([[self keyPathsForValuesAffectingMargin] containsObject:keyPath]) {
        [self updateVerticalOffset];
    }
}


//=======================================================
// NSPrintPanelAccessorizing Protocol
//=======================================================

// ------------------------------------------------------
/// プレビューに影響するキーのセットを返す
- (nonnull NSSet *)keyPathsForValuesAffectingPreview
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
-(nonnull NSArray *)localizedSummaryItems
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
        [items addObject:[self localizedSummaryItemWithName:@"First Header Line"
                                                description:[self printInfoDescription:[self headerOneInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"First Header Line Alignment"
                                                description:[self alignmentDescription:[self headerOneAlignmentType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Second Header Line"
                                                description:[self printInfoDescription:[self headerTwoInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Second Header Line Alignment"
                                                description:[self alignmentDescription:[self headerTwoAlignmentType]]]];
    }
    [items addObject:[self localizedSummaryItemWithName:@"Print Header Separator"
                                            description:([self printsHeaderSeparator] ? @"On" : @"Off")]];
    
    [items addObject:[self localizedSummaryItemWithName:@"Print Footer"
                                            description:([self printsFooter] ? @"On" : @"Off")]];
    if ([self printsFooter]) {
        [items addObject:[self localizedSummaryItemWithName:@"First Footer Line"
                                                description:[self printInfoDescription:[self footerOneInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"First Footer Line Alignment"
                                                description:[self alignmentDescription:[self footerOneAlignmentType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Second Footer Line"
                                                description:[self printInfoDescription:[self footerTwoInfoType]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Second Footer Line Alignment"
                                                description:[self alignmentDescription:[self footerTwoAlignmentType]]]];
    }
    [items addObject:[self localizedSummaryItemWithName:@"Print Footer Separator"
                                            description:([self printsFooterSeparator] ? @"On" : @"Off")]];
    
    return items;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// localizedSummaryItems で返す辞書を生成
- (nonnull NSDictionary *)localizedSummaryItemWithName:(nonnull NSString *)name description:(nonnull NSString *)description
// ------------------------------------------------------
{
    return @{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedString(name, nil),
             NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedString(description, nil)};
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
- (nonnull NSString *)printInfoDescription:(CEPrintInfoType)type
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
- (nonnull NSString *)alignmentDescription:(CEAlignmentType)type
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
- (nonnull NSSet *)keyPathsForValuesAffectingMargin
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
    
    [[self themePopup] addItemWithTitle:NSLocalizedString(@"Black and White", nil)];
    
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
