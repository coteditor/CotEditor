/*
 
 CEToolbarController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-01-07.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "CEToolbarController.h"
#import "CEEncodingManager.h"
#import "CESyntaxManager.h"
#import "CESyntaxStyle.h"
#import "CEDocument.h"
#import "Constants.h"

#import "NSString+CENewLine.h"


@interface CEToolbarController ()

@property (nonatomic, nullable, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *lineEndingPopupButton;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingPopupButton;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *syntaxPopupButton;
@property (nonatomic, nullable, weak) IBOutlet NSButton *shareButton;

@end




#pragma mark -

@implementation CEToolbarController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (NSString *keyPath in [self observedDocumentKeys]) {
        [_document removeObserver:self forKeyPath:keyPath];
    }
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    // setup share button
    [[self shareButton] sendActionOn:NSLeftMouseDownMask];
    
    [self buildEncodingPopupButton];
    [self buildSyntaxPopupButton];
    
    // observe popup menu line-up change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildEncodingPopupButton)
                                                 name:CEEncodingListDidUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxPopupButton)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxPopupButton)
                                                 name:CESyntaxHistoryDidUpdateNotification
                                               object:nil];
}


// ------------------------------------------------------
/// update popup button selection
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(lineEnding))]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf invalidateLineEndingSelection];
        });
        
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(encoding))] ||
               [keyPath isEqualToString:NSStringFromSelector(@selector(hasUTF8BOM))])
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf invalidateEncodingSelection];
        });
        
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(syntaxStyle))]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf invalidateSyntaxStyleSelection];
        });
    }
}



#pragma mark Public Accessors

// ------------------------------------------------------
/// set document to apply status
- (void)setDocument:(nullable CEDocument *)document
// ------------------------------------------------------
{
    for (NSString *keyPath in [self observedDocumentKeys]) {
        [[self document] removeObserver:self forKeyPath:keyPath];
    }
    
    _document = document;
    
    [self invalidateLineEndingSelection];
    [self invalidateEncodingSelection];
    [self invalidateSyntaxStyleSelection];
    [[self toolbar] validateVisibleItems];
    
    // observe document status change
    for (NSString *keyPath in [self observedDocumentKeys]) {
        [document addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// document's key paths to observe
- (nonnull NSArray<NSString *> *)observedDocumentKeys
// ------------------------------------------------------
{
    return @[NSStringFromSelector(@selector(lineEnding)),
             NSStringFromSelector(@selector(encoding)),
             NSStringFromSelector(@selector(hasUTF8BOM)),
             NSStringFromSelector(@selector(syntaxStyle))];
}


// ------------------------------------------------------
/// select item in the encoding popup menu
- (void)invalidateLineEndingSelection
// ------------------------------------------------------
{
    CENewLineType lineEnding = [[self document] lineEnding];
    
    [[self lineEndingPopupButton] selectItemAtIndex:lineEnding];
}


// ------------------------------------------------------
/// select item in the line ending menu
- (void)invalidateEncodingSelection
// ------------------------------------------------------
{
    NSInteger tag = [[self document] encoding];
    if ([[self document] hasUTF8BOM]) {
        tag *= -1;
    }
    
    [[self encodingPopupButton] selectItemWithTag:tag];
}


// ------------------------------------------------------
/// select item in the syntax style menu
- (void)invalidateSyntaxStyleSelection
// ------------------------------------------------------
{
    NSString *styleName = [[[self document] syntaxStyle] styleName];
    
    [[self syntaxPopupButton] selectItemWithTitle:styleName];
    if (![[self syntaxPopupButton] selectedItem]) {
        [[self syntaxPopupButton] selectItemAtIndex:0];  // select "None"
    }
}


// ------------------------------------------------------
/// build encoding popup item
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    [[CEEncodingManager sharedManager] updateChangeEncodingMenu:[[self encodingPopupButton] menu]];
    
    [self invalidateEncodingSelection];
}


// ------------------------------------------------------
/// build syntax style popup menu
- (void)buildSyntaxPopupButton
// ------------------------------------------------------
{
    NSArray<NSString *> *styleNames = [[CESyntaxManager sharedManager] styleNames];
    NSArray<NSString *> *recentStyleNames = [[CESyntaxManager sharedManager] recentStyleNames];
    
    [[self syntaxPopupButton] removeAllItems];
    
    [[[self syntaxPopupButton] menu] addItemWithTitle:NSLocalizedString(@"None", nil)
                                               action:@selector(changeSyntaxStyle:)
                                        keyEquivalent:@""];
    [[[self syntaxPopupButton] menu] addItem:[NSMenuItem separatorItem]];
    
    if ([recentStyleNames count] > 0) {
        NSMenuItem *titleItem = [[NSMenuItem alloc] init];
        [titleItem setTitle:NSLocalizedString(@"Recently Used", @"menu heading in syntax style list on toolbar popup")];
        [titleItem setEnabled:NO];
        [[[self syntaxPopupButton] menu] addItem:titleItem];
        
        for (NSString *styleName in recentStyleNames) {
            [[[self syntaxPopupButton] menu] addItemWithTitle:styleName
                                                       action:@selector(changeSyntaxStyle:)
                                                keyEquivalent:@""];
        }
        [[[self syntaxPopupButton] menu] addItem:[NSMenuItem separatorItem]];
    }
    
    for (NSString *styleName in styleNames) {
        [[[self syntaxPopupButton] menu] addItemWithTitle:styleName
                                                   action:@selector(changeSyntaxStyle:)
                                            keyEquivalent:@""];
    }
    
    [self invalidateSyntaxStyleSelection];
}

@end
