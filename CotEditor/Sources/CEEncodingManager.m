/*
 ==============================================================================
 CEEncodingManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-09-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEEncodingManager.h"
#import "constants.h"


NSString *const CEEncodingListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";


@interface CEEncodingManager ()

// readonly
@property (readwrite, nonatomic, copy) NSArray *encodingMenuItems;

@end




#pragma mark -

@implementation CEEncodingManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (CEEncodingManager *)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self buildEncodingMenuItems];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:CEDefaultEncodingListKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultEncodingListKey];
}


// ------------------------------------------------------
/// observed key value did update
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:CEDefaultEncodingListKey]) {
        [self buildEncodingMenuItems];
    }
}



#pragma mark Public Methods

//------------------------------------------------------
/// return copied menu items
- (NSArray *)encodingMenuItems
//------------------------------------------------------
{
    return [[NSArray alloc] initWithArray:_encodingMenuItems copyItems:YES];
}



#pragma mark Private Methods

//------------------------------------------------------
/// build encoding menu items
- (void)buildEncodingMenuItems
//------------------------------------------------------
{
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[encodings count]];
    
    for (NSNumber *encodingNumber in encodings) {
        CFStringEncoding cfEncoding = [encodingNumber unsignedLongValue];
        NSMenuItem *item;
        
        if (cfEncoding == kCFStringEncodingInvalidId) {
            item = [NSMenuItem separatorItem];
        } else {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            NSString *menuTitle = [NSString localizedNameOfStringEncoding:encoding];
            item = [[NSMenuItem alloc] initWithTitle:menuTitle action:NULL keyEquivalent:@""];
            [item setTag:encoding];
        }
        
        [items addObject:item];
    }
    
    [self setEncodingMenuItems:items];
    
    // notify that new encoding menu items was created
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CEEncodingListDidUpdateNotification object:self];
    });
}

@end
