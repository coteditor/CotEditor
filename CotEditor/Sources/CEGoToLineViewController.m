/*
 
 CEGoToLineViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-07.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CEGoToLineViewController.h"

#import "NSString+CECounting.h"
#import "NSString+CERange.h"


@interface CEGoToLineViewController ()

@property (nonatomic, nonnull) NSTextView *textView;
@property (nonatomic, nonnull, copy) NSString *location;

@end



#pragma mark -

@implementation CEGoToLineViewController

#pragma mark View Controller Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithTextView:(nonnull NSTextView *)textView
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _textView = textView;
        
        NSUInteger lineNumber = [[textView string] lineNumberAtIndex:[textView selectedRange].location];
        NSUInteger lineCount = [[[textView string] substringWithRange:[textView selectedRange]] numberOfLines];
        if (lineCount < 2) {
            _location = [NSString stringWithFormat:@"%li", lineNumber];
        } else {
            _location = [NSString stringWithFormat:@"%li:%li", lineNumber, lineCount];
        }
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"GoToLineView";
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply
- (IBAction)ok:(nullable id)sender
// ------------------------------------------------------
{
    [self selectLocation];
    
    [self dismissController:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// select location in textView
- (BOOL)selectLocation
// ------------------------------------------------------
{
    NSArray<NSString *> *locLen = [[self location] componentsSeparatedByString:@":"];
    
    if ([locLen count] == 0) { return NO; }
    
    NSInteger location = [locLen[0] integerValue];
    NSInteger length = ([locLen count] > 1) ? [locLen[1] integerValue] : 0;
    
    NSTextView *textView = [self textView];
    NSRange range = [[textView string] rangeForLineLocation:location length:length];
    
    if (range.location == NSNotFound) { return NO; }
    
    [textView setSelectedRange:range];
    [textView scrollRangeToVisible:range];
    [textView showFindIndicatorForRange:range];
    
    return YES;
}

@end
