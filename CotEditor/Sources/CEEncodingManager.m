/*
 
 CEEncodingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-09-24.

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

#import "CEEncodingManager.h"
#import "CEDefaults.h"
#import "CEEncodings.h"


NSString *_Nonnull const CEEncodingListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";


@interface CEEncodingManager ()

// readonly
@property (readwrite, nonatomic, nonnull, copy) NSArray<NSMenuItem *> *encodingMenuItems;

@end




#pragma mark -

@implementation CEEncodingManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CEEncodingManager *)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
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
-(void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:CEDefaultEncodingListKey]) {
        [self buildEncodingMenuItems];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// returns corresponding NSStringEncoding from a encoding name
+ (NSStringEncoding)encodingFromName:(nonnull NSString *)encodingName
// ------------------------------------------------------
{
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingList; i++) {
        CFStringEncoding cfEncoding = kCFStringEncodingList[i];
        
        if (cfEncoding == kCFStringEncodingInvalidId) { continue; }  // = separator
        
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        if ([encodingName isEqualToString:[NSString localizedNameOfStringEncoding:encoding]]) {
            return encoding;
        }
    }
    
    return NSNotFound;
}


// ------------------------------------------------------
/// whether Yen sign (U+00A5) can be converted to the given encoding
+ (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    static NSArray<NSNumber *> *invalidYenEncodings;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray<NSNumber *> *encodings = [NSMutableArray arrayWithCapacity:kSizeOfCFStringEncodingInvalidYenList];
        for (NSUInteger i = 0; i < kSizeOfCFStringEncodingInvalidYenList; i++) {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingInvalidYenList[i]);
            [encodings addObject:@(encoding)];
        }
        
        invalidYenEncodings = [encodings copy];
    });
    
    return [invalidYenEncodings containsObject:@(encoding)];
}


//------------------------------------------------------
/// return copied menu items
- (nonnull NSArray<NSMenuItem *> *)encodingMenuItems
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
    NSArray<NSNumber *> *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    NSMutableArray<NSMenuItem *> *items = [[NSMutableArray alloc] initWithCapacity:[encodings count]];
    
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
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;  // strong self
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CEEncodingListDidUpdateNotification object:self];
    });
}

@end
