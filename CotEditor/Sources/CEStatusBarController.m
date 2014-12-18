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
#import "CEWindowController.h"
#import "constants.h"


static const CGFloat kDefaultHeight = 20.0;
static const NSTimeInterval kDuration = 0.25;


@interface CEStatusBarController ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) IBOutlet NSNumberFormatter *decimalFormatter;
@property (nonatomic) NSByteCountFormatter *byteCountFormatter;
@property (nonatomic) NSDictionary *labelAttributes;

@property (nonatomic, copy) NSAttributedString *editorStatus;
@property (nonatomic, copy) NSString *documentStatus;

// readonly
@property (readwrite, nonatomic, getter=isShown) BOOL shown;

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
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        
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
    NSDictionary *documentInfo = [self representedObject];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarLinesKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Lines"
                                                               value:documentInfo[CEDocumentLinesKey]
                                                       selectedValue:documentInfo[CEDocumentSelectedLinesKey]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Chars"
                                                               value:documentInfo[CEDocumentCharsKey]
                                                       selectedValue:documentInfo[CEDocumentSelectedCharsKey]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Length"
                                                               value:documentInfo[CEDocumentLengthKey]
                                                       selectedValue:documentInfo[CEDocumentSelectedLengthKey]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Words"
                                                               value:documentInfo[CEDocumentWordsKey]
                                                       selectedValue:documentInfo[CEDocumentSelectedWordsKey]]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Location"
                                                               value:documentInfo[CEDocumentLocationKey]
                                                       selectedValue:nil]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Line"
                                                               value:documentInfo[CEDocumentLineKey]
                                                       selectedValue:nil]];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
        [status appendAttributedString:[self formattedStateWithLabel:@"Column"
                                                               value:documentInfo[CEDocumentColumnKey]
                                                       selectedValue:nil]];
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
    NSDictionary *documentInfo = [self representedObject];
    
    if ([defaults boolForKey:CEDefaultShowStatusBarEncodingKey]) {
        [status addObject:(documentInfo[CEDocumentEncodingKey] ?: @"-")];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarLineEndingsKey]) {
        [status addObject:(documentInfo[CEDocumentLineEndingsKey] ?: @"-")];
    }
    if ([defaults boolForKey:CEDefaultShowStatusBarFileSizeKey]) {
        
        [status addObject:(documentInfo[CEDocumentFileSizeKey] ?
                           [[self byteCountFormatter] stringFromByteCount:documentInfo[CEDocumentFileSizeKey]] : @"-")];
    }
    
    [self setDocumentStatus:[status componentsJoinedByString:@"   "]];
}


// ------------------------------------------------------
/// update visibility
- (void)setShown:(BOOL)isShown animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    [self setShown:isShown];
    
    CGFloat height = [self isShown] ? kDefaultHeight : 0.0;
    
    if (performAnimation) {
        // resize with animation
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [context setDuration:kDuration];
            [[[self heightConstraint] animator] setConstant:height];
        } completionHandler:nil];
        
    } else {
        // resize without animation
        [[self heightConstraint] setConstant:height];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// formatted state
- (NSAttributedString *)formattedStateWithLabel:(NSString *)label value:(NSNumber *)value selectedValue:(NSNumber *)selectedValue
// ------------------------------------------------------
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@%@",
                               localizedLabel, [[self decimalFormatter] stringFromNumber:value]];
    if ([selectedValue integerValue] > 0) {
        [string appendFormat:@" (%@)", [[self decimalFormatter] stringFromNumber:selectedValue]];
    }
    [string appendString:@"   "];  // buffer to the next state
    NSString *localizedLabel = [NSString stringWithFormat:NSLocalizedString(@"%@: ", nil), NSLocalizedString(label, nil)];
    
    NSMutableAttributedString *state = [[NSMutableAttributedString alloc] initWithString:string];
    
    [state addAttributes:[self labelAttributes] range:NSMakeRange(0, [localizedLabel length])];
    
    return [state copy];
}

@end
