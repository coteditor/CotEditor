/*
 ==============================================================================
 CEToolbarController
 
 CotEditor
 http://coteditor.github.io
 
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
#import "CEByteCountTransformer.h"
#import "constants.h"


static const CGFloat kDefaultHeight = 20.0;
static const NSTimeInterval kDuration = 0.1;


@interface CEStatusBarController ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) IBOutlet NSNumberFormatter *decimalFormatter;
@property (nonatomic) CEByteCountTransformer *byteCountTransformer;
@property (nonatomic) NSDictionary *labelAttributes;

@property (nonatomic, copy) NSAttributedString *editorStatus;
@property (nonatomic, copy) NSString *documentStatus;

@end




#pragma mark -

@implementation CEStatusBarController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// init instance
- (instancetype)initWithCoder:(NSCoder *)aDecoder
// ------------------------------------------------------
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _showsStatusBar = YES;
        _byteCountTransformer = [[CEByteCountTransformer alloc] init];
        
        NSColor *labelColor = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
        _labelAttributes = @{NSForegroundColorAttributeName: labelColor};
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// update left side text
- (void)updateEditorStatus
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] init];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarLinesKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Lines"
                                                               value:[self linesInfo]
                                                       selectedValue:[self selectedLinesInfo]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Chars"
                                                               value:[self charsInfo]
                                                       selectedValue:[self selectedCharsInfo]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Length"
                                                               value:[self lengthInfo]
                                                       selectedValue:[self selectedLengthInfo]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Words"
                                                               value:[self wordsInfo]
                                                       selectedValue:[self selectedWordsInfo]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Location"
                                                               value:[self locationInfo]
                                                       selectedValue:-1]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Line"
                                                               value:[self lineInfo]
                                                       selectedValue:-1]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Column"
                                                               value:[self columnInfo]
                                                       selectedValue:-1]];
    }
    
    [self setEditorStatus:status];
}


// ------------------------------------------------------
/// update right side text
- (void)updateDocumentStatus
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *status = [NSMutableArray array];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarEncodingKey]) {
        [status addObject:[self encodingInfo]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineEndingsKey]) {
        [status addObject:[self lineEndingsInfo]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarFileSizeKey]) {
        [status addObject:([self fileSizeInfo] ?
                           [[self byteCountTransformer] transformedValue:@([self fileSizeInfo])] : @"-")];
    }
    
    [self setDocumentStatus:[status componentsJoinedByString:@"   "]];
}


// ------------------------------------------------------
/// update visibility
- (void)setShowsStatusBar:(BOOL)showsStatusBar
// ------------------------------------------------------
{
    _showsStatusBar = showsStatusBar;
    
    CGFloat height = [self showsStatusBar] ? kDefaultHeight : 0.0;
    
    // resize with animation
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        [context setDuration:kDuration];
        [[[self heightConstraint] animator] setConstant:height];
    } completionHandler:nil];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// formatted state
- (NSAttributedString *)formattedStateWithLabel:(NSString *)label value:(NSInteger)value selectedValue:(NSInteger)selectedValue
// ------------------------------------------------------
{
    NSString *localizedLabel = [NSString stringWithFormat:@"%@%@",
                                NSLocalizedString(label, nil), NSLocalizedString(@": ", nil)];
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@%@",
                               localizedLabel, [[self decimalFormatter] stringFromNumber:@(value)]];
    if (selectedValue > 0) {
        [string appendFormat:@" (%@)", [[self decimalFormatter] stringFromNumber:@(selectedValue)]];
    }
    [string appendString:@"   "];  // buffer to the next state
    
    NSMutableAttributedString *state = [[NSMutableAttributedString alloc] initWithString:string];
    
    [state addAttributes:[self labelAttributes] range:NSMakeRange(0, [localizedLabel length])];
    
    return [state copy];
}

@end
