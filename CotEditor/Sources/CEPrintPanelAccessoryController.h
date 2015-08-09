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
extern NSString *__nonnull const CEPrintThemeKey;
extern NSString *__nonnull const CEPrintLineNumberKey;
extern NSString *__nonnull const CEPrintInvisiblesKey;
extern NSString *__nonnull const CEPrintHeaderKey;
extern NSString *__nonnull const CEPrimaryHeaderContentKey;
extern NSString *__nonnull const CESecondaryHeaderContentKey;
extern NSString *__nonnull const CEPrimaryHeaderAlignmentKey;
extern NSString *__nonnull const CESecondaryHeaderAlignmentKey;
extern NSString *__nonnull const CEPrintFooterKey;
extern NSString *__nonnull const CEPrimaryFooterContentKey;
extern NSString *__nonnull const CESecondaryFooterContentKey;
extern NSString *__nonnull const CEPrimaryFooterAlignmentKey;
extern NSString *__nonnull const CESecondaryFooterAlignmentKey;


@interface CEPrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

@end
