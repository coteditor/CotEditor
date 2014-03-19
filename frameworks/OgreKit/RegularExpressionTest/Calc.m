/*
 * Name: Calc.m
 * Project: OgreKit
 *
 * Creation Date: Jun 26 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "Calc.h"


/* calculator with four operations '+', '-', '*', '/' and parentheses '(', ')' */
static NSString *const calcRegex = @"\\g<e>(?<e>\\g<t>(?:(?@<e1>\\+\\g<t>)|(?@<e2>\\-\\g<t>))*){0}(?<t>\\g<f>(?:(?@<t1>\\*\\g<f>)|(?@<t2>/\\g<f>))*){0}(?<f>\\(\\g<e>\\)|(?@<f2>\\d+(?:\\.\\d*)?)){0}";
/*
 calcRegex corresponds to the following EBNF

    <e> ::= <t> { + <t> | - <t> }
    <t> ::= <f> { * <f> | / <f> }
    <f> ::= ( <e> )
        | NUMBERS
 
 Note 1: Left recursive rules is forbidden.
 Note 2: The upper limit of number/kinds of capture history "(?@...)" is 31.
         eg. in the foregoing example, the number of capture history is 5 (e1, e2, t1, t2, f3) <= 31.
 */


@implementation Calc

- (id)init
{
    self = [super init];
    if (self != nil) {
        _stack = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    return self;
}

- (void)dealloc
{
    [_stack release];
    [super dealloc];
}

- (void)push:(id)item
{
    [_stack addObject:item];
}

- (id)pop
{
    if ([_stack count] == 0) return nil;
    
    id  anObject = [[_stack lastObject] retain];
    [_stack removeLastObject];
    
    return [anObject autorelease];
}


/* adapt OGRegularExpressionCaptureVisitor protocol */
- (void)visitAtFirstCapture:(OGRegularExpressionCapture*)aCapture
{
    /*NSMutableString *indent = [NSMutableString string];
    int i;
    for (i = 0; i < [aCapture level]; i++) [indent appendString:@"  "];
    NSRange matchRange = [aCapture range];
    
    NSLog(@" %@#%d(\"%@\"): (%d-%d) \"%@\"", 
        indent, [aCapture groupIndex], [aCapture groupName], 
        matchRange.location, matchRange.length, 
        [aCapture string]);*/
}

- (void)visitAtLastCapture:(OGRegularExpressionCapture*)aCapture
{
    NSString    *name = [aCapture groupName];
    if (name == nil) return;
    
    SEL reduceSelector = NSSelectorFromString([NSString stringWithFormat:@"reduce_%@:", name]);
    [self performSelector:reduceSelector withObject:aCapture];
    
    NSLog(@"Stack: %@ <%@>", [_stack description], name);
}

/* evaluation */
- (id)eval:(NSString*)expression
{
    OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:calcRegex 
        options:OgreCaptureGroupOption 
        syntax:OgreRubySyntax 
        escapeCharacter:OgreBackslashCharacter];
    OGRegularExpressionMatch    *match = [regex matchInString:expression];
    
    if (match == nil || [match rangeOfMatchedString].length != [expression length]) return nil;
    
    [[match captureHistory] acceptVisitor:self];
    return [self pop];
}

- (void)reduce_e1:(OGRegularExpressionCapture*)aCapture
/* <e> ::= <t> + <t> */
{
    id  num2 = [self pop];
    id  num1 = [self pop];
    [self push:[NSNumber numberWithDouble:[num1 doubleValue] + [num2 doubleValue]]];
}

- (void)reduce_t1:(OGRegularExpressionCapture*)aCapture
/* <t> ::= <f> * <f> */
{
    id  num2 = [self pop];
    id  num1 = [self pop];
    [self push:[NSNumber numberWithDouble:[num1 doubleValue] * [num2 doubleValue]]];
}

- (void)reduce_f2:(OGRegularExpressionCapture*)aCapture
/* <f> ::= NUMBERS */
{
    [self push:[aCapture string]];
}

- (void)reduce_e2:(OGRegularExpressionCapture*)aCapture
/* <e> ::= <t> - <t> */
{
    id  num2 = [self pop];
    id  num1 = [self pop];
    [self push:[NSNumber numberWithDouble:[num1 doubleValue] - [num2 doubleValue]]];
}

- (void)reduce_t2:(OGRegularExpressionCapture*)aCapture
/* <t> ::= <f> / <f> */
{
    id  num2 = [self pop];
    id  num1 = [self pop];
    [self push:[NSNumber numberWithDouble:[num1 doubleValue] / [num2 doubleValue]]];
}

@end
