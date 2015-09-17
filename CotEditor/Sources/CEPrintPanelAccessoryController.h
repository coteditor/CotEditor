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


// print setting keys
extern NSString *_Nonnull const CEPrintThemeKey;
extern NSString *_Nonnull const CEPrintLineNumberKey;
extern NSString *_Nonnull const CEPrintInvisiblesKey;
extern NSString *_Nonnull const CEPrintHeaderKey;
extern NSString *_Nonnull const CEPrimaryHeaderContentKey;
extern NSString *_Nonnull const CESecondaryHeaderContentKey;
extern NSString *_Nonnull const CEPrimaryHeaderAlignmentKey;
extern NSString *_Nonnull const CESecondaryHeaderAlignmentKey;
extern NSString *_Nonnull const CEPrintFooterKey;
extern NSString *_Nonnull const CEPrimaryFooterContentKey;
extern NSString *_Nonnull const CESecondaryFooterContentKey;
extern NSString *_Nonnull const CEPrimaryFooterAlignmentKey;
extern NSString *_Nonnull const CESecondaryFooterAlignmentKey;


@interface CEPrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

@end
