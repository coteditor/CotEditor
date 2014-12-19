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
#import "CEIncompatibleCharsViewController.h"
#import "CESyntaxManager.h"
#import "CEDocumentAnalyzer.h"
#import "constants.h"


// sidebar mode
typedef NS_ENUM(NSUInteger, CESidebarTag) {
    CEDocumentInfoTag = 1,
    CEIncompatibleCharsTag,
};


@interface CEWindowController () <NSSplitViewDelegate>

@property (nonatomic) NSUInteger selectedSidebarTag; // ドロワーのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)
@property (nonatomic) BOOL needsRecolorWithBecomeKey; // ウィンドウがキーになったとき再カラーリングをするかどうかのフラグ
@property (nonatomic) NSTimer *editorInfoUpdateTimer;
@property (nonatomic) CGFloat sidebarWidth;


// IBOutlets
@property (nonatomic) IBOutlet CEStatusBarController *statusBarController;
@property (nonatomic) IBOutlet NSViewController *documentInfoViewController;
@property (nonatomic) IBOutlet CEIncompatibleCharsViewController *incompatibleCharsViewController;
@property (nonatomic, weak) IBOutlet NSSplitView *sidebarSplitView;
@property (nonatomic, weak) IBOutlet NSView *sidebar;
@property (nonatomic, weak) IBOutlet NSBox *sidebarBox;
@property (nonatomic) IBOutlet CEDocumentAnalyzer *documentAnalyzer;

// IBOutlets (readonly)
@property (readwrite, nonatomic, weak) IBOutlet CEToolbarController *toolbarController;
@property (readwrite, nonatomic, weak) IBOutlet CEEditorWrapper *editor;

@end




#pragma mark -

@implementation CEWindowController

static NSTimeInterval infoUpdateInterval;


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
    });
}



#pragma mark NSWindowController Methods

//=======================================================
// NSWindowController method
//
//=======================================================

// ------------------------------------------------------
/// ウィンドウ表示の準備
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [[self window] setContentSize:NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultWindowWidthKey],
                                             (CGFloat)[defaults doubleForKey:CEDefaultWindowHeightKey])];
    
    // setup background
    [(CEWindow *)[self window] setBackgroundAlpha:[defaults doubleForKey:CEDefaultWindowAlphaKey]];
    
    // setup document analyzer
    [[self documentAnalyzer] setDocument:[self document]];
    [[self documentInfoViewController] setRepresentedObject:[self documentAnalyzer]];
    
    // setup sidebar
    [[[self sidebar] layer] setBackgroundColor:CGColorCreateGenericGray(0.93, 1.0)];
    [self setSidebarShown:[defaults boolForKey:CEDefaultShowDocumentInspectorKey]];
    
    // set document instance to incompatible chars view
    [[self incompatibleCharsViewController] setRepresentedObject:[self document]];
    
    // set CEEditorWrapper to document instance
    [[self document] setEditor:[self editor]];
    [[self document] setStringToEditor];
    
    // setup status bar
    [[self statusBarController] setShown:[defaults boolForKey:CEDefaultShowStatusBarKey] animate:NO];
    [[self statusBarController] setShowsReadOnly:![[self document] isWritable]];
    
    [self updateFileInfo];
    [self updateModeInfoIfNeeded];
    
    // move focus to text view
    [[self window] makeFirstResponder:[[self editor] textView]];
    
    // observe sytnax style update
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
    
    [self stopEditorInfoUpdateTimer];
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
/// 非互換文字リストを表示
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [self setSelectedSidebarTag:CEIncompatibleCharsTag];
    [self setSidebarShown:YES];
}


// ------------------------------------------------------
/// 非互換文字を表示している場合はディレイののち更新
- (void)updateIncompatibleCharsIfNeeded
// ------------------------------------------------------
{
    [[self incompatibleCharsViewController] updateIfNeeded];
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーの文書情報を表示しているとき更新
- (void)updateEditorInfoIfNeeded
// ------------------------------------------------------
{
    BOOL updatesStatusBar = [[self statusBarController] isShown];
    BOOL updatesDrawer = [self isDocumentInfoShown];
    
    if (!updatesStatusBar && !updatesDrawer) { return; }
    
    [[self documentAnalyzer] updateEditorInfo:updatesDrawer];
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーの改行コード／エンコーディング表記を更新
- (void)updateModeInfoIfNeeded
// ------------------------------------------------------
{
    BOOL updatesStatusBar = [[self statusBarController] isShown];
    BOOL updatesDrawer = [self isDocumentInfoShown];
    
    if (!updatesStatusBar && !updatesDrawer) { return; }
    
    [[self documentAnalyzer] updateModeInfo];
}


// ------------------------------------------------------
/// 情報ドロワーとステータスバーのファイル情報を更新
- (void)updateFileInfo
// ------------------------------------------------------
{
    [[self documentAnalyzer] updateFileInfo];
}


// ------------------------------------------------------
/// 文書情報更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupEditorInfoUpdateTimer
// ------------------------------------------------------
{
    if ([self editorInfoUpdateTimer]) {
        [[self editorInfoUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:infoUpdateInterval]];
    } else {
        [self setEditorInfoUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:infoUpdateInterval
                                                                        target:self
                                                                      selector:@selector(updateEditorInfoWithTimer:)
                                                                      userInfo:nil
                                                                       repeats:NO]];
    }
}



#pragma mark Accessors

// ------------------------------------------------------
/// ステータスバーを表示しているかどうかを返す
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
    
    if (showsStatusBar) {
        [[self documentAnalyzer] updateEditorInfo:NO];
        [[self documentAnalyzer] updateFileInfo];
        [[self documentAnalyzer] updateModeInfo];
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
    // do nothing if any sheet is attached
    if ([[self window] attachedSheet]) { return; }
    
    // フラグがたっていたら、改めてスタイル名を指定し直して再カラーリングを実行
    if ([self needsRecolorWithBecomeKey]) {
        [self setNeedsRecolorWithBecomeKey:NO];
        [[self document] doSetSyntaxStyle:[[self editor] syntaxStyleName]];
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
    [state encodeBool:[self isSidebarShown] forKey:CEDefaultShowDocumentInspectorKey];
    [state encodeDouble:[self sidebarWidth] forKey:CEDefaultSidebarWidthKey];
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
    if ([state containsValueForKey:CEDefaultShowDocumentInspectorKey]) {
        [self setSidebarWidth:[state decodeDoubleForKey:CEDefaultSidebarWidthKey]];
        [self setSidebarShown:[state decodeBoolForKey:CEDefaultShowDocumentInspectorKey]];
    }
}


//=======================================================
// Delegate method (NSSplitView)
//  <== sidebarSplitView
//=======================================================

// ------------------------------------------------------
/// only sidebar can collapse
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
// ------------------------------------------------------
{
    return (subview == [self sidebar]);
}


// ------------------------------------------------------
/// store current sideview's width
- (void)splitViewDidResizeSubviews:(NSNotification *)notification
// ------------------------------------------------------
{
    CGFloat width = NSWidth([[self sidebar] bounds]);
    [self setSidebarWidth:width];
    [[NSUserDefaults standardUserDefaults] setDouble:width forKey:CEDefaultSidebarWidthKey];
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
    if ([self isDocumentInfoShown]) {
        [self setSidebarShown:NO];
    } else {
        [self setSelectedSidebarTag:CEDocumentInfoTag];
        [self setSidebarShown:YES];
    }
}


// ------------------------------------------------------
/// 変換不可文字列リストパネルを開く
- (IBAction)toggleIncompatibleCharList:(id)sender
// ------------------------------------------------------
{
    if ([self isSidebarShown] && [self selectedSidebarTag] == CEIncompatibleCharsTag) {
        [self setSidebarShown:NO];
    } else {
        [self setSelectedSidebarTag:CEIncompatibleCharsTag];
        [self setSidebarShown:YES];
    }
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
/// set sidebar visibility
- (void)setSidebarShown:(BOOL)shown
// ------------------------------------------------------
{
    if ([self selectedSidebarTag] == 0) {
        [self setSelectedSidebarTag:CEDocumentInfoTag];
    }
    
    if (shown) {
        CGFloat width = [self sidebarWidth] ?: [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultSidebarWidthKey];
        CGFloat maxWidth = [[self sidebarSplitView] maxPossiblePositionOfDividerAtIndex:0];
        
        [[self sidebarSplitView] setPosition:(maxWidth - width) ofDividerAtIndex:0];
    } else {
        // store current sidebar width
        if ([[self window] isVisible]) {  // ignore initial hide
            CGFloat width = NSWidth([[self sidebar] bounds]);
            [self setSidebarWidth:width];
            [[NSUserDefaults standardUserDefaults] setDouble:width forKey:CEDefaultSidebarWidthKey];
        }
        // clear incompatible chars markup
        [[self editor] clearAllMarkup];
        
        // close sidebar
        [[self sidebar] setHidden:YES];
    }
    [[self sidebarSplitView] adjustSubviews];
}


// ------------------------------------------------------
/// return whether sidebar is opened
- (BOOL)isSidebarShown
// ------------------------------------------------------
{
    return ![[self sidebarSplitView] isSubviewCollapsed:[self sidebar]];
}


// ------------------------------------------------------
/// 文書情報ドロワー内容を更新すべきかを返す
- (BOOL)isDocumentInfoShown
// ------------------------------------------------------
{
    return ([self selectedSidebarTag] == CEDocumentInfoTag && [self isSidebarShown]);
}


// ------------------------------------------------------
/// switch sidebar view
- (void)setSelectedSidebarTag:(NSUInteger)tag
// ------------------------------------------------------
{
    _selectedSidebarTag = tag;
    
    NSViewController *viewController;
    switch (tag) {
        case CEDocumentInfoTag:
            viewController = [self documentInfoViewController];
            [[self documentAnalyzer] updateEditorInfo:YES];
            [[self documentAnalyzer] updateFileInfo];
            [[self documentAnalyzer] updateModeInfo];
            break;
            
        case CEIncompatibleCharsTag:
            viewController = [self incompatibleCharsViewController];
            [[self incompatibleCharsViewController] update];
            break;
    }
    
    [[self sidebarBox] setContentView:[viewController view]];
}


// ------------------------------------------------------
/// 指定されたスタイルを適用していたら、リカラーフラグを立てる
- (void)syntaxDidUpdate:(NSNotification *)notification
// ------------------------------------------------------
{
    NSString *currentName = [[self editor] syntaxStyleName];
    NSString *oldName = [notification userInfo][CEOldNameKey];
    NSString *newName = [notification userInfo][CENewNameKey];
    
    if (![oldName isEqualToString:currentName]) { return; }
    
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


// ------------------------------------------------------
/// タイマーの設定時刻に到達、情報更新
- (void)updateEditorInfoWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopEditorInfoUpdateTimer];
    [self updateEditorInfoIfNeeded];
}


// ------------------------------------------------------
/// 文書情報更新タイマーを停止
- (void)stopEditorInfoUpdateTimer
// ------------------------------------------------------
{
    if ([self editorInfoUpdateTimer]) {
        [[self editorInfoUpdateTimer] invalidate];
        [self setEditorInfoUpdateTimer:nil];
    }
}

@end
