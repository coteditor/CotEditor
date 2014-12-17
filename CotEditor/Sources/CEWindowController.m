/*
 ==============================================================================
 CEWindowController
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-13 by nakamuxu
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

#import "CEWindowController.h"
#import "CEWindow.h"
#import "CEDocumentController.h"
#import "CEStatusBarController.h"
#import "CESyntaxManager.h"
#import "NSString+ComposedCharacter.h"
#import "constants.h"


// Drawer identifier
static NSString *const InfoIdentifier = @"info";
static NSString *const IncompatibleIdentifier = @"incompatibleChar";

// document information keys
NSString *const CEDocumentEncodingKey = @"encoding";
NSString *const CEDocumentLineEndingsKey = @"lineEndings";
NSString *const CEDocumentCreationDateKey = @"creationDate";         // NSDate
NSString *const CEDocumentModificationDateKey = @"modificationDate"; // NSDate
NSString *const CEDocumentOwnerKey = @"owner";
NSString *const CEDocumentHFSTypeKey = @"type";
NSString *const CEDocumentHFSCreatorKey = @"creator";
NSString *const CEDocumentFinderLockKey = @"finderLock";
NSString *const CEDocumentPermissionKey = @"permission";
NSString *const CEDocumentFileSizeKey = @"fileSize";
// editor information keys
NSString *const CEDocumentLinesKey = @"lines";
NSString *const CEDocumentCharsKey = @"chars";
NSString *const CEDocumentWordsKey = @"words";
NSString *const CEDocumentLengthKey = @"length";
NSString *const CEDocumentByteLengthKey = @"byteLength";
NSString *const CEDocumentSelectedLinesKey = @"selectedLines";
NSString *const CEDocumentSelectedCharsKey = @"selectedChars";
NSString *const CEDocumentSelectedWordsKey = @"selectedWords";
NSString *const CEDocumentSelectedByteLengthKey = @"selectedByteLength";
NSString *const CEDocumentSelectedLengthKey = @"selectedLength";
NSString *const CEDocumentFormattedLinesKey = @"formattedLines";
NSString *const CEDocumentFormattedCharsKey = @"formattedChars";
NSString *const CEDocumentFormattedWordsKey = @"formattedWords";
NSString *const CEDocumentFormattedLengthKey = @"formattedLength";
NSString *const CEDocumentFormattedByteLengthKey = @"formattedByteLength";
NSString *const CEDocumentColumnKey = @"column";         // caret location from line head
NSString *const CEDocumentLocationKey = @"location";     // caret location from begining of document
NSString *const CEDocumentLineKey = @"line";             // current line
NSString *const CEDocumentUnicodeKey = @"unicode";       // Unicode of selected single character (or surrogate-pair)


@interface CEWindowController () <NSDrawerDelegate, NSTabViewDelegate>

@property (nonatomic) NSUInteger tabViewSelectedIndex; // ドロワーのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)
@property (nonatomic) BOOL needsRecolorWithBecomeKey; // ウィンドウがキーになったとき再カラーリングをするかどうかのフラグ

@property (nonatomic) NSTimer *infoUpdateTimer;
@property (nonatomic) NSTimer *incompatibleCharTimer;

@property (nonatomic) NSMutableDictionary *documentInfo;


// IBOutlets
@property (nonatomic) IBOutlet CEStatusBarController *statusBarController;
@property (nonatomic) IBOutlet NSObjectController *documentInfoController;
@property (nonatomic) IBOutlet NSArrayController *incompatibleCharsController;
@property (nonatomic) IBOutlet NSDrawer *drawer;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSTextField *listErrorTextField;
@property (nonatomic) IBOutlet NSNumberFormatter *infoNumberFormatter;

// readonly
@property (readwrite, nonatomic, weak) IBOutlet CEToolbarController *toolbarController;
@property (readwrite, nonatomic, weak) IBOutlet CEEditorWrapper *editor;

@end




#pragma mark -

@implementation CEWindowController

static NSTimeInterval infoUpdateInterval;
static NSTimeInterval incompatibleCharInterval;


#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// クラス初期化
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        infoUpdateInterval = [defaults doubleForKey:CEDefaultInfoUpdateIntervalKey];
        incompatibleCharInterval = [defaults doubleForKey:CEDefaultIncompatibleCharIntervalKey];
    });
}



#pragma mark NSWindowController Methods

//=======================================================
// NSWindowController method
//
//=======================================================

// ------------------------------------------------------
/// ウィンドウ表示の準備完了時、サイズを設定し文字列／不透明度をセット
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSSize size = NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultWindowWidthKey],
                             (CGFloat)[defaults doubleForKey:CEDefaultWindowHeightKey]);
    [[self window] setContentSize:size];
    
    [self setDocumentInfo:[NSMutableDictionary dictionary]];
    
    // 背景をセットアップ
    [(CEWindow *)[self window] setBackgroundAlpha:[defaults doubleForKey:CEDefaultWindowAlphaKey]];
    
    // ドキュメントオブジェクトに CEEditorWrapper インスタンスをセット
    [[self document] setEditor:[self editor]];
    // テキストを表示
    [[self document] setStringToEditor];
    
    // setup status bar
    [[self statusBarController] setShown:[defaults boolForKey:CEDefaultShowStatusBarKey] animate:NO];
    [[self statusBarController] setShowsReadOnly:![[self document] isWritable]];
    
    [self updateFileAttributesInfo];
    [self updateEncodingAndLineEndingsInfo:YES];
    
    // テキストビューへフォーカスを移動
    [[self window] makeFirstResponder:[[self editor] textView]];
    
    // シンタックス定義の変更を監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syntaxDidUpdate:)
                                                 name:CESyntaxDidUpdateNotification
                                               object:nil];
    
    // observe opacity setting change
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CEDefaultWindowAlphaKey
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultWindowAlphaKey];
    
    [self stopInfoUpdateTimer];
    [self stopIncompatibleCharTimer];
}


// ------------------------------------------------------
/// apply user defaults change
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:CEDefaultWindowAlphaKey]) {
        [(CEWindow *)[self window] setBackgroundAlpha:(CGFloat)[change[NSKeyValueChangeNewKey] doubleValue]];
    }
}

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleStatusBar:)) {
        NSString *title = [self showsStatusBar] ? @"Hide Status Bar" : @"Show Status Bar";
        [menuItem setTitle:NSLocalizedString(title, nil)];
    }
    
    return YES;
}


#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 文書情報ドロワー内容を更新すべきかを返す
- (BOOL)needsInfoDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:InfoIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// 非互換文字ドロワー内容を更新すべきかを返す
- (BOOL)needsIncompatibleCharDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:IncompatibleIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// 非互換文字リストを表示
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [self updateIncompatibleCharList];
    [[self tabView] selectTabViewItemWithIdentifier:IncompatibleIdentifier];
    [[self drawer] open];
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーの文書情報を更新
- (void)updateEditorStatusInfo:(BOOL)needsUpdateDrawer
// ------------------------------------------------------
{
    BOOL updatesStatusBar = [[self statusBarController] isShown];
    BOOL updatesDrawer = needsUpdateDrawer ? YES : [self needsInfoDrawerUpdate];
    
    if (!needsUpdateDrawer && (!updatesStatusBar && !updatesDrawer)) { return; }
    
    NSString *wholeString = ([[NSString newLineStringWithType:[[self document] lineEnding]] length] == 2) ? [[self document] stringForSave] : [[[self editor] string] copy];
    NSString *selectedString = [[self editor] substringWithSelection] ? : @"";
    NSStringEncoding encoding = [[self document] encoding];
    __block NSRange selectedRange = [[self editor] selectedRange];
    __block CEStatusBarController *statusBar = [self statusBarController];
    __weak typeof(self) weakSelf = self;
    
    // 別スレッドで情報を計算し、メインスレッドで controller に渡す
    NSMutableDictionary *documentInfo = [self documentInfo];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL countLineEnding = [defaults boolForKey:CEDefaultCountLineEndingAsCharKey];
        NSUInteger column = 0, currentLine = 0, length = [wholeString length], location = 0;
        NSUInteger numberOfLines = 0, numberOfSelectedLines = 0;
        NSUInteger numberOfChars = 0, numberOfSelectedChars = 0;
        NSUInteger numberOfWords = 0, numberOfSelectedWords = 0;
        
        // IM で変換途中の文字列は選択範囲としてカウントしない (2007.05.20)
        if ([[[self editor] textView] hasMarkedText]) {
            selectedRange.length = 0;
        }
        
        if (length > 0) {
            BOOL hasSelection = (selectedRange.length > 0);
            NSRange lineRange = [wholeString lineRangeForRange:selectedRange];
            column = selectedRange.location - lineRange.location;  // as length
            column = [[wholeString substringWithRange:NSMakeRange(lineRange.location, column)] numberOfComposedCharacters];
            
            for (NSUInteger index = 0; index < length; numberOfLines++) {
                if (index <= selectedRange.location) {
                    currentLine = numberOfLines + 1;
                }
                index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
            }
            
            // 単語数カウント
            if (updatesDrawer || [defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
                NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
                numberOfWords = [spellChecker countWordsInString:wholeString language:nil];
                if (hasSelection) {
                    numberOfSelectedWords = [spellChecker countWordsInString:selectedString
                                                                    language:nil];
                }
            }
            if (hasSelection) {
                numberOfSelectedLines = [[[selectedString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]
                                          componentsSeparatedByString:@"\n"] count];
            }
            
            // location カウント
            if (updatesDrawer || [defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
                NSString *locString = [wholeString substringToIndex:selectedRange.location];
                NSString *str = countLineEnding ? locString : [locString stringByDeletingNewLineCharacters];
                
                location = [str numberOfComposedCharacters];
            }
            
            // 文字数カウント
            if (updatesDrawer || [defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
                NSString *str = countLineEnding ? wholeString : [wholeString stringByDeletingNewLineCharacters];
                numberOfChars = [str numberOfComposedCharacters];
                if (hasSelection) {
                    str = countLineEnding ? selectedString : [selectedString stringByDeletingNewLineCharacters];
                    numberOfSelectedChars = [str numberOfComposedCharacters];
                }
            }
            
            // 改行コードをカウントしない場合は再計算
            if (!countLineEnding) {
                selectedRange.length = [[selectedString stringByDeletingNewLineCharacters] length];
                length = [[wholeString stringByDeletingNewLineCharacters] length];
            }
        }
        
        NSString *unicodeInfo;
        NSUInteger byteLength = 0, selectedByteLength = 0;
        if (updatesDrawer) {
            {
                if (selectedRange.length == 2) {
                    unichar firstChar = [wholeString characterAtIndex:selectedRange.location];
                    unichar secondChar = [wholeString characterAtIndex:selectedRange.location + 1];
                    if (CFStringIsSurrogateHighCharacter(firstChar) && CFStringIsSurrogateLowCharacter(secondChar)) {
                        UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(firstChar, secondChar);
                        unicodeInfo = [NSString stringWithFormat:@"U+%04tX", pair];
                    }
                }
                if (selectedRange.length == 1) {
                    unichar character = [wholeString characterAtIndex:selectedRange.location];
                    unicodeInfo = [NSString stringWithFormat:@"U+%.4X", character];
                }
            }
            
            byteLength = [wholeString lengthOfBytesUsingEncoding:encoding];
            selectedByteLength = [[wholeString substringWithRange:selectedRange]
                                  lengthOfBytesUsingEncoding:encoding];
        }
        
        // apply to UI
        dispatch_sync(dispatch_get_main_queue(), ^{
            documentInfo[CEDocumentLinesKey] = @(numberOfLines);
            documentInfo[CEDocumentCharsKey] = @(numberOfChars);
            documentInfo[CEDocumentLengthKey] = @(length);
            documentInfo[CEDocumentByteLengthKey] = @(byteLength);
            documentInfo[CEDocumentWordsKey] = @(numberOfWords);
            documentInfo[CEDocumentSelectedLinesKey] = @(numberOfSelectedLines);
            documentInfo[CEDocumentSelectedCharsKey] = @(numberOfSelectedChars);
            documentInfo[CEDocumentSelectedLengthKey] = @(selectedRange.length);
            documentInfo[CEDocumentSelectedByteLengthKey] = @(selectedByteLength);
            documentInfo[CEDocumentSelectedWordsKey] = @(numberOfSelectedWords);
            documentInfo[CEDocumentFormattedLinesKey] = [strongSelf formatCount:numberOfLines selected:numberOfSelectedLines];
            documentInfo[CEDocumentFormattedCharsKey] = [strongSelf formatCount:numberOfChars selected:numberOfSelectedChars];
            documentInfo[CEDocumentFormattedLengthKey] = [strongSelf formatCount:length selected:selectedRange.length];
            documentInfo[CEDocumentFormattedByteLengthKey] = [strongSelf formatCount:byteLength selected:selectedByteLength];
            documentInfo[CEDocumentFormattedWordsKey] = [strongSelf formatCount:numberOfWords selected:numberOfSelectedWords];
            documentInfo[CEDocumentLocationKey] = @(location);
            documentInfo[CEDocumentColumnKey] = @(column);
            documentInfo[CEDocumentLineKey] = @(currentLine);
            if (unicodeInfo) {
                documentInfo[CEDocumentUnicodeKey] = unicodeInfo;
            } else {
                [documentInfo removeObjectForKey:CEDocumentUnicodeKey];
            }
            
            if (updatesStatusBar) {
                [statusBar updateEditorStatus];
            }
        });
    });
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーの改行コード／エンコーディング表記を更新
- (void)updateEncodingAndLineEndingsInfo:(BOOL)needsUpdateDrawer
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [[self statusBarController] isShown];
    BOOL shouldUpdateDrawer = needsUpdateDrawer ? YES : [self needsInfoDrawerUpdate];
    
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    [self documentInfo][CEDocumentEncodingKey] = [[self document] currentIANACharSetName];
    [self documentInfo][CEDocumentLineEndingsKey] = [NSString newLineNameWithType:[[self document] lineEnding]];
    
    if (shouldUpdateStatusBar) {
        [[self statusBarController] updateDocumentStatus];
    }
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーのファイル情報を更新
- (void)updateFileAttributesInfo
// ------------------------------------------------------
{
    NSDictionary *attrs = [[self document] fileAttributes];
    
    if ([[self document] fileURL]) {
        [self documentInfo][CEDocumentCreationDateKey] = [attrs fileCreationDate];
        [self documentInfo][CEDocumentModificationDateKey] = [attrs fileModificationDate];
        [self documentInfo][CEDocumentFileSizeKey] = @([attrs fileSize]);
    } else {
        [[self documentInfo] removeObjectsForKeys:@[CEDocumentCreationDateKey,
                                                    CEDocumentModificationDateKey,
                                                    CEDocumentFileSizeKey]];
    }
    [self documentInfo][CEDocumentOwnerKey] = [attrs fileOwnerAccountName] ? : @"";
    [self documentInfo][CEDocumentPermissionKey] = [attrs filePosixPermissions] ? [NSString stringWithFormat:@"%tu", [attrs filePosixPermissions]] : @"";
    [self documentInfo][CEDocumentFinderLockKey] = NSLocalizedString([attrs fileIsImmutable] ? @"Yes" : @"No", nil);
    [self documentInfo][CEDocumentHFSTypeKey] = [attrs fileHFSTypeCode] ? NSFileTypeForHFSTypeCode([attrs fileHFSTypeCode]) : @"";
    [self documentInfo][CEDocumentHFSCreatorKey] = [attrs fileHFSCreatorCode] ? NSFileTypeForHFSTypeCode([attrs fileHFSCreatorCode]) : @"";
    
    [[self statusBarController] updateDocumentStatus];
}


// ------------------------------------------------------
/// 非互換文字更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupIncompatibleCharTimer
// ------------------------------------------------------
{
    if (![self needsIncompatibleCharDrawerUpdate]) { return; }
    
    if ([self incompatibleCharTimer]) {
        [[self incompatibleCharTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:incompatibleCharInterval]];
    } else {
        [self setIncompatibleCharTimer:[NSTimer scheduledTimerWithTimeInterval:incompatibleCharInterval
                                                                        target:self
                                                                      selector:@selector(updateIncompatibleCharListWithTimer:)
                                                                      userInfo:nil
                                                                       repeats:NO]];
    }
}


// ------------------------------------------------------
/// 文書情報更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupInfoUpdateTimer
// ------------------------------------------------------
{
    if ([self infoUpdateTimer]) {
        [[self infoUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:infoUpdateInterval]];
    } else {
        [self setInfoUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:infoUpdateInterval
                                                                  target:self
                                                                selector:@selector(updateEditorStatusInfoWithTimer:)
                                                                userInfo:nil
                                                                 repeats:NO]];
    }
}



#pragma mark Accessors

// ------------------------------------------------------
/// ステータスバーを表示するかどうかを返す
- (BOOL)showsStatusBar
// ------------------------------------------------------
{
    return [[self statusBarController] isShown];
}


// ------------------------------------------------------
/// ステータスバーを表示する／しないをセット
- (void)setShowsStatusBar:(BOOL)showsStatusBar
// ------------------------------------------------------
{
    if (![self statusBarController]) { return; }
    
    [[self statusBarController] setShown:showsStatusBar animate:YES];
    [[self toolbarController] toggleItemWithTag:CEToolbarShowStatusBarItemTag
                                          setOn:showsStatusBar];
    [self updateEncodingAndLineEndingsInfo:NO];
    
    if (![self infoUpdateTimer]) {
        [self updateEditorStatusInfo:NO];
    }
}


// ------------------------------------------------------
/// 文書への書き込み（ファイル上書き保存）が可能かどうかをセット
- (void)setWritable:(BOOL)isWritable
// ------------------------------------------------------
{
    if ([self statusBarController]) {
        [[self statusBarController] setShowsReadOnly:!isWritable];
    }
}
    


#pragma mark Protocol

//=======================================================
// OgreKit Protocol
//
//=======================================================

// ------------------------------------------------------
/// OgreKit method that passes the main textView.
- (void)tellMeTargetToFindIn:(id)sender
// ------------------------------------------------------
{
    OgreTextFinder *textFinder = (OgreTextFinder *)sender;
    [textFinder setTargetToFindIn:[[self editor] textView]];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSWindow)
//  <== mainWindow
//=======================================================

// ------------------------------------------------------
/// ウィンドウがキーになった
- (void)windowDidBecomeKey:(NSNotification *)notification
// ------------------------------------------------------
{
    // シートを表示していなければ、各種更新実行
    if ([[self window] attachedSheet] == nil) {
        // フラグがたっていたら、改めてスタイル名を指定し直して再カラーリングを実行
        if ([self needsRecolorWithBecomeKey]) {
            [self setNeedsRecolorWithBecomeKey:NO];
            [[self document] doSetSyntaxStyle:[[self editor] syntaxStyleName]];
        }
    }
}


// ------------------------------------------------------
/// save window state on application termination
- (void)window:(NSWindow *)window willEncodeRestorableState:(NSCoder *)state
// ------------------------------------------------------
{
    [state encodeBool:[[self statusBarController] isShown] forKey:CEDefaultShowStatusBarKey];
    [state encodeBool:[[self editor] showsNavigationBar] forKey:CEDefaultShowNavigationBarKey];
    [state encodeBool:[[self editor] showsLineNum] forKey:CEDefaultShowLineNumbersKey];
    [state encodeBool:[[self editor] showsPageGuide] forKey:CEDefaultShowPageGuideKey];
    [state encodeBool:[[self editor] showsInvisibles] forKey:CEDefaultShowInvisiblesKey];
    [state encodeBool:[[self editor] isVerticalLayoutOrientation] forKey:CEDefaultLayoutTextVerticalKey];
}


// ------------------------------------------------------
/// restore window state from the last session
- (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)state
// ------------------------------------------------------
{
    if ([state containsValueForKey:CEDefaultShowStatusBarKey]) {
        [[self statusBarController] setShown:[state decodeBoolForKey:CEDefaultShowStatusBarKey] animate:NO];
    }
    if ([state containsValueForKey:CEDefaultShowNavigationBarKey]) {
        [[self editor] setShowsNavigationBar:[state decodeBoolForKey:CEDefaultShowNavigationBarKey] animate:NO];
    }
    if ([state containsValueForKey:CEDefaultShowLineNumbersKey]) {
        [[self editor] setShowsLineNum:[state decodeBoolForKey:CEDefaultShowLineNumbersKey]];
    }
    if ([state containsValueForKey:CEDefaultShowPageGuideKey]) {
        [[self editor] setShowsPageGuide:[state decodeBoolForKey:CEDefaultShowPageGuideKey]];
    }
    if ([state containsValueForKey:CEDefaultShowInvisiblesKey]) {
        [[self editor] setShowsInvisibles:[state decodeBoolForKey:CEDefaultShowInvisiblesKey]];
    }
    if ([state containsValueForKey:CEDefaultLayoutTextVerticalKey]) {
        [[self editor] setVerticalLayoutOrientation:[state decodeBoolForKey:CEDefaultLayoutTextVerticalKey]];
    }
}



//=======================================================
// Delegate method (NSTabView)
//  <== tabView
//=======================================================

// ------------------------------------------------------
/// ドロワーのタブが切り替えられる直前に内容の更新を行う
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
// ------------------------------------------------------
{
    if ([[tabViewItem identifier] isEqualToString:InfoIdentifier]) {
        [self updateFileAttributesInfo];
        [self updateEditorStatusInfo:YES];
        [self updateEncodingAndLineEndingsInfo:YES];
    } else if ([[tabViewItem identifier] isEqualToString:IncompatibleIdentifier]) {
        [self updateIncompatibleCharList];
    }
}


//=======================================================
// Delegate method (NSDrawer)
//  <== drawer
//=======================================================

// ------------------------------------------------------
/// ドロワーが閉じたらテキストビューのマークアップをクリア
- (void)drawerDidClose:(NSNotification *)notification
// ------------------------------------------------------
{
    [[self editor] clearAllMarkup];
    // テキストビューの表示だけをクリアし、リストはそのまま
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ファイル情報を表示
- (IBAction)getInfo:(id)sender
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:InfoIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            // 情報の更新
            [self updateFileAttributesInfo];
            [self updateEditorStatusInfo:YES];
            [self updateEncodingAndLineEndingsInfo:YES];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:InfoIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:InfoIdentifier];
        }
    }
}


// ------------------------------------------------------
/// 変換不可文字列リストパネルを開く
- (IBAction)toggleIncompatibleCharList:(id)sender
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:IncompatibleIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            [self updateIncompatibleCharList];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:IncompatibleIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:IncompatibleIdentifier];
        }
    }
}


// ------------------------------------------------------
/// 文字列を選択
- (IBAction)selectIncompatibleRange:(id)sender
// ------------------------------------------------------
{
    NSArray *selectedIncompatibles = [[self incompatibleCharsController] selectedObjects];
    
    if ([selectedIncompatibles count] == 0) { return; }

    NSRange range = [selectedIncompatibles[0][CEIncompatibleRangeKey] rangeValue];
    NSTextView *textView = [[self editor] textView];
    
    [[self editor] setSelectedRange:range];
    [[self window] makeFirstResponder:textView];

    // 検索結果表示エフェクトを追加 (改行コードが CR/LF のときにずれるので range は使えない)
    [textView scrollRangeToVisible:[textView selectedRange]];
    [textView showFindIndicatorForRange:[textView selectedRange]];
}


// ------------------------------------------------------
/// ステータスバーの表示をトグルに切り替える
- (IBAction)toggleStatusBar:(id)sender
// ------------------------------------------------------
{
    [self setShowsStatusBar:![self showsStatusBar]];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 指定されたスタイルを適用していたら、リカラーフラグを立てる
- (void)syntaxDidUpdate:(NSNotification *)notification
// ------------------------------------------------------
{
    NSString *currentName = [[self editor] syntaxStyleName];
    NSString *oldName = [notification userInfo][CEOldNameKey];
    NSString *newName = [notification userInfo][CENewNameKey];
    
    if ([oldName isEqualToString:currentName]) {
        if ([oldName isEqualToString:newName]) {
            [[self editor] setSyntaxStyleName:newName recolorNow:NO];
        }
        if (![newName isEqualToString:NSLocalizedString(@"None", nil)]) {
            if ([[self window] isKeyWindow]) {
                [[self document] doSetSyntaxStyle:newName];
            } else {
                [self setNeedsRecolorWithBecomeKey:YES];
            }
        }
    }
}


// ------------------------------------------------------
/// 選択範囲内の情報も併記するドロワー用情報のフォーマット
- (NSString *)formatCount:(NSUInteger)count selected:(NSUInteger)selectedCount
// ------------------------------------------------------
{
    NSNumberFormatter *formatter = [self infoNumberFormatter];
    
    if (selectedCount > 0) {
        return [NSString stringWithFormat:@"%@ (%@)",
                [formatter stringFromNumber:@(count)], [formatter stringFromNumber:@(selectedCount)]];
    } else {
        return [NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(count)]];
    }
}


// ------------------------------------------------------
/// 非互換文字リストを更新
- (void)updateIncompatibleCharList
// ------------------------------------------------------
{
    NSArray *contents = [[self document] findCharsIncompatibleWithEncoding:[[self document] encoding]];
    
    NSMutableArray *ranges = [NSMutableArray array];
    for (NSDictionary *incompatible in contents) {
        [ranges addObject:incompatible[CEIncompatibleRangeKey]];
    }
    [[self editor] clearAllMarkup];
    [[self editor] markupRanges:ranges];
    
    
    [[self listErrorTextField] setHidden:([contents count] > 0)]; // リストが取得できなかった時のメッセージを表示
    [[self incompatibleCharsController] setContent:contents];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、情報更新
- (void)updateEditorStatusInfoWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopInfoUpdateTimer];
    [self updateEditorStatusInfo:NO];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、非互換文字情報更新
- (void)updateIncompatibleCharListWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopIncompatibleCharTimer];
    [self updateIncompatibleCharList];
}


// ------------------------------------------------------
/// 文書情報更新タイマーを停止
- (void)stopInfoUpdateTimer
// ------------------------------------------------------
{
    if ([self infoUpdateTimer]) {
        [[self infoUpdateTimer] invalidate];
        [self setInfoUpdateTimer:nil];
    }
}


// ------------------------------------------------------
/// 非互換文字情報更新タイマーを停止
- (void)stopIncompatibleCharTimer
// ------------------------------------------------------
{
    if ([self incompatibleCharTimer]) {
        [[self incompatibleCharTimer] invalidate];
        [self setIncompatibleCharTimer:nil];
    }
}

@end
