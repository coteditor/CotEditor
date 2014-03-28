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

#pragma mark NSViewController Methods

//=======================================================
// NSViewController Protocol
//
//=======================================================

- (instancetype)init
{
    self = [super init];
    if (self) {
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
    return self;
}



#pragma mark Protocol

//=======================================================
// NSPrintPanelAccessorizing Protocol
//
//=======================================================

// ------------------------------------------------------
-(NSArray *)localizedSummaryItems
// ローカライズ済みの設定説明を返す
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



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (NSDictionary *)values
// プリンタローカル設定オブジェクトを返す
// ------------------------------------------------------
{
    return @{k_printColorIndex: @([self colorMode]),
             k_printLineNumIndex: @([self lineNumberMode]),
             k_printInvisibleCharIndex: @([self invisibleCharsMode]),
             k_printHeader: @([self printsHeader]),
             k_headerOneStringIndex: @([self headerOneInfoType]),
             k_headerOneAlignIndex: @([self headerOneAlignmentType]),
             k_headerTwoStringIndex: @([self headerTwoInfoType]),
             k_headerTwoAlignIndex: @([self headerTwoAlignmentType]),
             k_printHeaderSeparator: @([self printsHeaderSeparator]),
             k_printFooter: @([self printsFooter]),
             k_footerOneStringIndex: @([self footerOneInfoType]),
             k_footerOneAlignIndex: @([self footerOneAlignmentType]),
             k_footerTwoStringIndex: @([self footerTwoInfoType]),
             k_footerTwoAlignIndex: @([self footerTwoAlignmentType]),
             k_printFooterSeparator: @([self printsFooterSeparator])};
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (NSString *)printInfoDescription:(CEPrintInfoType)type
// ヘッダー／フッターの表示情報タイプから文字列を返す
// ------------------------------------------------------
{
    switch (type) {
        case CENoPrintInfo:
            return @"None";
            
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
- (NSString *)alignmentDescription:(CEAlignmentType)type
// アラインメントタイプから文字列を返す
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

@end
