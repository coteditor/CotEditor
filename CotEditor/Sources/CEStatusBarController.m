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
#import "CEDocumentAnalyzer.h"
#import "CEDefaults.h"


@interface CEStatusBarController ()

@property (nonatomic, nonnull) NSByteCountFormatter *byteCountFormatter;

@property (nonatomic) BOOL showsReadOnly;
@property (nonatomic, nullable, copy) NSAttributedString *editorStatus;
@property (nonatomic, nullable, copy) NSAttributedString *documentStatus;

@end



@interface NSMutableAttributedString (LabelAddition)

- (void)appendFromattedState:(nullable NSString *)value label:(nullable NSString *)label;

@end




#pragma mark -

@implementation CEStatusBarController

#pragma mark View Controller Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        [_byteCountFormatter setAdaptive:NO];
        
        // observe change of defaults
        for (NSString *key in [[self class] observedDefaultKeys]) {
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:key options:0 context:NULL];
        }
    }
    return self;
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
/// request analyzer to update editor info
- (void)viewWillAppear
// ------------------------------------------------------
{
    [super viewWillAppear];
    
    [[self documentAnalyzer] setNeedsUpdateStatusEditorInfo:YES];
}


// ------------------------------------------------------
/// request analyzer to stop updating editor info
- (void)viewDidDisappear
// ------------------------------------------------------
{
    [super viewDidDisappear];
    
    [[self documentAnalyzer] setNeedsUpdateStatusEditorInfo:NO];
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
/// set analyzer
- (void)setDocumentAnalyzer:(CEDocumentAnalyzer *)documentAnalyzer
// ------------------------------------------------------
{
    [[self documentAnalyzer] setNeedsUpdateStatusEditorInfo:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _documentAnalyzer = documentAnalyzer;
    
    [documentAnalyzer setNeedsUpdateStatusEditorInfo:![[self view] isHidden]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEditorStatus)
                                                 name:CEAnalyzerDidUpdateEditorInfoNotification
                                               object:documentAnalyzer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDocumentStatus)
                                                 name:CEAnalyzerDidUpdateFileInfoNotification
                                               object:documentAnalyzer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDocumentStatus)
                                                 name:CEAnalyzerDidUpdateModeInfoNotification
                                               object:documentAnalyzer];
    
    [self updateEditorStatus];
    [self updateDocumentStatus];
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
    if ([[self view] isHidden]) { return; }
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CEDocumentAnalyzer *info = [self documentAnalyzer];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarLinesKey]) {
        [status appendFromattedState:[info lines] label:@"Lines"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
        [status appendFromattedState:[info chars] label:@"Chars"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
        [status appendFromattedState:[info length] label:@"Length"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
        [status appendFromattedState:[info words] label:@"Words"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
        [status appendFromattedState:[info location] label:@"Location"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
        [status appendFromattedState:[info line] label:@"Line"];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
        [status appendFromattedState:[info column] label:@"Column"];
    }
    
    [self setEditorStatus:status];
}


// ------------------------------------------------------
/// update right side text and readonly icon state
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    if ([[self view] isHidden]) { return; }
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CEDocumentAnalyzer *info = [self documentAnalyzer];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarEncodingKey]) {
        [status appendFromattedState:[info charsetName] label:nil];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineEndingsKey]) {
        [status appendFromattedState:[info lineEndings] label:nil];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarFileSizeKey]) {
        NSString *fileSize = [[self byteCountFormatter] stringForObjectValue:[info fileSize]];
        [status appendFromattedState:fileSize label:nil];
    }
    
    [self setDocumentStatus:status];
    
    [self setShowsReadOnly:[info isReadOnly]];
}

@end




#pragma mark -

@implementation NSMutableAttributedString (LabelAddition)

// ------------------------------------------------------
/// append formatted state
- (void)appendFromattedState:(nullable NSString *)value label:(nullable NSString *)label
// ------------------------------------------------------
{
    if ([self length] > 0) {
        [self appendAttributedString:[[NSAttributedString alloc] initWithString:@"   "]];
    }
    
    if (label) {
        NSString *localizedLabel = [NSString stringWithFormat:NSLocalizedString(@"%@: ", nil), NSLocalizedString(label, nil)];
        NSAttributedString *attrLabel = [[NSAttributedString alloc] initWithString:localizedLabel
                                                                        attributes:@{NSForegroundColorAttributeName: [NSColor secondaryLabelColor]}];
        [self appendAttributedString:attrLabel];
    }
    
    NSAttributedString *attrValue;
    if (value) {
        attrValue = [[NSAttributedString alloc] initWithString:value];
    } else {
        attrValue = [[NSAttributedString alloc] initWithString:@"-"
                                                    attributes:@{NSForegroundColorAttributeName: [NSColor disabledControlTextColor]}];
    }
    [self appendAttributedString:attrValue];
}


@end
