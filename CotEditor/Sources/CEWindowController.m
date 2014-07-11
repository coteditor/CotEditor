/*
=================================================
CEWindowController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13
 
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

#import "CEWindowController.h"
#import "CEDocumentController.h"
#import "CEStatusBarView.h"
#import "CESyntaxManager.h"
#import "NSString+ComposedCharacter.h"
#import "constants.h"


@interface CEWindowController ()

@property (nonatomic) NSUInteger tabViewSelectedIndex; // ドローワのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)
@property (nonatomic) BOOL recolorWithBecomeKey; // ウィンドウがキーになったとき再カラーリングをするかどうかのフラグ

@property (nonatomic) NSTimer *infoUpdateTimer;
@property (nonatomic) NSTimer *incompatibleCharTimer;


// document information (for binding in drawer)
@property (nonatomic, copy) NSString *encodingInfo;    // encoding of document
@property (nonatomic, copy) NSString *lineEndingsInfo; // line endings of document
@property (nonatomic, copy) NSString *singleCharInfo;  // Unicode of selected single character (or surrogate-pair)
@property (nonatomic, copy) NSString *createdInfo;
@property (nonatomic, copy) NSString *modificatedInfo;
@property (nonatomic, copy) NSString *ownerInfo;
@property (nonatomic, copy) NSString *typeInfo;
@property (nonatomic, copy) NSString *creatorInfo;
@property (nonatomic, copy) NSString *finderLockInfo;
@property (nonatomic, copy) NSString *permissionInfo;
@property (nonatomic) NSNumber *fileSizeInfo;
@property (nonatomic, copy) NSString *linesInfo;
@property (nonatomic, copy) NSString *charsInfo;
@property (nonatomic, copy) NSString *lengthInfo;
@property (nonatomic, copy) NSString *wordsInfo;
@property (nonatomic, copy) NSString *byteLengthInfo;
@property (nonatomic) NSUInteger columnInfo;           // caret location from line head
@property (nonatomic) NSUInteger locationInfo;         // caret location from begining ob document
@property (nonatomic) NSUInteger lineInfo;             // current line

// IBOutlets
@property (nonatomic, weak) IBOutlet CEStatusBarView *statusBar;
@property (nonatomic) IBOutlet NSArrayController *listController;
@property (nonatomic) IBOutlet NSDrawer *drawer;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *tabViewSelectionPopUpButton;
@property (nonatomic, weak) IBOutlet NSTableView *listTableView;
@property (nonatomic, weak) IBOutlet NSTextField *listErrorTextField;
@property (nonatomic) IBOutlet NSNumberFormatter *infoNumberFormatter;

// readonly
@property (nonatomic, weak, readwrite) IBOutlet CEToolbarController *toolbarController;
@property (nonatomic, weak, readwrite) IBOutlet CEEditorView *editorView;

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
        
        infoUpdateInterval = [defaults doubleForKey:k_key_infoUpdateInterval];
        incompatibleCharInterval = [defaults doubleForKey:k_key_incompatibleCharInterval];
    });
}



#pragma mark NSWindowController Methods

//=======================================================
// NSWindowController method
//
//=======================================================

// ------------------------------------------------------
/// クラス初期化
- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    if (self) {
        [self setIsWritable:YES];
        [self setIsAlertedNotWritable:NO];
    }
    return self;
}

// ------------------------------------------------------
/// ウィンドウ表示の準備完了時、サイズを設定し文字列／不透明度をセット
- (void)windowDidLoad
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSSize size = NSMakeSize((CGFloat)[defaults doubleForKey:k_key_windowWidth],
                             (CGFloat)[defaults doubleForKey:k_key_windowHeight]);
    [[self window] setContentSize:size];
    
    // 背景をセットアップ
    [self setAlpha:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]];
    [[self window] setBackgroundColor:[NSColor clearColor]]; // ウィンドウ背景色に透明色をセット
    
    // ドキュメントオブジェクトに CEEditorView インスタンスをセット
    [[self document] setEditorView:[self editorView]];
    // デフォルト改行コードをセット
    [[self document] setLineEndingCharToView:[defaults integerForKey:k_key_defaultLineEndCharCode]];
    // テキストを表示
    [[self document] setStringToEditorView];
    
    // シンタックス定義の変更を監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syntaxDidUpdate:)
                                                 name:CESyntaxDidUpdateNotification
                                               object:nil];
    
    // observe opacity setting change
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:k_key_windowAlpha
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:k_key_windowAlpha];
    
    [self stopInfoUpdateTimer];
    [self stopIncompatibleCharTimer];
}


// ------------------------------------------------------
/// apply user defaults change
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:k_key_windowAlpha]) {
        [self setAlpha:(CGFloat)[change[NSKeyValueChangeNewKey] doubleValue]];
    }
}

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleShowStatusBar:)) {
        NSString *title = [self showStatusBar] ? @"Hide Status Bar" : @"Show Status Bar";
        [menuItem setTitle:title];
    }
    
    return YES;
}


#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 文書情報ドローワ内容を更新すべきかを返す
- (BOOL)needsInfoDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// 非互換文字ドローワ内容を更新すべきかを返す
- (BOOL)needsIncompatibleCharDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// すべての文書情報を更新
- (void)updateFileAttrsInformation
// ------------------------------------------------------
{
    NSDictionary *fileAttributes = [[self document] fileAttributes];

    [self setCreatorInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSCreatorCode])];
    [self setTypeInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSTypeCode])];
    [self setCreatedInfo:[[fileAttributes fileCreationDate] description]];
    [self setModificatedInfo:[[fileAttributes fileModificationDate] description]];
    [self setOwnerInfo:[fileAttributes fileOwnerAccountName]];
    
    NSString *finderLockInfo = [fileAttributes fileIsImmutable] ? NSLocalizedString(@"ON", nil) : nil;
    [self setFinderLockInfo:finderLockInfo];
    [self setPermissionInfo:[NSString stringWithFormat:@"%tu", [fileAttributes filePosixPermissions]]];
    NSNumber *beforeFileSize = [self fileSizeInfo];
    [self setFileSizeInfo:@([fileAttributes fileSize])];
    if (![beforeFileSize isEqualToNumber:[self fileSizeInfo]]) {
        [self updateLineEndingsInStatusAndInfo:false];
    }
}


// ------------------------------------------------------
/// 変換不可文字列リストを更新
- (void)updateIncompatibleCharList
// ------------------------------------------------------
{
    NSArray *contents = [[self document] findCharsIncompatibleWithEncoding:[[self document] encoding]];
    
    [self markupIncompatibleChars:contents];

    [[self listErrorTextField] setHidden:([contents count] > 0)]; // リストが取得できなかった時のメッセージを表示
    [[self listController] setContent:contents];
}


// ------------------------------------------------------
/// 非互換文字リストを表示
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [self updateIncompatibleCharList];
    [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
    [[self drawer] open];
}


// ------------------------------------------------------
/// テキストビューの不透明度を返す
- (CGFloat)alpha
// ------------------------------------------------------
{
    return [[[self editorView] textView] backgroundAlpha];
}

// ------------------------------------------------------
/// テキストビューの不透明度を変更する
- (void)setAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    CGFloat sanitizedAlpha = alpha;
    
    sanitizedAlpha = MAX(sanitizedAlpha, 0.2);
    sanitizedAlpha = MIN(sanitizedAlpha, 1.0);
    
    [[self window] setOpaque:(sanitizedAlpha == 1.0)];
    [[[self editorView] splitView] setAllBackgroundColorWithAlpha:sanitizedAlpha];
    [[[self window] contentView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
/// ステータスバーを表示するかどうかを返す
- (BOOL)showStatusBar
// ------------------------------------------------------
{
    return [[self statusBar] showStatusBar];
}


// ------------------------------------------------------
/// ステータスバーを表示する／しないをセット
- (void)setShowStatusBar:(BOOL)showStatusBar
// ------------------------------------------------------
{
    if (![self statusBar]) { return; }
    
    [[self statusBar] setShowStatusBar:showStatusBar];
    [[self toolbarController] toggleItemWithIdentifier:k_showStatusBarItemID setOn:showStatusBar];
    [self updateLineEndingsInStatusAndInfo:NO];
    
    if (![self infoUpdateTimer]) {
        [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
    }
}


// ------------------------------------------------------
/// 文書への書き込み（ファイル上書き保存）が可能かどうかをセット
- (void)setIsWritable:(BOOL)isWritable
// ------------------------------------------------------
{
    _isWritable = isWritable;
    
    if ([self statusBar]) {
        [[self statusBar] setShowsReadOnlyIcon:!isWritable];
    }
}


// ------------------------------------------------------
/// 書き込み禁止アラートを表示
- (void)alertForNotWritable
// ------------------------------------------------------
{
    if ([self isWritable] || [self isAlertedNotWritable]) { return; }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_showAlertForNotWritable]) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"The file is not writable.", nil)];
        [alert setInformativeText:NSLocalizedString(@"You may not be able to save your changes, but you will be able to save a copy somewhere else.", nil)];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:NULL
                            contextInfo:NULL];
    }
    [self setIsAlertedNotWritable:YES];
}


// ------------------------------------------------------
/// ドローワの文書情報を更新
- (void)updateDocumentInfoStringWithDrawerForceUpdate:(BOOL)doUpdate
// ------------------------------------------------------
{
    BOOL updatesStatusBar = [[self statusBar] showStatusBar];
    BOOL updatesDrawer = doUpdate ? YES : [self needsInfoDrawerUpdate];
    
    if (!updatesStatusBar && !updatesDrawer) { return; }
    
    NSString *textViewString = [[self editorView] string];
    NSString *wholeString = ([[self editorView] lineEndingCharacter] == OgreCrLfNewlineCharacter) ? [[self editorView] stringForSave] : textViewString;
    NSStringEncoding encoding = [[self document] encoding];
    __block NSRange selectedRange = [[self editorView] selectedRange];
    __block CEStatusBarView *statusBar = [self statusBar];
    __block typeof(self) blockSelf = self;
    
    // 別スレッドで情報を計算し、メインスレッドで drawer と statusBar に渡す
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL countLineEnding = [defaults boolForKey:k_key_countLineEndingAsChar];
        NSUInteger column = 0, currentLine = 0, length = [wholeString length], location = 0;
        NSUInteger numberOfLines = 0, numberOfSelectedLines = 0;
        NSUInteger numberOfChars = 0, numberOfSelectedChars = 0;
        NSUInteger numberOfWords = 0, numberOfSelectedWords = 0;
        
        // IM で変換途中の文字列は選択範囲としてカウントしない (2007.05.20)
        if ([[[self editorView] textView] hasMarkedText]) {
            selectedRange.length = 0;
        }
        
        if (length > 0) {
            BOOL hasSelection = (selectedRange.length > 0);
            NSString *selectedString = hasSelection ? [textViewString substringWithRange:selectedRange] : @"";
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
            if (updatesDrawer || [defaults boolForKey:k_key_showStatusBarWords]) {
                NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
                numberOfWords = [spellChecker countWordsInString:wholeString language:nil];
                if (hasSelection) {
                    numberOfSelectedWords = [spellChecker countWordsInString:selectedString
                                                                    language:nil];
                }
            }
            if (hasSelection) {
                numberOfSelectedLines = [[selectedString componentsSeparatedByString:@"\n"] count];
            }
            
            // location カウント
            if (updatesDrawer || [defaults boolForKey:k_key_showStatusBarLocation]) {
                NSString *locString = [wholeString substringToIndex:selectedRange.location];
                NSString *str = countLineEnding ? locString : [OGRegularExpression chomp:locString];
                
                location = [str numberOfComposedCharacters];
            }
            
            // 文字数カウント
            if (updatesDrawer || [defaults boolForKey:k_key_showStatusBarChars]) {
                NSString *str = countLineEnding ? wholeString : [OGRegularExpression chomp:wholeString];
                numberOfChars = [str numberOfComposedCharacters];
                if (hasSelection) {
                    str = countLineEnding ? selectedString : [OGRegularExpression chomp:selectedString];
                    numberOfSelectedChars = [str numberOfComposedCharacters];
                }
            }
            
            // 改行コードをカウントしない場合は再計算
            if (!countLineEnding) {
                selectedRange.length = [[OGRegularExpression chomp:selectedString] length];
                length = [[OGRegularExpression chomp:wholeString] length];
            }
        }
        
        NSString *singleCharInfo;
        NSUInteger byteLength = 0, selectedByteLength = 0;
        if (updatesDrawer) {
            {
                if (selectedRange.length == 2) {
                    unichar firstChar = [wholeString characterAtIndex:selectedRange.location];
                    unichar secondChar = [wholeString characterAtIndex:selectedRange.location + 1];
                    if (CFStringIsSurrogateHighCharacter(firstChar) && CFStringIsSurrogateLowCharacter(secondChar)) {
                        UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(firstChar, secondChar);
                        singleCharInfo = [NSString stringWithFormat:@"U+%04tX", pair];
                    }
                }
                if (selectedRange.length == 1) {
                    unichar character = [wholeString characterAtIndex:selectedRange.location];
                    singleCharInfo = [NSString stringWithFormat:@"U+%.4X", character];
                }
            }
            
            byteLength = [wholeString lengthOfBytesUsingEncoding:encoding];
            selectedByteLength = [[wholeString substringWithRange:selectedRange]
                                  lengthOfBytesUsingEncoding:encoding];
        }
        
        // apply to UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (updatesStatusBar) {
                [statusBar setLinesInfo:numberOfLines];
                [statusBar setSelectedLinesInfo:numberOfSelectedLines];
                [statusBar setCharsInfo:numberOfChars];
                [statusBar setSelectedCharsInfo:numberOfSelectedChars];
                [statusBar setLengthInfo:length];
                [statusBar setSelectedLengthInfo:selectedRange.length];
                [statusBar setWordsInfo:numberOfWords];
                [statusBar setSelectedWordsInfo:numberOfSelectedWords];
                [statusBar setLocationInfo:location];
                [statusBar setLineInfo:currentLine];
                [statusBar setColumnInfo:column];
                [statusBar updateLeftField];
            }
            if (updatesDrawer) {
                [blockSelf setLinesInfo:numberOfLines selected:numberOfSelectedLines];
                [blockSelf setCharsInfo:numberOfChars selected:numberOfSelectedChars];
                [blockSelf setLengthInfo:length selected:selectedRange.length];
                [blockSelf setByteLengthInfo:byteLength selected:selectedByteLength];
                [blockSelf setWordsInfo:numberOfWords selected:numberOfSelectedWords];
                [blockSelf setLocationInfo:location];
                [blockSelf setColumnInfo:column];
                [blockSelf setLineInfo:currentLine];
                [blockSelf setSingleCharInfo:singleCharInfo];
            }
        });
    });
}


// ------------------------------------------------------
/// ステータスバーと情報ドローワの改行コード表記を更新
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [[self statusBar] showStatusBar];
    BOOL shouldUpdateDrawer = inBool ? YES : [self needsInfoDrawerUpdate];
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSString *lineEndingsInfo;
    
    switch ([[self editorView] lineEndingCharacter]) {
        case OgreLfNewlineCharacter:
            lineEndingsInfo = @"LF";
            break;
        case OgreCrNewlineCharacter:
            lineEndingsInfo = @"CR";
            break;
        case OgreCrLfNewlineCharacter:
            lineEndingsInfo = @"CRLF";
            break;
        case OgreUnicodeLineSeparatorNewlineCharacter:
            lineEndingsInfo = @"U-lineSep"; // Unicode line separator
            break;
        case OgreUnicodeParagraphSeparatorNewlineCharacter:
            lineEndingsInfo = @"U-paraSep"; // Unicode paragraph separator
            break;
        case OgreNonbreakingNewlineCharacter:
            lineEndingsInfo = @""; // 改行なしの場合
            break;
        default:
            return;
    }
    
    NSString *encodingInfo = [[self document] currentIANACharSetName];
    if (shouldUpdateStatusBar) {
        [[self statusBar] setEncodingInfo:encodingInfo];
        [[self statusBar] setLineEndingsInfo:lineEndingsInfo];
        [[self statusBar] setFileSizeInfo:[[[self document] fileAttributes] fileSize]];
        [[self statusBar] updateRightField];
    }
    if (shouldUpdateDrawer) {
        [self setEncodingInfo:encodingInfo];
        [self setLineEndingsInfo:lineEndingsInfo];
    }
}


// ------------------------------------------------------
/// 非互換文字更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupIncompatibleCharTimer
// ------------------------------------------------------
{
    if ([self needsIncompatibleCharDrawerUpdate]) {
        if ([self incompatibleCharTimer]) {
            [[self incompatibleCharTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:incompatibleCharInterval]];
        } else {
            [self setIncompatibleCharTimer:[NSTimer scheduledTimerWithTimeInterval:incompatibleCharInterval
                                                                            target:self
                                                                          selector:@selector(doUpdateIncompatibleCharListWithTimer:)
                                                                          userInfo:nil
                                                                           repeats:NO]];
        }
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
                                                                selector:@selector(doUpdateInfoWithTimer:)
                                                                userInfo:nil
                                                                 repeats:NO]];
    }
}
    


#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    // クリック時に当該文字列を選択するように設定
    [[self listTableView] setTarget:self];
    [[self listTableView] setAction:@selector(selectIncompatibleRange:)];
}


//=======================================================
// OgreKit Protocol
//
//=======================================================

// ------------------------------------------------------
/// *OgreKit method. to pass the main textView.
- (void)tellMeTargetToFindIn:(id)textFinder
// ------------------------------------------------------
{
    [textFinder setTargetToFindIn:[[self editorView] textView]];
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
        if ([self recolorWithBecomeKey]) {
            [self setRecolorWithBecomeKey:NO];
            [[self document] doSetSyntaxStyle:[[self editorView] syntaxStyleName]];
        }
    }
}


// ------------------------------------------------------
/// ウィンドウが閉じる直前
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    // デリゲートをやめる
    [[self drawer] setDelegate:nil];
    [[self tabView] setDelegate:nil];

    // バインディング停止
    //（自身の変数 tabViewSelectedIndex を使わせている関係で、放置しておくと自身が retain されたままになる）
    [[self tabViewSelectionPopUpButton] unbind:@"selectedIndex"];
    [[self tabView] unbind:@"selectedIndex"];
}


// ------------------------------------------------------
/// フルスクリーンを開始
- (void)windowWillEnterFullScreen:(NSNotification *)notification
// ------------------------------------------------------
{
    // ウインドウ背景をデフォルトにする（ツールバーの背景に影響）
    [[self window] setBackgroundColor:nil];
}


// ------------------------------------------------------
/// フルスクリーンを終了
- (void)windowDidExitFullScreen:(NSNotification *)notification
// ------------------------------------------------------
{
    // ウインドウ背景を戻す
    [[self window] setBackgroundColor:[NSColor clearColor]];
}


//=======================================================
// Delegate method (NSTabView)
//  <== tabView
//=======================================================

// ------------------------------------------------------
/// ドローワのタブが切り替えられる直前に内容の更新を行う
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
// ------------------------------------------------------
{
    if ([[tabViewItem identifier] isEqualToString:k_infoIdentifier]) {
        [self updateFileAttrsInformation];
        [self updateDocumentInfoStringWithDrawerForceUpdate:YES];
        [self updateLineEndingsInStatusAndInfo:YES];
    } else if ([[tabViewItem identifier] isEqualToString:k_incompatibleIdentifier]) {
        [self updateIncompatibleCharList];
    }
}


//=======================================================
// Delegate method (NSDrawer)
//  <== drawer
//=======================================================

// ------------------------------------------------------
/// ドローワが閉じたらテキストビューのマークアップをクリア
- (void)drawerDidClose:(NSNotification *)notification
// ------------------------------------------------------
{
    [self clearAllMarkup];
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
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            // 情報の更新
            [self updateFileAttrsInformation];
            [self updateDocumentInfoStringWithDrawerForceUpdate:YES];
            [self updateLineEndingsInStatusAndInfo:YES];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
    }
}


// ------------------------------------------------------
/// 変換不可文字列リストパネルを開く
- (IBAction)toggleIncompatibleCharList:(id)sender
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            [self updateIncompatibleCharList];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
    }
}


// ------------------------------------------------------
/// 文字列を選択
- (IBAction)selectIncompatibleRange:(id)sender
// ------------------------------------------------------
{
    if ([[[self listController] selectedObjects] count] == 0) { return; }

    NSRange range = [[[self listController] selectedObjects][0][k_incompatibleRange] rangeValue];
    
    [[self editorView] setSelectedRange:range];
    [[self window] makeFirstResponder:[[self editorView] textView]];
    [[[self editorView] textView] scrollRangeToVisible:range];

    // 検索結果表示エフェクトを追加
    [[[self editorView] textView] showFindIndicatorForRange:range];
}


// ------------------------------------------------------
/// ステータスバーの表示をトグルに切り替える
- (IBAction)toggleShowStatusBar:(id)sender
// ------------------------------------------------------
{
    [self setShowStatusBar:![self showStatusBar]];
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
    NSString *currentName = [[self editorView] syntaxStyleName];
    NSString *oldName = [notification userInfo][CEOldNameKey];
    NSString *newName = [notification userInfo][CENewNameKey];
    
    if ([oldName isEqualToString:currentName]) {
        if (![oldName isEqualToString:newName]) {
            [[self editorView] setSyntaxStyleName:newName recolorNow:NO];
        }
        if (![newName isEqualToString:NSLocalizedString(@"None", nil)]) {
            [self setRecolorWithBecomeKey:YES];
        }
    }
}


// ------------------------------------------------------
/// 単語数情報をセット
- (void)setWordsInfo:(NSUInteger)words selected:(NSUInteger)selectedWords
// ------------------------------------------------------
{
    [self setWordsInfo:[self formatCount:words selected:selectedWords]];
}


// ------------------------------------------------------
/// バイト長情報をセット
- (void)setByteLengthInfo:(NSUInteger)byteLength selected:(NSUInteger)selectedByteLength
// ------------------------------------------------------
{
    [self setByteLengthInfo:[self formatCount:byteLength selected:selectedByteLength]];
}


// ------------------------------------------------------
/// 文字数情報をセット
- (void)setCharsInfo:(NSUInteger)chars selected:(NSUInteger)selectedChars
// ------------------------------------------------------
{
    [self setCharsInfo:[self formatCount:chars selected:selectedChars]];
}


// ------------------------------------------------------
/// 文字長情報をセット
- (void)setLengthInfo:(NSUInteger)length selected:(NSUInteger)selectedLength
// ------------------------------------------------------
{
    [self setLengthInfo:[self formatCount:length selected:selectedLength]];
}


// ------------------------------------------------------
/// 行数情報をセット
- (void)setLinesInfo:(NSUInteger)lines selected:(NSUInteger)selectedLines
// ------------------------------------------------------
{
    [self setLinesInfo:[self formatCount:lines selected:selectedLines]];
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
/// 背景色(検索のハイライト含む)の変更を取り消し
- (void)clearAllMarkup
// ------------------------------------------------------
{
    NSArray *managers = [[self editorView] allLayoutManagers];
    
    for (NSLayoutManager *manager in managers) {
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[[self editorView] string] length])];
    }
}


// ------------------------------------------------------
/// 現在のエンコードにコンバートできない文字列をマークアップ
- (void)markupIncompatibleChars:(NSArray *)uncompatibleChars
// ------------------------------------------------------
{
    // 文字色と背景色の中間色を得る
    NSColor *foreColor = [[[self editorView] textView] textColor];
    NSColor *backColor = [[[self editorView] textView] backgroundColor];
    CGFloat BG_R, BG_G, BG_B, F_R, F_G, F_B;
    [[foreColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&F_R green:&F_G blue:&F_B alpha:nil];
    [[backColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&BG_R green:&BG_G blue:&BG_B alpha:nil];
    NSColor *incompatibleColor = [NSColor colorWithCalibratedRed:((BG_R + F_R) / 2)
                                                           green:((BG_G + F_G) / 2)
                                                            blue:((BG_B + F_B) / 2)
                                                           alpha:1.0];
    
    // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
    [self clearAllMarkup];
    
    // 非互換文字をハイライト
    NSArray *layoutManagers = [[self editorView] allLayoutManagers];
    for (NSDictionary *uncompatible in uncompatibleChars) {
        for (NSLayoutManager *manager in layoutManagers) {
            [manager addTemporaryAttribute:NSBackgroundColorAttributeName
                                     value:incompatibleColor
                         forCharacterRange:[uncompatible[k_incompatibleRange] rangeValue]];
        }
    }
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、情報更新
- (void)doUpdateInfoWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopInfoUpdateTimer];
    [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、非互換文字情報更新
- (void)doUpdateIncompatibleCharListWithTimer:(NSTimer *)timer
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
