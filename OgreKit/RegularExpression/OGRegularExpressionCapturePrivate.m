/*
 * Name: OGRegularExpressionCapturePrivate.m
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */


#import <OgreKit/OGRegularExpressionCapturePrivate.h>


@implementation OGRegularExpressionCapture (Private)

- (id)initWithTreeNode:(OnigCaptureTreeNode*)captureNode 
    index:(unsigned)index 
    level:(unsigned)level 
    parentNode:(OGRegularExpressionCapture*)parentNode 
    match:(OGRegularExpressionMatch*)match
{
    self = [super init];
    if (self != nil) {
        _captureNode = captureNode;
        _index = index;
        _level = level;
        _parent = [parentNode retain];
        _match = [match retain];
    }
    return self;
}

- (void)dealloc
{
    [_parent release];
    [_match release];
    [super dealloc];
}

- (OnigCaptureTreeNode*)_captureNode
{
    return _captureNode;
}

@end
