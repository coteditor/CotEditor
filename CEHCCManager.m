/*
=================================================
CEHCCManager
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

#import "CEHCCManager.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEHCCManager (Private)
- (void)setupWindowPosition;
- (void)setupHCCIsOk;
- (void)setSampleTextFieldBackgroundColor:(NSNotification *)inNotification;
- (void)importHexColorCode:(NSString *)inCodeString to:(id)inControl;
- (void)checkComboBox:(id)inControl string:(NSString *)inString;
@end


//------------------------------------------------------------------------------------------




@implementation CEHCCManager

static CEHCCManager *sharedInstance = nil;

#pragma mark ===== Class method =====

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (CEHCCManager *)sharedInstance
// 共有インスタンスを返す
// ------------------------------------------------------
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    if (sharedInstance == nil) {
        self = [super init];
        (void)[NSBundle loadNibNamed:@"HCCManager" owner:self];
        // ノーティフィケーションセンタへデータ出力読み込み完了の通知を依頼
        [[NSNotificationCenter defaultCenter] addObserver:self 
            selector:@selector(setSampleTextFieldBackgroundColor:) 
            name:NSColorPanelColorDidChangeNotification 
            object:nil];
        sharedInstance = self;
    }
    return sharedInstance;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSBundle loadNibNamed: でロードされたオブジェクトを開放
    // 参考にさせていただきました > http://homepage.mac.com/mkino2/backnumber/2004_10.html#October%2012_1
    [[_sampleTextField window] release]; // （コンテントビューは自動解放される）
    [_foreColorDataController release];
    [_backColorDataController release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setupHCCValues
// パネル位置／内容を初期化
// ------------------------------------------------------
{
    [self setupWindowPosition];
    [self setupHCCIsOk];
}


// ------------------------------------------------------
- (void)openHexColorCodeEditor
// カラーコード編集ウィンドウを表示
// ------------------------------------------------------
{
    [[_sampleTextField window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (void)importHexColorCodeAsForeColor:(NSString *)inCodeString
// 文字列をカラーコードとしてフォアカラーコンボボックスへ取り込む
// ------------------------------------------------------
{
    [self importHexColorCode:inCodeString to:_foreColorComboBox];
}


// ------------------------------------------------------
- (void)importHexColorCodeAsBackGroundColor:(NSString *)inCodeString
// 文字列をカラーコードとしてBGカラーコンボボックスへ取り込む
//------------------------------------------------------
{
    [self importHexColorCode:inCodeString to:_backgroundColorComboBox];
    // 背景色を強制的に更新
    [_sampleTextField setBackgroundColor:[_backgroundColorWell color]];
}



#pragma mark ===== Protocol =====

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    // バインディングでは背景色が設定できないので、手動で。
    [_sampleTextField setBackgroundColor:[_backgroundColorWell color]];
    // ディスクロージャボタンを初期化
    [_disclosureButton setState:NSOffState];
    [self toggleDisclosureButton:nil];
    // ArrayController のソート方式をセット
    NSSortDescriptor *theDescriptor = 
            [[[NSSortDescriptor alloc] initWithKey:k_HCCDataControllerKey ascending:YES] autorelease];
    [_foreColorDataController setSortDescriptors:@[theDescriptor]];
    [_backColorDataController setSortDescriptors:@[theDescriptor]];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSComboBox)
//  <== _backgroundColorComboBox
//=======================================================

// ------------------------------------------------------
- (BOOL)control:(NSControl *)inControl textShouldEndEditing:(NSText *)inFieldEditor
// コンボボックスへの入力終了直前、入力内容を見て完了の許可を出す
// ------------------------------------------------------
{
    NSString *theCodeStr = [inFieldEditor string];

    [self checkComboBox:inControl string:theCodeStr];

    return YES;
}


// ------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification *)inNotification
// コンボボックスへの入力が終った
// ------------------------------------------------------
{
    if ([[inNotification object] isEqualTo:_backgroundColorComboBox]) {
        // サンプル表示の背景色をセット（バインディングが設定できないので、ノーティフィケーションで行っている）
        // _backgroundColorComboBox への Hex 値の入力を反映させる
        [_sampleTextField setBackgroundColor:[_backgroundColorWell color]];
    }
}


// ------------------------------------------------------
- (void)comboBoxSelectionDidChange:(NSNotification *)inNotification
// コンボボックスのリストの選択が変更された
// ------------------------------------------------------
{
    id theComboBox = [inNotification object];
    NSString *theCodeStr = [theComboBox objectValueOfSelectedItem];

    [self checkComboBox:theComboBox string:[theComboBox objectValueOfSelectedItem]];
    if ([theComboBox isEqualTo:_backgroundColorComboBox]) {
        [self importHexColorCode:theCodeStr to:_backgroundColorComboBox];
        // サンプル表示の背景色をセット（バインディングが設定できないので、ノーティフィケーションで行っている）
        // _backgroundColorComboBox への Hex 値の入力を反映させる
        [_sampleTextField setBackgroundColor:[_backgroundColorWell color]];
    }
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)exportHexColorCode:(id)sender
// ドキュメントにカラーコードを書き出す
// ------------------------------------------------------
{
    if ([[NSApp orderedDocuments] count] < 1) { return; }
    CEDocument *theDoc = [NSApp orderedDocuments][0];
    NSString *theCodeStr = nil, *theSelected = nil;
    NSRange theRange;

    if ([sender tag] == k_exportForeColorButtonTag) {
        theCodeStr = [_foreColorComboBox stringValue];
    } else if ([sender tag] == k_exportBGColorButtonTag) {
        theCodeStr = [_backgroundColorComboBox stringValue];
    }
    if ([theCodeStr length] != 6) {
        return;
    }

    theRange = [[theDoc editorView] selectedRange];
    theSelected = [[theDoc editorView] substringWithSelection];
    if ((([theSelected length] == 7) && 
            ([[theSelected substringToIndex:1] isEqualToString:@"#"])) || 
            (theRange.location == 0) || 
            ((theRange.location > 0) && 
                (![[[theDoc editorView] substringWithRange:
                    NSMakeRange(theRange.location - 1, 1)] isEqualToString:@"#"]))) {
        // ドキュメントで「#」からカラーコードが選択されているとき、
        // または選択範囲の直前が「#」でないときはアタマに「#」を追加して置換／挿入
        [[theDoc editorView] replaceTextViewSelectedStringTo:
                [NSString stringWithFormat:@"#%@", theCodeStr] scroll:YES];
    } else {
        [[theDoc editorView] replaceTextViewSelectedStringTo:theCodeStr scroll:YES];
    }
    // ドキュメントウィンドウを前面に
    [[[theDoc editorView] window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)swapColor:(id)sender
// 文字色／背景色入れ換え
// ------------------------------------------------------
{
    NSString *theCodeStr = [_foreColorComboBox stringValue];

    [[_foreColorComboBox window] makeFirstResponder:_foreColorComboBox];
    [_foreColorComboBox setStringValue:[_backgroundColorComboBox stringValue]];
    [[_backgroundColorComboBox window] makeFirstResponder:_backgroundColorComboBox];
    [_backgroundColorComboBox setStringValue:theCodeStr];
    [[_foreColorComboBox window] makeFirstResponder:_foreColorComboBox];
    // 適正値かどうかの判断基準フラグを初期化
    [self setupHCCIsOk];
    // 背景色を強制的に更新
    [_sampleTextField setBackgroundColor:[_backgroundColorWell color]];
}


// ------------------------------------------------------
- (IBAction)toggleDisclosureButton:(id)sender
// ディスクロージャボタンでの表示切り替え
// ------------------------------------------------------
{
    NSRect theOptionFrame = [_optionView frame];
    NSRect theWindowFrame = [[_optionView window] frame];

    if ([sender state] == NSOnState) {
        theOptionFrame.origin.y -= k_optionViewHeight;
        theOptionFrame.size.height = k_optionViewHeight;
        theWindowFrame.origin.y -= k_optionViewHeight;
        theWindowFrame.size.height += k_optionViewHeight;
    } else {
        theOptionFrame.origin.y += k_optionViewHeight;
        theOptionFrame.size.height = 0.0;
        theWindowFrame.origin.y += k_optionViewHeight;
        theWindowFrame.size.height -= k_optionViewHeight;
    }
    [_optionView setFrame:theOptionFrame];
    [[_optionView window] setFrame:theWindowFrame display:YES animate:NO];
}


// ------------------------------------------------------
- (IBAction)addComboBoxDataCurrentString:(id)sender
// コンボボックスのリストに現在の値を加える
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // フォーカスを移して値を確定
    [[sender window] makeFirstResponder:sender];

    // 正しい値が入力されているときのみ、リストへの追加を行う
    if (([sender tag] == k_addCodeToForeButtonTag) && 
            ([[theValues valueForKey:k_key_foreColorCBoxIsOk] boolValue])) {
        [_foreColorDataController addObject:
                @{k_HCCDataControllerKey: [_foreColorComboBox stringValue]}];
    } else if (([sender tag] == k_addCodeToBackButtonTag) && 
            ([[theValues valueForKey:k_key_backgroundColorCBoxIsOk] boolValue])) {
        [_backColorDataController addObject:
                @{k_HCCDataControllerKey: [_backgroundColorComboBox stringValue]}];
    }
}



@end

@implementation CEHCCManager (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (void)setupWindowPosition
// 記憶されたパネル位置を是正（ディスクロージャ矢印で表示される部分だけ下部に長く保存されている）
//------------------------------------------------------
{
    NSPoint theOrigin = [[_sampleTextField window] frame].origin;
    theOrigin.y -= k_optionViewHeight;
    [[_sampleTextField window] setFrameOrigin:theOrigin];
}


//------------------------------------------------------
- (void)setupHCCIsOk
// 適正値かどうかの判断基準フラグを初期化
//------------------------------------------------------
{
    [self checkComboBox:_foreColorComboBox string:[_foreColorComboBox stringValue]];
    [self checkComboBox:_backgroundColorComboBox string:[_backgroundColorComboBox stringValue]];
}

//------------------------------------------------------
- (void)setSampleTextFieldBackgroundColor:(NSNotification *)inNotification
// （カラーウェルの変更にともなって）サンプル表示の背景色をセット
//------------------------------------------------------
{
    // （バインディングが設定できないので、ノーティフィケーションで行っている）

    // 別のカラーウェルのものだったら、無視
    if ((![[_sampleTextField window] isKeyWindow]) || (![_backgroundColorWell isActive])) {
        return;
    }
    id theColorPanel = [inNotification object];
    NSColor *theColor = [theColorPanel color];

    if (theColor != nil) {
        [_sampleTextField setBackgroundColor:theColor];
    }
}


//------------------------------------------------------
- (void)importHexColorCode:(NSString *)inCodeString to:(id)inControl
// 文字列をカラーコードとしてコンボボックスへ取り込む
//------------------------------------------------------
{
    NSString *theString = nil;
    BOOL theBoolIsHex = NO;

    if (([inCodeString length] == 7) && 
            ([[inCodeString substringToIndex:1] isEqualToString:@"#"])) {
        theString = [inCodeString substringFromIndex:1];
    } else if ([inCodeString length] == 6) {
        theString = inCodeString;
    }
    if ([theString length] == 6) {
        NSCharacterSet *theSet = 
                [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSInteger i;

        for (i = 0; i < 6; i++) {
            theBoolIsHex = [theSet characterIsMember:[theString characterAtIndex:i]];
            if (!theBoolIsHex) {
                break;
            }
        }
    }
    // 正しいカラーコードのみ取り込む
    if ((theString != nil) && (theBoolIsHex)) {
        [[inControl window] makeFirstResponder:inControl];
        [inControl setStringValue:theString];
        // いったん、レスポンダをウィンドウにして値を確定、他のコントロールに反映させる
        [[inControl window] makeFirstResponder:[inControl window]];
    }
    [[inControl window] makeKeyAndOrderFront:self];
    [[inControl window] makeFirstResponder:inControl];
}


//------------------------------------------------------
- (void)checkComboBox:(id)inControl string:(NSString *)inString
// コンボボックスの値をチェック、不正なら背景色を変更する
//------------------------------------------------------
{
    NSString *theKeyName = nil;
    BOOL theBoolIsOk = NO;

    if ((inString != nil) && ([inString length] == 6)) {
        NSCharacterSet *theSet = 
                [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSInteger i;

        theBoolIsOk = YES;
        for (i = 0; i < 6; i++) {
            if (![theSet characterIsMember:[inString characterAtIndex:i]]) {
                theBoolIsOk = NO;
                break;
            }
        }
    }
    if (theBoolIsOk) {
        [(NSComboBox *)inControl setBackgroundColor:[NSColor controlBackgroundColor]];
    } else {
        [(NSComboBox *)inControl setBackgroundColor:
                [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.5 alpha:1.0]];
        NSBeep();
    }
    if ([inControl isEqualTo:_foreColorComboBox]) {
        theKeyName = k_key_foreColorCBoxIsOk;
    } else if ([inControl isEqualTo:_backgroundColorComboBox]) {
        theKeyName = k_key_backgroundColorCBoxIsOk;
    }
    [[[NSUserDefaultsController sharedUserDefaultsController] defaults] 
        setValue:@(theBoolIsOk) forKey:theKeyName];
}



@end
