/*
 
 CEKeyBindingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-09-01.

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

#import "CEKeyBindingManager.h"
#import "CEKeyBindingUtils.h"
#import "CEErrors.h"


// outlineView data key, column identifier
NSString *_Nonnull const CEKeyBindingTitleKey = @"title";
NSString *_Nonnull const CEKeyBindingKeySpecCharsKey = @"keyBindingKey";
NSString *_Nonnull const CEKeyBindingSelectorStringKey = @"selectorString";
NSString *_Nonnull const CEKeyBindingChildrenKey = @"children";




#pragma mark -

@implementation CEKeyBindingManager

#pragma mark Superclass Methods

//------------------------------------------------------
/// directory name in both Application Support and bundled Resources
- (nonnull NSString *)directoryName
//------------------------------------------------------
{
    return @"KeyBindings";
}



#pragma mark Abstract Methods

//------------------------------------------------------
/// name of file to save custom key bindings in the plist file form (without extension)
- (nonnull NSString *)settingFileName
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// create a KVO-compatible dictionary for outlineView in preferences from the key binding setting
/// @param usesFactoryDefaults   YES for default setting and NO for the current setting
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)keySpecCharsListForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// default key binding
- (NSDictionary<NSString *, NSString *> *)defaultKeyBindingDict
//------------------------------------------------------
{
    @throw nil;
}



#pragma mark Public Methods

//------------------------------------------------------
/// file URL to save custom key bindings file
- (nonnull NSURL *)keyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirectoryURL] URLByAppendingPathComponent:[self settingFileName]]
            URLByAppendingPathExtension:@"plist"];
}


// ------------------------------------------------------
/// whether key bindings are not customized
- (BOOL)usesDefaultKeyBindings
// ------------------------------------------------------
{
    return [[self keyBindingDict] isEqualToDictionary:[self defaultKeyBindingDict]];
}


//------------------------------------------------------
/// save passed-in key binding settings
- (BOOL)saveKeyBindings:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData
//------------------------------------------------------
{
    // create directory to save in user domain if not yet exist
    if (![self prepareUserSettingDirectory]) { return NO; }
    
    NSDictionary<NSString *, id> *plistDict = [self keyBindingDictionaryFromOutlineData:outlineData];
    NSURL *fileURL = [self keyBindingSettingFileURL];
    BOOL success = NO;
    
    // write to file
    NSError *error;
    if ([plistDict isEqualToDictionary:[self defaultKeyBindingDict]]) {
        // just remove setting file if the new setting is exactly the same as the default
        success = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    } else {
        success = [plistDict writeToURL:fileURL atomically:YES];
    }
    
    // store new values
    if (success) {
        [self setKeyBindingDict:plistDict];
    } else {
        NSLog(@"Error on saving keybindings setting file: %@", [error description]);
    }
    
    return success;
}


//------------------------------------------------------
/// validate new key spec chars are settable
- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldKeySpecChars:(nonnull NSString *)oldKeySpecChars error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // blank key is always valid
    if ([keySpec length] == 0) { return YES; }
    
    // duplication check
    NSArray<NSString *> *registeredKeySpecChars = [[self keyBindingDict] allKeys];
    if (![keySpec isEqualToString:oldKeySpecChars] && [registeredKeySpecChars containsObject:keySpec]) {
        if (outError) {
            *outError = [self errorWithMessageFormat:@"“%@” is already taken." keySpecChars:keySpec];
        }
        return NO;
    }
    
    return YES;
}


//------------------------------------------------------
/// create error for keySpecChars validation
- (nonnull NSError *)errorWithMessageFormat:(nonnull NSString *)message keySpecChars:(nonnull NSString *)keySpecChars
//------------------------------------------------------
{
    NSString *printableKey = [CEKeyBindingUtils printableKeyStringFromKeySpecChars:keySpecChars];
    return [NSError errorWithDomain:CEErrorDomain
                                    code:CEInvalidKeySpecCharsError
                                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(message, nil), printableKey],
                                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please choose another key.", nil)}];
    
}



#pragma mark Private Mthods

//------------------------------------------------------
/// create a plist-compatible dictionary to save from outlineView data
- (nonnull NSDictionary<NSString *, id> *)keyBindingDictionaryFromOutlineData:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData
//------------------------------------------------------
{
    NSMutableDictionary<NSString *, id> *keyBindingDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary<NSString *, id> *item in outlineData) {
        NSArray<NSDictionary<NSString *, id> *> *children = item[CEKeyBindingChildrenKey];
        if (children) {
            [keyBindingDict addEntriesFromDictionary:[self keyBindingDictionaryFromOutlineData:children]];
            
        } else {
            NSString *keySpecChars = item[CEKeyBindingKeySpecCharsKey];
            NSString *selectorString = item[CEKeyBindingSelectorStringKey];
            if (([keySpecChars length] > 0) && ([selectorString length] > 0)) {
                keyBindingDict[keySpecChars] = selectorString;
            }
        }
    }
    
    return [keyBindingDict copy];
}

@end
