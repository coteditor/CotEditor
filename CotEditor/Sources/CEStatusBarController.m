/*
 ==============================================================================
 CEStatusBarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-11 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEStatusBarController.h"
#import "CEDocumentAnalyzer.h"
#import "constants.h"


static const CGFloat kDefaultHeight = 20.0;
static const NSTimeInterval kDuration = 0.25;


@interface CEStatusBarController ()

@property (nonatomic, weak) IBOutlet CEDocumentAnalyzer *documentAnalyzer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic, copy) NSAttributedString *editorStatus;
@property (nonatomic, copy) NSString *documentStatus;

// readonly
@property (readwrite, nonatomic, getter=isShown) BOOL shown;

@end




#pragma mark -

@implementation CEStatusBarController

static NSColor *kLabelColor;


#pragma mark Class Methods

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



#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// awake from nib
- (void)awakeFromNib
// ------------------------------------------------------
{
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


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// update visibility
- (void)setShown:(BOOL)isShown animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    [self setShown:isShown];
    
    CGFloat height = [self isShown] ? kDefaultHeight : 0.0;
    
    if (performAnimation) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:kDuration];
            [[[self heightConstraint] animator] setConstant:height];
        } completionHandler:nil];
        
    } else {
        [[self heightConstraint] setConstant:height];
    }
    
    if (isShown) {
        [self updateEditorStatus];
        [self updateDocumentStatus];
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
/// update right side text
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    if (![self isShown]) { return; }
    
    NSMutableArray *status = [NSMutableArray array];
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
}


// ------------------------------------------------------
/// formatted state
- (NSAttributedString *)formattedStateWithLabel:(NSString *)label value:(NSString *)value
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
