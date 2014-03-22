/*
 =================================================
 CEPanelController
 (for CotEditor)
 
 Copyright (C) 2004-2006 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2005.07.14
 
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

#import "CEColorCodePanelController.h"
#import "constants.h"


@interface CEColorCodePanelController () <NSComboBoxDelegate>

@property (nonatomic) IBOutlet NSArrayController *foreColorDataController;
@property (nonatomic) IBOutlet NSArrayController *backColorDataController;
@property (nonatomic, weak) IBOutlet NSTextField *sampleTextField;
@property (nonatomic, weak) IBOutlet NSColorWell *foreColorWell;
@property (nonatomic, weak) IBOutlet NSColorWell *backColorWell;
@property (nonatomic, weak) IBOutlet NSComboBox *foreColorComboBox;
@property (nonatomic, weak) IBOutlet NSComboBox *backColorComboBox;
@property (nonatomic, weak) IBOutlet NSButton *disclosureButton;
@property (nonatomic, weak) IBOutlet NSBox *optionView;

@end


#pragma mark -

@implementation CEColorCodePanelController


#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (CEColorCodePanelController *)sharedController
// return singleton instance
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static CEColorCodePanelController *shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[CEColorCodePanelController alloc] initWithWindowNibName:@"ColorCodePanel"];
    });
    
    return shared;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithWindow:(NSWindow *)window
// 初期化
// ------------------------------------------------------
{
    self = [super initWithWindow:window];
    if (self) {
        // ノーティフィケーションセンタへデータ出力読み込み完了の通知を依頼（removeはスーパークラスが行なう）
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setSampleTextFieldBackgroundColor:)
                                                     name:NSColorPanelColorDidChangeNotification
                                                   object:nil];
    }
    return self;
}


// ------------------------------------------------------
- (void)importHexColorCodeAsForeColor:(NSString *)codeString
// 文字列をカラーコードとしてフォアカラーコンボボックスへ取り込む
// ------------------------------------------------------
{
    [self importHexColorCode:codeString to:[self foreColorComboBox]];
}


// ------------------------------------------------------
- (void)importHexColorCodeAsBackColor:(NSString *)codeString
// 文字列をカラーコードとしてBGカラーコンボボックスへ取り込む
//------------------------------------------------------
{
    [self importHexColorCode:codeString to:[self backColorComboBox]];
    // 背景色を強制的に更新
    [[self sampleTextField] setBackgroundColor:[[self backColorWell] color]];
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    // パネル位置／内容を初期化
    [self setupWindowPosition];
    [self setupColorCodeValidation];
    
    // バインディングでは背景色が設定できないので、手動で。
    [[self sampleTextField] setBackgroundColor:[[self backColorWell] color]];
    // ディスクロージャボタンを初期化
    [[self disclosureButton] setState:NSOffState];
    [self toggleDisclosureButton:nil];
    // ArrayController のソート方式をセット
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:k_ColorCodeDataControllerKey ascending:YES];
    [[self foreColorDataController] setSortDescriptors:@[descriptor]];
    [[self backColorDataController] setSortDescriptors:@[descriptor]];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSComboBox)
//  <== backColorComboBox
//=======================================================

// ------------------------------------------------------
- (BOOL)control:(NSControl *)inControl textShouldEndEditing:(NSText *)inFieldEditor
// コンボボックスへの入力終了直前、入力内容を見て完了の許可を出す
// ------------------------------------------------------
{
    NSString *codeString = [inFieldEditor string];

    [self checkComboBox:inControl string:codeString];

    return YES;
}


// ------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
// コンボボックスへの入力が終った
// ------------------------------------------------------
{
    if ([[aNotification object] isEqualTo:[self backColorComboBox]]) {
        // サンプル表示の背景色をセット（バインディングが設定できないので、ノーティフィケーションで行っている）
        // backColorComboBox への Hex 値の入力を反映させる
        [[self sampleTextField] setBackgroundColor:[[self backColorWell] color]];
    }
}


// ------------------------------------------------------
- (void)comboBoxSelectionDidChange:(NSNotification *)aNotification
// コンボボックスのリストの選択が変更された
// ------------------------------------------------------
{
    NSComboBox *comboBox = [aNotification object];
    NSString *theCodeStr = [comboBox objectValueOfSelectedItem];

    [self checkComboBox:comboBox string:[comboBox objectValueOfSelectedItem]];
    if ([comboBox isEqualTo:[self backColorComboBox]]) {
        [self importHexColorCode:theCodeStr to:[self backColorComboBox]];
        // サンプル表示の背景色をセット（バインディングが設定できないので、ノーティフィケーションで行っている）
        // backColorComboBox への Hex 値の入力を反映させる
        [[self sampleTextField] setBackgroundColor:[[self backColorWell] color]];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)exportHexColorCode:(id)sender
// ドキュメントにカラーコードを書き出す
// ------------------------------------------------------
{
    if (![self documentWindowController]) { return; }
    NSString *codeString = nil, *selected = nil;
    NSRange range;

    if ([sender tag] == k_exportForeColorButtonTag) {
        codeString = [[self foreColorComboBox] stringValue];
    } else if ([sender tag] == k_exportBGColorButtonTag) {
        codeString = [[self backColorComboBox] stringValue];
    }
    if ([codeString length] != 6) {
        return;
    }

    range = [[[self documentWindowController] editorView] selectedRange];
    selected = [[[self documentWindowController] editorView] substringWithSelection];
    if ((([selected length] == 7) && 
            ([[selected substringToIndex:1] isEqualToString:@"#"])) || 
            (range.location == 0) || 
            ((range.location > 0) && 
                (![[[[self documentWindowController] editorView] substringWithRange:
                    NSMakeRange(range.location - 1, 1)] isEqualToString:@"#"]))) {
        // ドキュメントで「#」からカラーコードが選択されているとき、
        // または選択範囲の直前が「#」でないときはアタマに「#」を追加して置換／挿入
        [[[self documentWindowController] editorView] replaceTextViewSelectedStringTo:
                [NSString stringWithFormat:@"#%@", codeString] scroll:YES];
    } else {
        [[[self documentWindowController] editorView] replaceTextViewSelectedStringTo:codeString scroll:YES];
    }
    // ドキュメントウィンドウを前面に
    [[[[self documentWindowController] editorView] window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)swapColor:(id)sender
// 文字色／背景色入れ換え
// ------------------------------------------------------
{
    NSString *codeString = [[self foreColorComboBox] stringValue];

    [[self window] makeFirstResponder:[self foreColorComboBox]];
    [[self foreColorComboBox] setStringValue:[[self backColorComboBox] stringValue]];
    [[self window] makeFirstResponder:[self backColorComboBox]];
    [[self backColorComboBox] setStringValue:codeString];
    [[self window] makeFirstResponder:[self foreColorComboBox]];
    // 適正値かどうかの判断基準フラグを初期化
    [self setupColorCodeValidation];
    // 背景色を強制的に更新
    [[self sampleTextField] setBackgroundColor:[[self backColorWell] color]];
}


// ------------------------------------------------------
- (IBAction)toggleDisclosureButton:(id)sender
// ディスクロージャボタンでの表示切り替え
// ------------------------------------------------------
{
    NSRect windowFrame = [[self window] frame];
    CGFloat optionHeight = [[self optionView] frame].size.height;
    
    if ([sender state] == NSOnState) {
        windowFrame.origin.y -= optionHeight;
        windowFrame.size.height += optionHeight;
        [[self optionView] setHidden:NO];
    } else {
        windowFrame.origin.y += optionHeight;
        windowFrame.size.height -= optionHeight;
        [[self optionView] setHidden:YES];
    }
    [[self window] setFrame:windowFrame display:YES animate:NO];
}


// ------------------------------------------------------
- (IBAction)addComboBoxDataCurrentString:(id)sender
// コンボボックスのリストに現在の値を加える
// ------------------------------------------------------
{
    // フォーカスを移して値を確定
    [[sender window] makeFirstResponder:sender];

    // 正しい値が入力されているときのみ、リストへの追加を行う
    if (([sender tag] == k_addCodeToForeButtonTag) && 
            ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_foreColorCBoxIsOk])) {
        [[self foreColorDataController] addObject:@{k_ColorCodeDataControllerKey: [[self foreColorComboBox] stringValue]}];
    } else if (([sender tag] == k_addCodeToBackButtonTag) && 
            ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_backgroundColorCBoxIsOk])) {
        [[self backColorDataController] addObject:@{k_ColorCodeDataControllerKey: [[self backColorComboBox] stringValue]}];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (void)setupWindowPosition
// 記憶されたパネル位置を是正（ディスクロージャ矢印で表示される部分だけ下部に長く保存されている）
//------------------------------------------------------
{
    NSPoint origin = [[self window] frame].origin;
    origin.y -= [[self optionView] frame].size.height;
    [[self window] setFrameOrigin:origin];
}


//------------------------------------------------------
- (void)setupColorCodeValidation
// 適正値かどうかの判断基準フラグを初期化
//------------------------------------------------------
{
    [self checkComboBox:[self foreColorComboBox] string:[[self foreColorComboBox] stringValue]];
    [self checkComboBox:[self backColorComboBox] string:[[self backColorComboBox] stringValue]];
}

//------------------------------------------------------
- (void)setSampleTextFieldBackgroundColor:(NSNotification *)aNotification
// （カラーウェルの変更にともなって）サンプル表示の背景色をセット
//------------------------------------------------------
{
    // （バインディングが設定できないので、ノーティフィケーションで行っている）

    // 別のカラーウェルのものだったら、無視
    if ((![[self window] isKeyWindow]) || (![[self backColorWell] isActive])) {
        return;
    }
    id colorPanel = [aNotification object];
    NSColor *color = [colorPanel color];

    if (color != nil) {
        [[self sampleTextField] setBackgroundColor:color];
    }
}


//------------------------------------------------------
- (void)importHexColorCode:(NSString *)codeString to:(id)control
// 文字列をカラーコードとしてコンボボックスへ取り込む
//------------------------------------------------------
{
    NSString *string = nil;
    BOOL isHex = NO;

    if (([codeString length] == 7) && 
            ([[codeString substringToIndex:1] isEqualToString:@"#"])) {
        string = [codeString substringFromIndex:1];
    } else if ([codeString length] == 6) {
        string = codeString;
    }
    if ([string length] == 6) {
        NSCharacterSet *theSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSInteger i;

        for (i = 0; i < 6; i++) {
            isHex = [theSet characterIsMember:[string characterAtIndex:i]];
            if (!isHex) {
                break;
            }
        }
    }
    // 正しいカラーコードのみ取り込む
    if ((string != nil) && (isHex)) {
        [[control window] makeFirstResponder:control];
        [control setStringValue:string];
        // いったん、レスポンダをウィンドウにして値を確定、他のコントロールに反映させる
        [[control window] makeFirstResponder:[control window]];
    }
    [[control window] makeKeyAndOrderFront:self];
    [[control window] makeFirstResponder:control];
}


//------------------------------------------------------
- (void)checkComboBox:(id)control string:(NSString *)string
// コンボボックスの値をチェック、不正なら背景色を変更する
//------------------------------------------------------
{
    NSString *keyName = nil;
    BOOL isValid = NO;

    if ((string != nil) && ([string length] == 6)) {
        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSInteger i;

        isValid = YES;
        for (i = 0; i < 6; i++) {
            if (![set characterIsMember:[string characterAtIndex:i]]) {
                isValid = NO;
                break;
            }
        }
    }
    if (isValid) {
        [(NSComboBox *)control setBackgroundColor:[NSColor controlBackgroundColor]];
    } else {
        [(NSComboBox *)control setBackgroundColor:
                [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.5 alpha:1.0]];
        NSBeep();
    }
    if ([control isEqualTo:[self foreColorComboBox]]) {
        keyName = k_key_foreColorCBoxIsOk;
    } else if ([control isEqualTo:[self backColorComboBox]]) {
        keyName = k_key_backgroundColorCBoxIsOk;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(isValid) forKey:keyName];
}

@end
