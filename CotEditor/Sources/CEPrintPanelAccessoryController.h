/*
 
 CEPrintAccessoryViewController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-24.

 ------------------------------------------------------------------------------
 
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
#import "Constants.h"


@interface CEPrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

@property (readonly, nonatomic, nonnull) NSString *theme;
@property (readonly, nonatomic) CELineNumberPrintMode lineNumberMode;
@property (readonly, nonatomic) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (readonly, nonatomic) BOOL printsHeader;
@property (readonly, nonatomic) CEPrintInfoType headerOneInfoType;
@property (readonly, nonatomic) CEAlignmentType headerOneAlignmentType;
@property (readonly, nonatomic) CEPrintInfoType headerTwoInfoType;
@property (readonly, nonatomic) CEAlignmentType headerTwoAlignmentType;
@property (readonly, nonatomic) BOOL printsHeaderSeparator;

@property (readonly, nonatomic) BOOL printsFooter;
@property (readonly, nonatomic) CEPrintInfoType footerOneInfoType;
@property (readonly, nonatomic) CEAlignmentType footerOneAlignmentType;
@property (readonly, nonatomic) CEPrintInfoType footerTwoInfoType;
@property (readonly, nonatomic) CEAlignmentType footerTwoAlignmentType;
@property (readonly, nonatomic) BOOL printsFooterSeparator;

@end
