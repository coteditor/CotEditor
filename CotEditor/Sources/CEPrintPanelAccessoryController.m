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


// print setting keys
NSString *_Nonnull const CEPrintThemeKey = @"CEThemeName";
NSString *_Nonnull const CEPrintLineNumberKey = @"CEPrintLineNumber";
NSString *_Nonnull const CEPrintInvisiblesKey = @"CEPrintInvisibles";
NSString *_Nonnull const CEPrintHeaderKey = @"CEPrintHeader";
NSString *_Nonnull const CEPrimaryHeaderContentKey = @"CEPrimaryHeaderContent";
NSString *_Nonnull const CESecondaryHeaderContentKey = @"CESecondaryHeaderContent";
NSString *_Nonnull const CEPrimaryHeaderAlignmentKey = @"CEPrimaryHeaderAlignment";
NSString *_Nonnull const CESecondaryHeaderAlignmentKey = @"CESecondaryHeaderAlignment";
NSString *_Nonnull const CEPrintFooterKey = @"CEPrintFooter";
NSString *_Nonnull const CEPrimaryFooterContentKey = @"CEPrimaryFooterContent";
NSString *_Nonnull const CESecondaryFooterContentKey = @"CESecondaryFooterContent";
NSString *_Nonnull const CEPrimaryFooterAlignmentKey = @"CEPrimaryFooterAlignment";
NSString *_Nonnull const CESecondaryFooterAlignmentKey = @"CESecondaryFooterAlignment";


@interface CEPrintPanelAccessoryController ()

@property (nonatomic, nullable) IBOutlet NSPopUpButton *themePopup;


@property (nonatomic, nullable) NSString *theme;
@property (nonatomic) CELineNumberPrintMode lineNumberMode;
@property (nonatomic) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (nonatomic) BOOL printsHeader;
@property (nonatomic) CEPrintInfoType primaryHeaderContent;
@property (nonatomic) CEAlignmentType primaryHeaderAlignment;
@property (nonatomic) CEPrintInfoType secondaryHeaderContent;
@property (nonatomic) CEAlignmentType secondaryHeaderAlignment;

@property (nonatomic) BOOL printsFooter;
@property (nonatomic) CEPrintInfoType primaryFooterContent;
@property (nonatomic) CEAlignmentType primaryFooterAlignment;
@property (nonatomic) CEPrintInfoType secondaryFooterContent;
@property (nonatomic) CEAlignmentType secondaryFooterAlignment;

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
    self.primaryHeaderContent = [defaults integerForKey:CEDefaultPrimaryHeaderContentKey];
    self.primaryHeaderAlignment = [defaults integerForKey:CEDefaultPrimaryHeaderAlignmentKey];
    self.secondaryHeaderContent = [defaults integerForKey:CEDefaultSecondaryHeaderContentKey];
    self.secondaryHeaderAlignment = [defaults integerForKey:CEDefaultSecondaryHeaderAlignmentKey];
    
    self.printsFooter = [defaults boolForKey:CEDefaultPrintFooterKey];
    self.primaryFooterContent = [defaults integerForKey:CEDefaultPrimaryFooterContentKey];
    self.primaryFooterAlignment = [defaults integerForKey:CEDefaultPrimaryFooterAlignmentKey];
    self.secondaryFooterContent = [defaults integerForKey:CEDefaultSecondaryFooterContentKey];
    self.secondaryFooterAlignment = [defaults integerForKey:CEDefaultSecondaryFooterAlignmentKey];
    
    // 現在のテーマラインナップを反映させる
    [self updateThemeList];
}



#pragma mark Protocol

//=======================================================
// NSPrintPanelAccessorizing Protocol
//=======================================================

// ------------------------------------------------------
/// プレビューに影響するキーのセットを返す
- (nonnull NSSet<NSString *> *)keyPathsForValuesAffectingPreview
// ------------------------------------------------------
{
    return [NSSet setWithArray:@[@"theme",
                                 @"lineNumberMode",
                                 @"invisibleCharsMode",
                                 @"printsHeader",
                                 @"primaryHeaderContent",
                                 @"primaryHeaderAlignment",
                                 @"secondaryHeaderContent",
                                 @"secondaryHeaderAlignment",
                                 @"printsFooter",
                                 @"primaryFooterAlignment",
                                 @"primaryFooterContent",
                                 @"secondaryFooterAlignment",
                                 @"secondaryFooterContent",
                                 ]];
}


// ------------------------------------------------------
/// ローカライズ済みの設定説明を返す
-(nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)localizedSummaryItems
// ------------------------------------------------------
{
    NSMutableArray *items = [NSMutableArray array];
    NSString *description = @"";
    
    [items addObject:[self localizedSummaryItemWithName:@"Color"
                                            description:[self theme]]];
    
    switch ([self lineNumberMode]) {
        case CENoLinePrint:
            description = @"Don’t Print";
            break;
        case CESameAsDocumentLinePrint:
            description = @"Same as Document’s Setting";
            break;
        case CEDoLinePrint:
            description = @"Print";
            break;
    }
    [items addObject:[self localizedSummaryItemWithName:@"Line Number"
                                            description:description]];
    
    switch ([self invisibleCharsMode]) {
        case CENoInvisibleCharsPrint:
            description = @"Don’t Print";
            break;
        case CESameAsDocumentInvisibleCharsPrint:
            description = @"Same as Document’s Setting";
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
        [items addObject:[self localizedSummaryItemWithName:@"Primary Header"
                                                description:[self printInfoDescription:[self primaryHeaderContent]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Primary Header Alignment"
                                                description:[self alignmentDescription:[self primaryHeaderAlignment]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Secondary Header"
                                                description:[self printInfoDescription:[self secondaryHeaderContent]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Secondary Header Alignment"
                                                description:[self alignmentDescription:[self secondaryHeaderAlignment]]]];
    }
    
    [items addObject:[self localizedSummaryItemWithName:@"Print Footer"
                                            description:([self printsFooter] ? @"On" : @"Off")]];
    if ([self printsFooter]) {
        [items addObject:[self localizedSummaryItemWithName:@"Primary Footer"
                                                description:[self printInfoDescription:[self primaryFooterContent]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Primary Footer Alignment"
                                                description:[self alignmentDescription:[self primaryFooterAlignment]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Secondary Footer"
                                                description:[self printInfoDescription:[self secondaryFooterContent]]]];
        [items addObject:[self localizedSummaryItemWithName:@"Secondary Footer Alignment"
                                                description:[self alignmentDescription:[self secondaryFooterAlignment]]]];
    }
    
    return items;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// localizedSummaryItems で返す辞書を生成
- (nonnull NSDictionary<NSString *, NSString *> *)localizedSummaryItemWithName:(nonnull NSString *)name description:(nonnull NSString *)description
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
    
    NSArray<NSString *> *themeNames = [[CEThemeManager sharedManager] themeNames];
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
    return [NSString stringWithFormat:@"representedObject.dictionary.%@", key];
}



#pragma mark Setting Accessors

// ------------------------------------------------------
- (void)setTheme:(nullable NSString *)theme
// ------------------------------------------------------
{
    [self setValue:theme forKeyPath:[self settingsPathForKey:CEPrintThemeKey]];
}


// ------------------------------------------------------
- (nullable NSString *)theme
// ------------------------------------------------------
{
    return [self valueForKeyPath:[self settingsPathForKey:CEPrintThemeKey]];
}


// ------------------------------------------------------
- (void)setLineNumberMode:(CELineNumberPrintMode)lineNumberMode
// ------------------------------------------------------
{
    [self setValue:@(lineNumberMode) forKeyPath:[self settingsPathForKey:CEPrintLineNumberKey]];
}


// ------------------------------------------------------
- (CELineNumberPrintMode)lineNumberMode
// ------------------------------------------------------
{
    return (CELineNumberPrintMode)[[self valueForKeyPath:[self settingsPathForKey:CEPrintLineNumberKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setInvisibleCharsMode:(CEInvisibleCharsPrintMode)invisibleCharsMode
// ------------------------------------------------------
{
    [self setValue:@(invisibleCharsMode) forKeyPath:[self settingsPathForKey:CEPrintInvisiblesKey]];
}


// ------------------------------------------------------
- (CEInvisibleCharsPrintMode)invisibleCharsMode
// ------------------------------------------------------
{
    return (CEInvisibleCharsPrintMode)[[self valueForKeyPath:[self settingsPathForKey:CEPrintInvisiblesKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrintsHeader:(BOOL)printsHeader
// ------------------------------------------------------
{
    [self setValue:@(printsHeader) forKeyPath:[self settingsPathForKey:CEPrintHeaderKey]];
}


// ------------------------------------------------------
- (BOOL)printsHeader
// ------------------------------------------------------
{
    return [[self valueForKeyPath:[self settingsPathForKey:CEPrintHeaderKey]] boolValue];
}


// ------------------------------------------------------
- (void)setPrimaryHeaderContent:(CEPrintInfoType)primaryHeaderContent
// ------------------------------------------------------
{
    [self setValue:@(primaryHeaderContent) forKeyPath:[self settingsPathForKey:CEPrimaryHeaderContentKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)primaryHeaderContent
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEPrimaryHeaderContentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrimaryHeaderAlignment:(CEAlignmentType)primaryHeaderAlignment
// ------------------------------------------------------
{
    [self setValue:@(primaryHeaderAlignment) forKeyPath:[self settingsPathForKey:CEPrimaryHeaderAlignmentKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)primaryHeaderAlignment
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEPrimaryHeaderAlignmentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setSecondaryHeaderContent:(CEPrintInfoType)secondaryHeaderContent
// ------------------------------------------------------
{
    [self setValue:@(secondaryHeaderContent) forKeyPath:[self settingsPathForKey:CESecondaryHeaderContentKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)secondaryHeaderContent
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CESecondaryHeaderContentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setSecondaryHeaderAlignment:(CEAlignmentType)secondaryHeaderAlignment
// ------------------------------------------------------
{
    [self setValue:@(secondaryHeaderAlignment) forKeyPath:[self settingsPathForKey:CESecondaryHeaderAlignmentKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)secondaryHeaderAlignment
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CESecondaryHeaderAlignmentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrintsFooter:(BOOL)printsFooter
// ------------------------------------------------------
{
    [self setValue:@(printsFooter) forKeyPath:[self settingsPathForKey:CEPrintFooterKey]];
}


// ------------------------------------------------------
- (BOOL)printsFooter
// ------------------------------------------------------
{
    return [[self valueForKeyPath:[self settingsPathForKey:CEPrintFooterKey]] boolValue];
}


// ------------------------------------------------------
- (void)setPrimaryFooterContent:(CEPrintInfoType)primaryFooterContent
// ------------------------------------------------------
{
    [self setValue:@(primaryFooterContent) forKeyPath:[self settingsPathForKey:CEPrimaryFooterContentKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)primaryFooterContent
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CEPrimaryFooterContentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setPrimaryFooterAlignment:(CEAlignmentType)primaryFooterAlignment
// ------------------------------------------------------
{
    [self setValue:@(primaryFooterAlignment) forKeyPath:[self settingsPathForKey:CEPrimaryFooterAlignmentKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)primaryFooterAlignment
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CEPrimaryFooterAlignmentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setSecondaryFooterContent:(CEPrintInfoType)secondaryFooterContent
// ------------------------------------------------------
{
    [self setValue:@(secondaryFooterContent) forKeyPath:[self settingsPathForKey:CESecondaryFooterContentKey]];
}


// ------------------------------------------------------
- (CEPrintInfoType)secondaryFooterContent
// ------------------------------------------------------
{
    return (CEPrintInfoType)[[self valueForKeyPath:[self settingsPathForKey:CESecondaryFooterContentKey]] unsignedIntegerValue];
}


// ------------------------------------------------------
- (void)setSecondaryFooterAlignment:(CEAlignmentType)secondaryFooterAlignment
// ------------------------------------------------------
{
    [self setValue:@(secondaryFooterAlignment) forKeyPath:[self settingsPathForKey:CESecondaryFooterAlignmentKey]];
}


// ------------------------------------------------------
- (CEAlignmentType)secondaryFooterAlignment
// ------------------------------------------------------
{
    return (CEAlignmentType)[[self valueForKeyPath:[self settingsPathForKey:CESecondaryFooterAlignmentKey]] unsignedIntegerValue];
}

@end
