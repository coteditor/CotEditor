/*
 ==============================================================================
 CEDocumentController
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-14 by nakamuxu
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

#import "CEDocumentController.h"
#import "CEEncodingManager.h"
#import "CEByteCountTransformer.h"
#import "constants.h"


@interface CEDocumentController ()

@property (nonatomic) BOOL showsHiddenFiles;

@property (nonatomic) IBOutlet NSView *openPanelAccessoryView;
@property (nonatomic) IBOutlet NSPopUpButton *accessoryEncodingMenu;


// readonly
@property (nonatomic, readwrite) NSStringEncoding accessorySelectedEncoding;

@end




#pragma mark -

@implementation CEDocumentController

#pragma mark NSDocumentController Methods

// ------------------------------------------------------
/// inizialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _accessorySelectedEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey];
    }
    return self;
}


// ------------------------------------------------------
/// check file before creating a new document instance
- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
// ------------------------------------------------------
{
    // display alert if file is enorm large
    NSUInteger fileSizeThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultLargeFileAlertThresholdKey];
    if (fileSizeThreshold > 0) {
        NSNumber *fileSize = nil;
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        
        if ([fileSize integerValue] > fileSizeThreshold) {
            CEByteCountTransformer *transformer = [[CEByteCountTransformer alloc] init];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” has a size of %@.", nil),
                                   [url lastPathComponent],
                                   [transformer transformedValue:fileSize]]];
            [alert setInformativeText:NSLocalizedString(@"Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Open", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            
            // cancel operation
            if ([alert runModal] == NSAlertSecondButtonReturn) {
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
                return nil;
            }
        }
    }
    
    return [super makeDocumentWithContentsOfURL:url ofType:typeName error:nil];
}


// ------------------------------------------------------
/// オープンパネルを開くときにエンコーディング指定メニューを付加する
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
// ------------------------------------------------------
{
    // エンコーディングメニューを初期化し、ビューをセット
    if (![self openPanelAccessoryView]) {
        [NSBundle loadNibNamed:@"OpenDocumentAccessory" owner:self];
    }
    [self buildEncodingPopupButton];
    [openPanel setAccessoryView:[self openPanelAccessoryView]];

    // 非表示ファイルも表示有無
    [openPanel setTreatsFilePackagesAsDirectories:[self showsHiddenFiles]];
    [openPanel setShowsHiddenFiles:[self showsHiddenFiles]];
    [self setShowsHiddenFiles:NO];  // reset flag

    return [super runModalOpenPanel:openPanel forTypes:extensions];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// ドキュメントを開く
- (IBAction)openHiddenDocument:(id)sender
// ------------------------------------------------------
{
    [self setShowsHiddenFiles:YES];

    [super openDocument:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// オープンパネルのエンコーディングメニューを再構築
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    NSArray *items = [[CEEncodingManager sharedManager] encodingMenuItems];
    NSMenu *menu = [[self accessoryEncodingMenu] menu];
    
    [menu removeAllItems];
    
    [menu addItemWithTitle:NSLocalizedString(@"Auto-Detect", nil) action:NULL keyEquivalent:@""];
    [[menu itemAtIndex:0] setTag:CEAutoDetectEncodingMenuItemTag];
    [menu addItem:[NSMenuItem separatorItem]];
    
    for (NSMenuItem *item in items) {
        [menu addItem:item];
    }
    
    [self resetAccessorySelectedEncoding];
}


// ------------------------------------------------------
/// エンコーディングメニューの選択を初期化
- (void)resetAccessorySelectedEncoding
// ------------------------------------------------------
{
    NSStringEncoding defaultEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey];
    
    [self setAccessorySelectedEncoding:defaultEncoding];
}

@end
