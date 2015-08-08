/*
 
 CEPrintView.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-10-01.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

@import Cocoa;
#import "CETextViewProtocol.h"


// constants
extern CGFloat const kHorizontalPrintMargin;  // left/light margin
extern CGFloat const kVerticalPrintMargin;    // top/bottom margin


@class CEPrintPanelAccessoryController;


@interface CEPrintView : NSTextView <CETextViewProtocol>

@property (nonatomic, nullable) CEPrintPanelAccessoryController *printPanelAccessoryController;

@property (nonatomic, nullable, copy) NSString *filePath;
@property (nonatomic, nullable, copy) NSString *documentName;
@property (nonatomic, nullable, copy) NSString *syntaxName;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic, nullable) CETheme *theme;

// settings on current window to be set by CEDocument.
// These values are used if set option is "Same as document's setting"
@property (nonatomic) BOOL documentShowsLineNum;
@property (nonatomic) BOOL documentShowsInvisibles;

@end
