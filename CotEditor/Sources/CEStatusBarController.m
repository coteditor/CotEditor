/*
 
 CEStatusBarController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-11.

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

#import "CEStatusBarController.h"
#import "CEDocumentAnalyzer.h"
#import "Constants.h"


static const CGFloat kDefaultHeight = 20.0;
static const NSTimeInterval kDuration = 0.25;


@interface CEStatusBarController ()

@property (nonatomic, nullable, weak) IBOutlet CEDocumentAnalyzer *documentAnalyzer;
@property (nonatomic, nullable, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic) BOOL showsReadOnly;
@property (nonatomic, nullable, copy) NSAttributedString *editorStatus;
@property (nonatomic, nullable, copy) NSString *documentStatus;

// readonly
@property (readwrite, nonatomic, getter=isShown) BOOL shown;

@end




#pragma mark -

@implementation CEStatusBarController

static NSColor *kLabelColor;


#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kLabelColor = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
    });
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// awake from nib
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEditorStatus)
                                                 name:CEAnalyzerDidUpdateEditorInfoNotification
                                               object:[self documentAnalyzer]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDocumentStatus)
                                                 name:CEAnalyzerDidUpdateFileInfoNotification
                                               object:[self documentAnalyzer]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDocumentStatus)
                                                 name:CEAnalyzerDidUpdateModeInfoNotification
                                               object:[self documentAnalyzer]];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// update visibility
- (void)setShown:(BOOL)isShown animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    [self setShown:isShown];
    
    if (isShown) {
        [self updateEditorStatus];
        [self updateDocumentStatus];
    }
    
    NSLayoutConstraint *heightConstraint = [self heightConstraint];
    CGFloat height = isShown ? kDefaultHeight : 0.0;
    
    if (performAnimation) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:kDuration];
            [[heightConstraint animator] setConstant:height];
        } completionHandler:nil];
        
    } else {
        [heightConstraint setConstant:height];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// update left side text
- (void)updateEditorStatus
// ------------------------------------------------------
{
    if (![self isShown]) { return; }
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CEDocumentAnalyzer *info = [self documentAnalyzer];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarLinesKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Lines" value:[info lines]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Chars" value:[info chars]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Length" value:[info length]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Words" value:[info words]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Location" value:[info location]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Line" value:[info line]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Column" value:[info column]]];
    }
    
    [self setEditorStatus:status];
}


// ------------------------------------------------------
/// update right side text and readonly icon state
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    if (![self isShown]) { return; }
    
    NSMutableArray<NSString *> *status = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CEDocumentAnalyzer *info = [self documentAnalyzer];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarEncodingKey]) {
        [status addObject:([info charsetName] ?: @"-")];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineEndingsKey]) {
        [status addObject:([info lineEndings] ?: @"-")];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarFileSizeKey]) {
        [status addObject:([info fileSize] ?: @"-")];
    }
    
    [self setDocumentStatus:[status componentsJoinedByString:@"   "]];
    
    if ([[[[[self view] window] windowController] document] isInViewingMode]) {  // on Versions browsing mode
        [self setShowsReadOnly:NO];
    } else {
        [self setShowsReadOnly:![info isWritable]];
    }
}


// ------------------------------------------------------
/// formatted state
- (NSAttributedString *)formattedStateWithLabel:(nonnull NSString *)label value:(nullable NSString *)value
// ------------------------------------------------------
{
    NSString *localizedLabel = [NSString stringWithFormat:NSLocalizedString(@"%@: ", nil), NSLocalizedString(label, nil)];
    NSString *string = [NSString stringWithFormat:@"%@%@   ", localizedLabel, value];
    
    NSMutableAttributedString *state = [[NSMutableAttributedString alloc] initWithString:string];
    
    [state addAttribute:NSForegroundColorAttributeName
                  value:kLabelColor
                  range:NSMakeRange(0, [localizedLabel length])];
    
    return [state copy];
}

@end
