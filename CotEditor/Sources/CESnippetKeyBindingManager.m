/*
 
 CESnippetKeyBindingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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

#import "CESnippetKeyBindingManager.h"
#import "CEKeyBindingItem.h"
#import "CEKeyBindingUtils.h"
#import "CEDefaults.h"
#import "Constants.h"


@interface CESnippetKeyBindingManager ()

@property (nonatomic, nonnull, copy) NSArray<NSString *> *defaultSnippets;

@property (readwrite, nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *defaultKeyBindingDict;

@end




#pragma mark -


@implementation CESnippetKeyBindingManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CESnippetKeyBindingManager *)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Key Binding Manager Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _defaultKeyBindingDict = @{@"$\r": [[self class] selectorStringWithIndex:0]};
        _defaultSnippets = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
        
        // read user key bindings if available
        self.keyBindingDict = [NSDictionary dictionaryWithContentsOfURL:[self keyBindingSettingFileURL]] ?: _defaultKeyBindingDict;
        
    }
    return self;
}


//------------------------------------------------------
/// name of file to save custom key bindings in the plist file form (without extension)
- (nonnull NSString *)settingFileName
//------------------------------------------------------
{
    return @"TextKeyBindings";
}


//------------------------------------------------------
/// create a KVO-compatible dictionary for outlineView in preferences from the key binding setting
/// @param usesFactoryDefaults   YES for default setting and NO for the current setting
- (nonnull NSArray<id<CEKeyBindingItemInterface>> *)bindingItemsForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSMutableArray<CEKeyBindingItem *> *bindingItems = [NSMutableArray array];
    NSDictionary<NSString *, NSString *> *dict = usesFactoryDefaults ? [self defaultKeyBindingDict] : [self keyBindingDict];
    
    for (NSUInteger index = 0; index <= 30; index++) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Insert Text %li", nil), index];
        NSString *selector = [[self class] selectorStringWithIndex:index];
        
        CEKeyBindingItem *item = [[CEKeyBindingItem alloc] initWithTitle:title
                                                                selector:selector
                                                            keySpecChars:[[dict allKeysForObject:selector] firstObject]];
        
        [bindingItems addObject:item];
    }
    
    return [bindingItems copy];
}


// ------------------------------------------------------
/// whether key bindings are not customized
- (BOOL)usesDefaultKeyBindings
// ------------------------------------------------------
{
    BOOL usesDefaultSnippets = [[self snippetsWithFactoryDefaults:NO] isEqualToArray:[self defaultSnippets]];
    
    return usesDefaultSnippets && [super usesDefaultKeyBindings];
}


//------------------------------------------------------
/// validate new key spec chars are settable
- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldKeySpecChars:(nonnull NSString *)oldKeySpecChars error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    BOOL valid = [super validateKeySpecChars:keySpec oldKeySpecChars:oldKeySpecChars error:outError];
    
    // command key existance check
    if (valid && [keySpec containsString:@"@"]) {
        if (outError) {
            *outError = [self errorWithMessageFormat:@"“%@” includes the Command key." keySpecChars:keySpec];
        }
        return NO;
    }
    
    return valid;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// return snippet string for key binding if exists
- (nullable NSString *)snippetWithKeyEquivalent:(nullable NSString *)keyEquivalent modifierMask:(NSEventModifierFlags)modifierMask
// ------------------------------------------------------
{
    if (!keyEquivalent) { return nil; }
    if ((modifierMask & NSDeviceIndependentModifierFlagsMask) == 0) { return nil; }  // check modifier key is pressed  (just in case)
    
    // selector string for the key press
    NSString *keySpecChars = [CEKeyBindingUtils keySpecCharsFromKeyEquivalent:keyEquivalent modifierMask:modifierMask];
    NSString *selectorString = [self keyBindingDict][keySpecChars];
    
    NSUInteger index = [self snippetIndexForSelectorWithString:selectorString];
    
    if (index == NSNotFound) { return nil; }

    NSArray<NSString *> *snippets = [self snippetsWithFactoryDefaults:NO];
    
    if (index >= [snippets count]) { return nil; }
    
    return snippets[index];
}


//------------------------------------------------------
/// return snippet texts to insert with key binding
/// @param usesFactoryDefaults   YES for default setting and NO for the current setting
- (nonnull NSArray<NSString *> *)snippetsWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    if (usesFactoryDefaults) {
        return [self defaultSnippets];
    } else {
        return [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
    }
}


//------------------------------------------------------
/// save texts to insert
- (void)saveSnippets:(nullable NSArray<NSString *> *)snippets
//------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:snippets forKey:CEDefaultInsertCustomTextArrayKey];
}



#pragma mark Private Methods

//------------------------------------------------------
/// build selector name for index
+ (nonnull NSString *)selectorStringWithIndex:(NSUInteger)index
//------------------------------------------------------
{
    return [NSString stringWithFormat:@"insertCustomText_%02li:", index];
}


//------------------------------------------------------
/// extract index number of snippet from selector name
- (NSUInteger)snippetIndexForSelectorWithString:(nullable NSString *)selectorString
//------------------------------------------------------
{
    if ([selectorString length] == 0) { return NSNotFound; }
    
    const NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^insertCustomText_([0-9]{2}):$" options:0 error:nil];
    NSTextCheckingResult *result = [regex firstMatchInString:selectorString options:0 range:NSMakeRange(0, [selectorString length])];
    NSRange numberRange = [result rangeAtIndex:1];
    
    if (numberRange.location == NSNotFound) { return NSNotFound; }
    
   return [[selectorString substringWithRange:numberRange] integerValue];
}

@end
