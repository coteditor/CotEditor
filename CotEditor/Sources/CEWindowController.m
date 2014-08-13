/*
 ==============================================================================
 CEWindowController
 
 CotEditor
 http://coteditor.github.io
 
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
#import "CEDocumentController.h"
#import "CEStatusBarController.h"
#import "CESyntaxManager.h"
#import "NSString+ComposedCharacter.h"
#import "constants.h"


@interface CEWindowController ()

@property (nonatomic) NSUInteger tabViewSelectedIndex; // ドロワーのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)
@property (nonatomic) BOOL needsRecolorWithBecomeKey; // ウィンドウがキーになったとき再カラーリングをするかどうかのフラグ

@property (nonatomic) NSTimer *infoUpdateTimer;
@property (nonatomic) NSTimer *incompatibleCharTimer;

// document information (for binding in drawer)
@property (nonatomic, copy) NSString *encodingInfo;
@property (nonatomic, copy) NSString *lineEndingsInfo;
@property (nonatomic, copy) NSDate *createdInfo;
@property (nonatomic, copy) NSDate *modificatedInfo;
@property (nonatomic, copy) NSString *ownerInfo;
@property (nonatomic, copy) NSString *typeInfo;
@property (nonatomic, copy) NSString *creatorInfo;
@property (nonatomic, copy) NSString *finderLockInfo;
@property (nonatomic, copy) NSString *permissionInfo;
@property (nonatomic) unsigned long long fileSizeInfo;
// editor information (for binding in drawer)
@property (nonatomic, copy) NSString *linesInfo;
@property (nonatomic, copy) NSString *charsInfo;
@property (nonatomic, copy) NSString *wordsInfo;
@property (nonatomic, copy) NSString *lengthInfo;
@property (nonatomic, copy) NSString *byteLengthInfo;
@property (nonatomic) NSUInteger columnInfo;           // caret location from line head
@property (nonatomic) NSUInteger locationInfo;         // caret location from begining of document
@property (nonatomic) NSUInteger lineInfo;             // current line
@property (nonatomic, copy) NSString *singleCharInfo;  // Unicode of selected single character (or surrogate-pair)

// IBOutlets
@property (nonatomic) IBOutlet CEStatusBarController *statusBarController;
@property (nonatomic) IBOutlet NSArrayController *listController;
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
/// ウィンドウ表示の準備完了時、サイズを設定し文字列／不透明度をセット
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSSize size = NSMakeSize((CGFloat)[defaults doubleForKey:k_key_windowWidth],
                             (CGFloat)[defaults doubleForKey:k_key_windowHeight]);
    [[self window] setContentSize:size];
    
    // 背景をセットアップ
    [self setAlpha:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]];
    [[self window] setBackgroundColor:[NSColor clearColor]]; // ウィンドウ背景色に透明色をセット
    
    // ドキュメントオブジェクトに CEEditorWrapper インスタンスをセット
    [[self document] setEditor:[self editor]];
    // テキストを表示
    [[self document] setStringToEditor];
    
    [self updateFileAttributesInfo];
    
    // setup status bar
    [[self statusBarController] setShowsStatusBar:[defaults boolForKey:k_key_showStatusBar]];
    [[self statusBarController] setShowsReadOnly:![[self document] isWritable]];
    
    // テキストビューへフォーカスを移動
    [[self window] makeFirstResponder:[[self editor] textView]];
    
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
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// 非互換文字ドロワー内容を更新すべきかを返す
- (BOOL)needsIncompatibleCharDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
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
/// 情報ドロワーとステータスバーの文書情報を更新
- (void)updateEditorStatusInfo:(BOOL)needsUpdateDrawer
// ------------------------------------------------------
{
    BOOL updatesStatusBar = [[self statusBarController] showsStatusBar];
    BOOL updatesDrawer = needsUpdateDrawer ? YES : [self needsInfoDrawerUpdate];
    
    if (!updatesStatusBar && !updatesDrawer) { return; }
    
    NSString *wholeString = ([[[self document] lineEndingString] length] == 2) ? [[self document] stringForSave] : [[[self editor] string] copy];
    NSString *selectedString = [[self editor] substringWithSelection] ? : @"";
    NSStringEncoding encoding = [[self document] encoding];
    __block NSRange selectedRange = [[self editor] selectedRange];
    __block CEStatusBarController *statusBar = [self statusBarController];
    __weak typeof(self) weakSelf = self;
    
    // 別スレッドで情報を計算し、メインスレッドで drawer と statusBar に渡す
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL countLineEnding = [defaults boolForKey:k_key_countLineEndingAsChar];
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
        dispatch_sync(dispatch_get_main_queue(), ^{
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
                [statusBar updateEditorStatus];
            }
            if (updatesDrawer) {
                [strongSelf setLinesInfo:[strongSelf formatCount:numberOfLines selected:numberOfSelectedLines]];
                [strongSelf setCharsInfo:[strongSelf formatCount:numberOfChars selected:numberOfSelectedChars]];
                [strongSelf setLengthInfo:[strongSelf formatCount:length selected:selectedRange.length]];
                [strongSelf setByteLengthInfo:[strongSelf formatCount:byteLength selected:selectedByteLength]];
                [strongSelf setWordsInfo:[strongSelf formatCount:numberOfWords selected:numberOfSelectedWords]];
                [strongSelf setLocationInfo:location];
                [strongSelf setColumnInfo:column];
                [strongSelf setLineInfo:currentLine];
                [strongSelf setSingleCharInfo:singleCharInfo];
            }
        });
    });
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーの改行コード／エンコーディング表記を更新
- (void)updateEncodingAndLineEndingsInfo:(BOOL)needsUpdateDrawer
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [[self statusBarController] showsStatusBar];
    BOOL shouldUpdateDrawer = needsUpdateDrawer ? YES : [self needsInfoDrawerUpdate];
    
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSString *lineEndingsInfo = [[self document] lineEndingName];
    NSString *encodingInfo = [[self document] currentIANACharSetName];
    
    [self setEncodingInfo:encodingInfo];
    [self setLineEndingsInfo:lineEndingsInfo];
    
    [[self statusBarController] setEncodingInfo:encodingInfo];
    [[self statusBarController] setLineEndingsInfo:lineEndingsInfo];
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
    
    [self setCreatedInfo:[attrs fileCreationDate]];
    [self setModificatedInfo:[attrs fileModificationDate]];
    [self setOwnerInfo:[attrs fileOwnerAccountName]];
    [self setTypeInfo:NSFileTypeForHFSTypeCode([attrs fileHFSTypeCode])];
    [self setCreatorInfo:NSFileTypeForHFSTypeCode([attrs fileHFSCreatorCode])];
    [self setFinderLockInfo:([attrs fileIsImmutable] ? NSLocalizedString(@"ON", nil) : nil)];
    [self setPermissionInfo:[NSString stringWithFormat:@"%tu", [attrs filePosixPermissions]]];
    [self setFileSizeInfo:[attrs fileSize]];
    
    [[self statusBarController] setFileSizeInfo:[attrs fileSize]];
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
/// テキストビューの不透明度を返す
- (CGFloat)alpha
// ------------------------------------------------------
{
    return [[[self editor] textView] backgroundAlpha];
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
    [[self editor] setBackgroundAlpha:sanitizedAlpha];
    [[[self window] contentView] setNeedsDisplay:YES];
    [[self window] invalidateShadow];
}


// ------------------------------------------------------
/// ステータスバーを表示するかどうかを返す
- (BOOL)showsStatusBar
// ------------------------------------------------------
{
    return [[self statusBarController] showsStatusBar];
}


// ------------------------------------------------------
/// ステータスバーを表示する／しないをセット
- (void)setShowsStatusBar:(BOOL)showsStatusBar
// ------------------------------------------------------
{
    if (![self statusBarController]) { return; }
    
    [[self statusBarController] setShowsStatusBar:showsStatusBar];
    [[self toolbarController] toggleItemWithIdentifier:k_showStatusBarItemID setOn:showsStatusBar];
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
- (void)tellMeTargetToFindIn:(id)textFinder
// ------------------------------------------------------
{
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
/// ドロワーのタブが切り替えられる直前に内容の更新を行う
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
// ------------------------------------------------------
{
    if ([[tabViewItem identifier] isEqualToString:k_infoIdentifier]) {
        [self updateFileAttributesInfo];
        [self updateEditorStatusInfo:YES];
        [self updateEncodingAndLineEndingsInfo:YES];
    } else if ([[tabViewItem identifier] isEqualToString:k_incompatibleIdentifier]) {
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
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            // 情報の更新
            [self updateFileAttributesInfo];
            [self updateEditorStatusInfo:YES];
            [self updateEncodingAndLineEndingsInfo:YES];
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
    
    [[self editor] setSelectedRange:range];
    [[self window] makeFirstResponder:[[self editor] textView]];
    [[[self editor] textView] scrollRangeToVisible:range];

    // 検索結果表示エフェクトを追加
    [[[self editor] textView] showFindIndicatorForRange:range];
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
            [self setNeedsRecolorWithBecomeKey:YES];
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
        [ranges addObject:incompatible[k_incompatibleRange]];
    }
    [[self editor] clearAllMarkup];
    [[self editor] markupRanges:ranges];
    
    
    [[self listErrorTextField] setHidden:([contents count] > 0)]; // リストが取得できなかった時のメッセージを表示
    [[self listController] setContent:contents];
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
