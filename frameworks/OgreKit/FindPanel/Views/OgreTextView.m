/*
 * Name: OgreTextView.m
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextView.h>
#import <OgreKit/OgreTextViewAdapter.h>


@implementation OgreTextView

- (NSObject <OgreTextFindComponent>*)ogreAdapter
{
    return [[[OgreTextViewAdapter alloc] initWithTarget:self] autorelease];
}

- (void)bind:(NSString *)binding toObject:(id)observableController withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    //NSLog(@"bind:%@ toObject:%@ withKeyPath:%@ options:%@", binding, [observableController className], keyPath, [options description]);
    
    if ([binding isEqualToString:@"data"]) {
        _observableControllerForDataBinding = observableController; // no retain
        [_keyPathForDataBinding autorelease];
        _keyPathForDataBinding = [keyPath retain];
    } else if ([binding isEqualToString:@"value"]) {
        _observableControllerForValueBinding = observableController; // no retain
        [_keyPathForValueBinding autorelease];
        _keyPathForValueBinding = [keyPath retain];
    }
    
    [super bind:binding toObject:observableController withKeyPath:keyPath options:options];
}

- (void)unbind:(NSString *)binding
{
    [super unbind:binding];
    
    if ([binding isEqualToString:@"data"]) {
        _observableControllerForDataBinding = nil;
        [_keyPathForDataBinding release];
        _keyPathForDataBinding = nil;
    } else if ([binding isEqualToString:@"value"]) {
        _observableControllerForValueBinding = nil;
        [_keyPathForValueBinding release];
        _keyPathForValueBinding = nil;
    }
}

- (void)dealloc
{
    [_keyPathForDataBinding release];
    [_keyPathForValueBinding release];
    [super dealloc];
}

- (void)ogreDidEndEditing
{
    if (_observableControllerForDataBinding != nil) {
        NSData  *newData;
        if ([self importsGraphics]) {
            newData = [self RTFDFromRange:NSMakeRange(0, [[self string] length])];
        } else {
            newData = [self RTFFromRange:NSMakeRange(0, [[self string] length])];
        }
        [_observableControllerForDataBinding setValue:newData forKeyPath:_keyPathForDataBinding];
    } else if (_observableControllerForValueBinding != nil) {
        NSTextStorage   *textStorage = [self textStorage];
        NSString        *newString = [NSString stringWithString:[textStorage string]];  // copy
        [_observableControllerForValueBinding setValue:newString forKeyPath:_keyPathForValueBinding];
    }
}

@end
