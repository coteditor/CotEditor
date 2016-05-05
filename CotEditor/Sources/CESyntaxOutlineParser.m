/*
 
 CESyntaxOutlineParser.m
 
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

#import "CESyntaxOutlineParser.h"
#import "Constants.h"


// Outline item dict keys
NSString *_Nonnull const CEOutlineItemTitleKey = @"outlineItemTitle";
NSString *_Nonnull const CEOutlineItemRangeKey = @"outlineItemRange";
NSString *_Nonnull const CEOutlineItemStyleBoldKey = @"outlineItemStyleBold";
NSString *_Nonnull const CEOutlineItemStyleItalicKey = @"outlineItemStyleItalic";
NSString *_Nonnull const CEOutlineItemStyleUnderlineKey = @"outlineItemStyleUnderline";


@interface CESyntaxOutlineParser ()

@property (nonatomic, nonnull) NSString *string;

@property (nonatomic, nullable) NSArray<NSDictionary *> *definitions;

@end




#pragma mark -

@implementation CESyntaxOutlineParser

#pragma mark Superclass Methods

//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithString:(nonnull NSString *)string definitions:(nonnull NSArray<NSDictionary *> *)definitions
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // make sure the string is immutable
        //   -> [note] NSTextStorage's `string` property retruns mutable string
        _string = [NSString stringWithString:string];
        
        _definitions = definitions;
    }
    return self;
}


// ------------------------------------------------------
/// parse string in background and return extracted outline items
- (void)parseWithCompletionHandler:(nullable void (^)(NSArray<NSDictionary<NSString *,id> *> * _Nonnull))completionHandler
// ------------------------------------------------------
{
    NSString *string = [self string];
    NSArray<NSDictionary *> *definitions = [self definitions];
    
    if ([string length] == 0 || [definitions count] == 0) {
        // just return empty array
        if (completionHandler) {
            completionHandler(@[]);
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSMutableArray<NSDictionary<NSString *, id> *> *outlineItems = [NSMutableArray array];
        
        for (NSDictionary<NSString *, id> *definition in definitions) {
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
            
            [regex enumerateMatchesInString:string
                                    options:0
                                      range:NSMakeRange(0, [string length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 NSRange range = [result range];
                 
                 // separator item
                 if ([template isEqualToString:CESeparatorString]) {
                     [outlineItems addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                               CEOutlineItemTitleKey: CESeparatorString}];
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
                 
                 // font styles (unwrap once to avoid setting nil to dict)
                 BOOL isBold = [definition[CESyntaxBoldKey] boolValue];
                 BOOL isItalic = [definition[CESyntaxItalicKey] boolValue];
                 BOOL isUnderline = [definition[CESyntaxUnderlineKey] boolValue];
                 
                 // append outline item
                 [outlineItems addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                           CEOutlineItemTitleKey: title,
                                           CEOutlineItemStyleBoldKey: @(isBold),
                                           CEOutlineItemStyleItalicKey: @(isItalic),
                                           CEOutlineItemStyleUnderlineKey: @(isUnderline)}];
             }];
        }
        
        if ([outlineItems count] > 0) {
            // sort by location
            [outlineItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSRange range1 = [obj1[CEOutlineItemRangeKey] rangeValue];
                NSRange range2 = [obj2[CEOutlineItemRangeKey] rangeValue];
                
                if (range1.location > range2.location) {
                    return NSOrderedDescending;
                } else if (range1.location < range2.location) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedSame;
                }
            }];
        }
        
        if (completionHandler) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completionHandler([NSArray arrayWithArray:outlineItems]);
            });
        }
    });
}

@end
