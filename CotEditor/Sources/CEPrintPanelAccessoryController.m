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
#import "Constants.h"


@interface CEPrintPanelAccessoryController ()

@property (nonatomic, nullable) IBOutlet NSPopUpButton *themePopup;


@property (nonatomic, nullable) NSString *theme;
@property (nonatomic) CELineNumberPrintMode lineNumberMode;
@property (nonatomic) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (nonatomic) BOOL printsHeader;
@property (nonatomic) CEPrintInfoType headerOneInfoType;
@property (nonatomic) CEAlignmentType headerOneAlignmentType;
@property (nonatomic) CEPrintInfoType headerTwoInfoType;
@property (nonatomic) CEAlignmentType headerTwoAlignmentType;

@property (nonatomic) BOOL printsFooter;
@property (nonatomic) CEPrintInfoType footerOneInfoType;
@property (nonatomic) CEAlignmentType footerOneAlignmentType;
@property (nonatomic) CEPrintInfoType footerTwoInfoType;
@property (nonatomic) CEAlignmentType footerTwoAlignmentType;

@end




#pragma mark -

@implementation CEPrintPanelAccessoryController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithNibName:@"PrintPanelAccessory" bundle:nil];
}


// ------------------------------------------------------
/// printInfoがセットされた （新たにプリントシートが表示される）
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // テーマを使用する場合はセットしておく
    switch ([defaults integerForKey:CEDefaultPrintColorIndexKey]) {
        case CEBlackColorPrint:
            self.theme = NSLocalizedString(@"Black and White", nil);
            break;
        case CESameAsDocumentColorPrint:
            self.theme = [defaults stringForKey:CEDefaultThemeKey];
            break;
        default:
            self.theme = [defaults stringForKey:CEDefaultPrintThemeKey];
    }
    
    self.lineNumberMode = [defaults integerForKey:CEDefaultPrintLineNumIndexKey];
    self.invisibleCharsMode = [defaults integerForKey:CEDefaultPrintInvisibleCharIndexKey];
    
    self.printsHeader = [defaults boolForKey:CEDefaultPrintHeaderKey];
    self.headerOneInfoType = [defaults integerForKey:CEDefaultHeaderOneStringIndexKey];
    self.headerOneAlignmentType = [defaults integerForKey:CEDefaultHeaderOneAlignIndexKey];
    self.headerTwoInfoType = [defaults integerForKey:CEDefaultHeaderTwoStringIndexKey];
    self.headerTwoAlignmentType = [defaults integerForKey:CEDefaultHeaderTwoAlignIndexKey];
    
    self.printsFooter = [defaults boolForKey:CEDefaultPrintFooterKey];
    self.footerOneInfoType = [defaults integerForKey:CEDefaultFooterOneStringIndexKey];
    self.footerOneAlignmentType = [defaults integerForKey:CEDefaultFooterOneAlignIndexKey];
    self.footerTwoInfoType = [defaults integerForKey:CEDefaultFooterTwoStringIndexKey];
    self.footerTwoAlignmentType = [defaults integerForKey:CEDefaultFooterTwoAlignIndexKey];
    
    // 現在のテーマラインナップを反映させる
    [self updateThemeList];
}



#pragma mark Protocol

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
                                 @"headerOneInfoType",
                                 @"headerOneAlignmentType",
                                 @"headerTwoInfoType",
                                 @"headerTwoAlignmentType",
                                 @"printsFooter",
                                 @"footerOneAlignmentType",
                                 @"footerOneInfoType",
                                 @"footerTwoAlignmentType",
                                 @"footerTwoInfoType",
                                 ]];
}


// ------------------------------------------------------
/// ローカライズ済みの設定説明を返す
-(nonnull NSArray *)localizedSummaryItems
// ------------------------------------------------------
{
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


// ------------------------------------------------------
/// return keyPath to the given setting key
- (nonnull NSString *)settingsPathForKey:(nonnull NSString *)key;
// ------------------------------------------------------
{
    return [NSString stringWithFormat:@"representedObject.printSettings.%@", key];
}



#pragma mark Setting Accessors

// ------------------------------------------------------
- (void)setTheme:(nullable NSString *)theme
// ------------------------------------------------------
{
    [self setValue:theme forKeyPath:[self settingsPathForKey:CEDefaultPrintThemeKey]];
}


// ------------------------------------------------------
- (nullable NSString *)theme
// ------------------------------------------------------
{
    return [self valueForKeyPath:[self settingsPathForKey:CEDefaultPrintThemeKey]];
}


// ------------------------------------------------------
- (void)setLineNumberMode:(CELineNumberPrintMode)lineNumberMode
// ------------------------------------------------------
{
    [self setValue:@(lineNumberMode) forKeyPath:[self settingsPathForKey:CEDefaultPrintLineNumIndexKey]];
}


// ------------------------------------------------------
- (CELineNumberPrintMode)lineNumberMode
// ------------------------------------------------------
{
    return (CELineNumberPrintMode)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultPrintLineNumIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setInvisibleCharsMode:(CEInvisibleCharsPrintMode)invisibleCharsMode
// ------------------------------------------------------
{
    [self setValue:@(invisibleCharsMode) forKeyPath:[self settingsPathForKey:CEDefaultPrintInvisibleCharIndexKey]];
}


// ------------------------------------------------------
- (CEInvisibleCharsPrintMode)invisibleCharsMode
// ------------------------------------------------------
{
    return (CEInvisibleCharsPrintMode)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultPrintInvisibleCharIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrintsHeader:(BOOL)printsHeader
// ------------------------------------------------------
{
    [self setValue:@(printsHeader) forKeyPath:[self settingsPathForKey:CEDefaultPrintHeaderKey]];
}


// ------------------------------------------------------
- (BOOL)printsHeader
// ------------------------------------------------------
{
    return [[self valueForKeyPath:[self settingsPathForKey:CEDefaultPrintHeaderKey]] boolValue];
}


// ------------------------------------------------------
- (void)setHeaderOneInfoType:(CEPrintInfoType)headerOneInfoType
// ------------------------------------------------------
{
    [self setValue:@(headerOneInfoType) forKeyPath:[self settingsPathForKey:CEDefaultHeaderOneStringIndexKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)headerOneInfoType
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultHeaderOneStringIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setHeaderOneAlignmentType:(CEAlignmentType)headerOneAlignmentType
// ------------------------------------------------------
{
    [self setValue:@(headerOneAlignmentType) forKeyPath:[self settingsPathForKey:CEDefaultHeaderOneAlignIndexKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)headerOneAlignmentType
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultHeaderOneAlignIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setHeaderTwoInfoType:(CEPrintInfoType)headerTwoInfoType
// ------------------------------------------------------
{
    [self setValue:@(headerTwoInfoType) forKeyPath:[self settingsPathForKey:CEDefaultHeaderTwoStringIndexKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)headerTwoInfoType
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultHeaderTwoStringIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setHeaderTwoAlignmentType:(CEAlignmentType)headerTwoAlignmentType
// ------------------------------------------------------
{
    [self setValue:@(headerTwoAlignmentType) forKeyPath:[self settingsPathForKey:CEDefaultHeaderTwoAlignIndexKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)headerTwoAlignmentType
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultHeaderTwoAlignIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrintsFooter:(BOOL)printsFooter
// ------------------------------------------------------
{
    [self setValue:@(printsFooter) forKeyPath:[self settingsPathForKey:CEDefaultPrintFooterKey]];
}


// ------------------------------------------------------
- (BOOL)printsFooter
// ------------------------------------------------------
{
    return [[self valueForKeyPath:[self settingsPathForKey:CEDefaultPrintFooterKey]] boolValue];
}


// ------------------------------------------------------
- (void)setFooterOneInfoType:(CEPrintInfoType)footerOneInfoType
// ------------------------------------------------------
{
    [self setValue:@(footerOneInfoType) forKeyPath:[self settingsPathForKey:CEDefaultFooterOneStringIndexKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)footerOneInfoType
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultFooterOneStringIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setFooterOneAlignmentType:(CEAlignmentType)footerOneAlignmentType
// ------------------------------------------------------
{
    [self setValue:@(footerOneAlignmentType) forKeyPath:[self settingsPathForKey:CEDefaultFooterOneAlignIndexKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)footerOneAlignmentType
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultFooterOneAlignIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setFooterTwoInfoType:(CEPrintInfoType)footerTwoInfoType
// ------------------------------------------------------
{
    [self setValue:@(footerTwoInfoType) forKeyPath:[self settingsPathForKey:CEDefaultFooterTwoStringIndexKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)footerTwoInfoType
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultFooterTwoStringIndexKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setFooterTwoAlignmentType:(CEAlignmentType)footerTwoAlignmentType
// ------------------------------------------------------
{
    [self setValue:@(footerTwoAlignmentType) forKeyPath:[self settingsPathForKey:CEDefaultFooterTwoAlignIndexKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)footerTwoAlignmentType
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEDefaultFooterTwoAlignIndexKey]] unsignedIntegerValue];
}

@end
