/*
 
 CETextFinder.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-03.

 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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


// keys for Find All result
extern NSString * _Nonnull const CEFindResultRange;  // NSRange in NSValue
extern NSString * _Nonnull const CEFindResultLineNumber;  // NSUInteger in NSNumber
extern NSString * _Nonnull const CEFindResultAttributedLineString;  // NSAttributedString
extern NSString * _Nonnull const CEFindResultLineRange;  // NSRange in NSValue


typedef NS_ENUM(NSInteger, CETextFinderAction) {
    CETextFinderActionSetReplacementString = 100,
    CETextFinderActionFindAll,
};


@protocol CETextFinderDelegate;


@interface CETextFinder : NSResponder

@property (nonatomic, nullable, weak) IBOutlet id<CETextFinderDelegate> delegate;

@property (nonatomic, nonnull, copy) NSString *findString;
@property (nonatomic, nonnull, copy) NSString *replacementString;

@property (readonly, nonatomic, nonnull) NSColor *highlightColor;


+ (nonnull CETextFinder *)sharedTextFinder;


// action messages
- (IBAction)showFindPanel:(nullable id)sender;
- (IBAction)findNext:(nullable id)sender;
- (IBAction)findPrevious:(nullable id)sender;
- (IBAction)findSelectedText:(nullable id)sender;
- (IBAction)findAll:(nullable id)sender;
- (IBAction)replace:(nullable id)sender;
- (IBAction)replaceAndFind:(nullable id)sender;
- (IBAction)replaceAll:(nullable id)sender;
- (IBAction)useSelectionForFind:(nullable id)sender;
- (IBAction)useSelectionForReplace:(nullable id)sender;
- (IBAction)centerSelectionInVisibleArea:(nullable id)sender;

@end


@protocol CETextFinderClientProvider <NSObject>

@required
- (nullable NSTextView *)focusedTextView;

@end


@protocol CETextFinderDelegate <NSObject>

@optional
- (void)textFinder:(nonnull CETextFinder *)textFinder didFinishFindingAll:(nonnull NSString *)findString results:(nonnull NSArray<NSDictionary *> *)results textView:(nonnull NSTextView *)textView;
- (void)textFinder:(nonnull CETextFinder *)textFinder didFound:(NSInteger)numberOfFound textView:(nonnull NSTextView *)textView;

- (void)textFinderDidUpdateFindHistory;
- (void)textFinderDidUpdateReplaceHistory;

@end
