/*
 
 CEOutlineParseOperation.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-06.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEOutlineParseOperation.h"
#import "CEOutlineItem.h"
#import "Constants.h"


@interface CEOutlineParseOperation ()

@property (nonatomic, nonnull) NSArray<NSDictionary *> *definitions;

// readonly
@property (readwrite, nonatomic, nullable, copy) NSArray<CEOutlineItem *> *results;

@end




#pragma mark -

@implementation CEOutlineParseOperation

#pragma mark Superclass Methods

//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// runs asynchronous
- (BOOL)isAsynchronous
//------------------------------------------------------
{
    return YES;
}


//------------------------------------------------------
/// priority of operation
- (NSOperationQueuePriority)queuePriority
//------------------------------------------------------
{
    return NSOperationQueuePriorityLow;
}




#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithDefinitions:(nonnull NSArray<NSDictionary *> *)definitions
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _definitions = definitions;
    }
    return self;
}


// ------------------------------------------------------
/// parse string in background and return extracted outline items
- (void)main
// ------------------------------------------------------
{
    NSString *string = [self string];
    
    if ([string length] == 0 || [[self definitions] count] == 0) { return; }
    
    NSMutableArray<CEOutlineItem *> *outlineItems = [NSMutableArray array];
    
    for (NSDictionary<NSString *, id> *definition in [self definitions]) {
        NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
        if ([definition[CESyntaxIgnoreCaseKey] boolValue]) {
            options |= NSRegularExpressionCaseInsensitive;
        }
        
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:definition[CESyntaxBeginStringKey]
                                                                               options:options
                                                                                 error:&error];
        if (error) {
            NSLog(@"ERROR in \"%s\" with regex pattern \"%@\"", __PRETTY_FUNCTION__, definition[CESyntaxBeginStringKey]);
            continue;  // do nothing
        }
        
        NSString *template = definition[CESyntaxKeyStringKey];
        
        __weak typeof(self) weakSelf = self;
        [regex enumerateMatchesInString:string
                                options:NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                                  range:[self parseRange]
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             if ([weakSelf isCancelled]) {
                 *stop = YES;
                 return;
             }
             
             NSRange range = [result range];
             CEOutlineItem *item = [[CEOutlineItem alloc] init];
             
             // separator item
             if ([template isEqualToString:CESeparatorString]) {
                 [item setTitle:CESeparatorString];
                 [item setRange:range];
                 [outlineItems addObject:item];
                 return;
             }
             
             // menu item title
             NSString *title;
             
             if ([template length] == 0) {
                 // no pattern definition
                 title = [string substringWithRange:range];;
                 
             } else {
                 // replace matched string with template
                 title = [regex replacementStringForResult:result
                                                  inString:string
                                                    offset:0
                                                  template:template];
                 
                 // replace line number ($LN)
                 if ([title rangeOfString:@"$LN"].location != NSNotFound) {
                     // count line number of the beginning of the matched range
                     NSUInteger lineCount = 0, index = 0;
                     while (index <= range.location) {
                         index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
                         lineCount++;
                     }
                     
                     // replace
                     title = [title stringByReplacingOccurrencesOfString:@"(?<!\\\\)\\$LN"
                                                              withString:[NSString stringWithFormat:@"%tu", lineCount]
                                                                 options:NSRegularExpressionSearch
                                                                   range:NSMakeRange(0, [title length])];
                 }
             }
             
             // replace whitespaces
             title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
             
             [item setRange:range];
             [item setTitle:title];
             [item setBold:[definition[CESyntaxBoldKey] boolValue]];
             [item setItalic:[definition[CESyntaxItalicKey] boolValue]];;
             [item setHasUnderline:[definition[CESyntaxUnderlineKey] boolValue]];;
             
             // append outline item
             [outlineItems addObject:item];
         }];
        
        if ([self isCancelled]) { return; }
    }
    
    // sort by location
    [outlineItems sortUsingComparator:^NSComparisonResult(CEOutlineItem *item1, CEOutlineItem *item2) {
        if ([item1 range].location > [item2 range].location) {
            return NSOrderedDescending;
        } else if ([item1 range].location < [item2 range].location) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    [self setResults:outlineItems];
}

@end
