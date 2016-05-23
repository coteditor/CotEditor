/*
 
 CEStatusBarController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-11.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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
#import "CEDocument.h"
#import "CEDocumentAnalyzer.h"
#import "CEDefaults.h"


static const CGFloat kDefaultHeight = 20.0;
static const NSTimeInterval kDuration = 0.12;


@interface CEStatusBarController ()

@property (nonatomic, nullable, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic) BOOL showsReadOnly;
@property (nonatomic, nullable, copy) NSAttributedString *editorStatus;
@property (nonatomic, nullable, copy) NSAttributedString *documentStatus;

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
    
    for (NSString *key in [[self class] observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// awake from nib
- (void)awakeFromNib
// ------------------------------------------------------
{
    [super awakeFromNib];
    
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
    
    // observe change of defaults
    for (NSString *key in [[self class] observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:key options:0 context:NULL];
    }
}


// ------------------------------------------------------
/// apply change of user setting
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([[[self class] observedDefaultKeys] containsObject:keyPath]) {
        [self updateEditorStatus];
        [self updateDocumentStatus];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
///
- (void)setShown:(BOOL)shown
// ------------------------------------------------------
{
    [[self documentAnalyzer] setNeedsUpdateStatusEditorInfo:shown];
    
    _shown = shown;
}

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
/// default keys to observe update
+ (nonnull NSArray<NSString *> *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultShowStatusBarLinesKey,
             CEDefaultShowStatusBarCharsKey,
             CEDefaultShowStatusBarLengthKey,
             CEDefaultShowStatusBarWordsKey,
             CEDefaultShowStatusBarLocationKey,
             CEDefaultShowStatusBarLineKey,
             CEDefaultShowStatusBarColumnKey,
             
             CEDefaultShowStatusBarEncodingKey,
             CEDefaultShowStatusBarLineEndingsKey,
             CEDefaultShowStatusBarFileSizeKey,
             ];
}


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
        [self appendFormattedState:[info lines] label:@"Lines" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
        [self appendFormattedState:[info chars] label:@"Chars" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
        [self appendFormattedState:[info length] label:@"Length" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
        [self appendFormattedState:[info words] label:@"Words" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
        [self appendFormattedState:[info location] label:@"Location" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
        [self appendFormattedState:[info line] label:@"Line" toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
        [self appendFormattedState:[info column] label:@"Column" toStatusLine:status];
    }
    
    [self setEditorStatus:status];
}


// ------------------------------------------------------
/// update right side text and readonly icon state
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    if (![self isShown]) { return; }
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CEDocumentAnalyzer *info = [self documentAnalyzer];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarEncodingKey]) {
        [self appendFormattedState:[info charsetName] label:nil toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineEndingsKey]) {
        [self appendFormattedState:[info lineEndings] label:nil toStatusLine:status];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarFileSizeKey]) {
        [self appendFormattedState:[info fileSize] label:nil toStatusLine:status];
    }
    
    [self setDocumentStatus:status];
    
    if ([[[[[self view] window] windowController] document] isInViewingMode]) {  // on Versions browsing mode
        [self setShowsReadOnly:NO];
    } else {
        [self setShowsReadOnly:[info isReadOnly]];
    }
}


// ------------------------------------------------------
/// append formatted state
- (NSAttributedString *)appendFormattedState:(nullable NSString *)value label:(nullable NSString *)label toStatusLine:(nonnull NSMutableAttributedString *)status
// ------------------------------------------------------
{
    if ([status length] > 0) {
        [status appendAttributedString:[[NSAttributedString alloc] initWithString:@"   "]];
    }
    
    if (label) {
        NSString *localizedLabel = [NSString stringWithFormat:NSLocalizedString(@"%@: ", nil), NSLocalizedString(label, nil)];
        NSAttributedString *attrLabel = [[NSAttributedString alloc] initWithString:localizedLabel
                                                                        attributes:@{NSForegroundColorAttributeName: kLabelColor}];
        [status appendAttributedString:attrLabel];
    }
    
    NSAttributedString *attrValue;
    if (value) {
        attrValue = [[NSAttributedString alloc] initWithString:value];
    } else {
        attrValue = [[NSAttributedString alloc] initWithString:@"-"
                                                    attributes:@{NSForegroundColorAttributeName: [NSColor disabledControlTextColor]}];
    }
    [status appendAttributedString:attrValue];
    
    return status;
}

@end
