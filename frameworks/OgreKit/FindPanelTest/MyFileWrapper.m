/*
 * Name: MyFileWrapper.m
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyFileWrapper.h"


@implementation MyFileWrapper

- (id)initWithName:(NSString*)name path:(NSString*)path parent:(id)parent
{
    self = [super init];
    if (self != nil) {
        _name = [name retain];
        _path = [path retain];
        _parent = parent;

        _icon = [[[NSWorkspace sharedWorkspace] iconForFile:_path] retain];
        [_icon setSize:NSMakeSize(16, 16)];

        NSFileManager *manager = [NSFileManager defaultManager];
        [manager fileExistsAtPath:_path isDirectory:&_isDirectory];

        _info = [[NSMutableString alloc] init];
        NSNumber        *fsize;
        NSDate          *moddate;
#ifdef MAC_OS_X_VERSION_10_6
        NSDictionary    *fattrs = [manager attributesOfItemAtPath:_path error:NULL];
#else
        NSDictionary    *fattrs = [manager fileAttributesAtPath:_path traverseLink:YES];
#endif
        
        if (fattrs != nil) {
            if ((moddate = [fattrs objectForKey:NSFileModificationDate]) != nil)
                [_info appendFormat:@"Modif Date: %@,\t", [moddate description]];   
                
            if ((fsize = [fattrs objectForKey:NSFileSize]) != nil)
                [_info appendFormat:@"Size: %d", [fsize intValue]];
        }
    }
    return self;
}

- (void)initComponents
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_path isDirectory:&_isDirectory] && _isDirectory) {
#ifdef MAC_OS_X_VERSION_10_6
        NSArray *subpaths = [manager contentsOfDirectoryAtPath:_path error:NULL];
#else
        NSArray *subpaths = [manager directoryContentsAtPath:_path];
#endif
        _components = [[NSMutableArray alloc] initWithCapacity:[subpaths count]];
        NSString        *subpath;
        NSEnumerator    *subpathE = [subpaths objectEnumerator];
        while ((subpath = [subpathE nextObject]) != nil) {
            [_components addObject:[[[[self class] alloc] initWithName:subpath path:[_path stringByAppendingPathComponent:subpath] parent:self] autorelease]];
        }
    }
}

- (void)dealloc
{
    [_name release];
    [_path release];
    [_info release];
    [_icon release];
    [_components release];
    [super dealloc];
}

- (NSString*)name
{
    return _name;
}

- (NSString*)path
{
    return _path;
}

- (NSImage*)icon
{
    return _icon;
}

- (NSString*)info
{
    return _info;
}

- (BOOL)isDirectory
{
    return _isDirectory;
}

- (NSArray*)components
{
    if (_isDirectory && (_components == nil)) [self initComponents];
    return _components;
}

- (id)componentAtIndex:(unsigned)index
{
    if (_isDirectory && (_components == nil)) [self initComponents];
    return [_components objectAtIndex:index];
}

- (unsigned)numberOfComponents
{
    if (_isDirectory && (_components == nil)) [self initComponents];
    return [_components count];
}

- (void)removeComponent:(id)aComponent
{
    [_components removeObject:aComponent];
}

- (void)remove
{
    [_parent removeComponent:self];
}

- (NSString*)description
{
    //if (_isDirectory && (_components == nil)) [self initComponents];
    return [NSString stringWithFormat:@"name:%@ %@%@", _name, (_isDirectory? @"components:" : @""), (_components? [_components description] : (_isDirectory? @"UNKNOWN" : @""))];
}

@end
