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
#import <OgreKit/OGRegularExpression.h>


extern NSString *_Nonnull const kEscapeCharacter;


typedef NS_ENUM(NSInteger, CETextFinderAction) {
    CETextFinderActionSetReplacementString = 100,
    CETextFinderActionFindAll,
};


@protocol CETextFinderDelegate;


@interface CETextFinder : NSResponder

@property (nonatomic, nullable, weak) IBOutlet id<CETextFinderDelegate> delegate;

@property (nonatomic, nonnull, copy) NSString *findString;
@property (nonatomic, nonnull, copy) NSString *replacementString;

#pragma mark Settings
@property (readonly, nonatomic) BOOL usesRegularExpression;
@property (readonly, nonatomic) BOOL isWrap;
@property (readonly, nonatomic) BOOL inSelection;
@property (readonly, nonatomic) BOOL closesIndicatorWhenDone;
@property (readonly, nonatomic) OgreSyntax syntax;
@property (readonly, nonatomic) unsigned options;


+ (nonnull CETextFinder *)sharedTextFinder;

- (nullable NSString *)selectedString;
- (nullable NSTextView *)client;
- (nullable OGRegularExpression *)regex;
- (NSRange)scopeRange;
- (nonnull NSString *)sanitizedFindString;
- (OgreSyntax)textFinderSyntax;


// action messages
- (IBAction)showFindPanel:(nullable id)sender;
- (IBAction)findNext:(nullable id)sender;
- (IBAction)findPrevious:(nullable id)sender;
- (IBAction)findSelectedText:(nullable id)sender;
- (IBAction)findAll:(nullable id)sender;
- (IBAction)replace:(nullable id)sender;
- (IBAction)replaceAll:(nullable id)sender;
- (IBAction)replaceAndFind:(nullable id)sender;
- (IBAction)useSelectionForFind:(nullable id)sender;
- (IBAction)useSelectionForReplace:(nullable id)sender;

@end


@protocol CETextFinderClientProvider <NSObject>

@required
- (nullable NSTextView *)focusedTextView;

@end


@protocol CETextFinderDelegate <NSObject>

@optional
- (void)textFinder:(nonnull CETextFinder *)textFinder didFindAll:(nonnull NSArray<NSDictionary *> *)results findString:(nonnull NSString *)findString textView:(nonnull NSTextView *)textView;

@end
