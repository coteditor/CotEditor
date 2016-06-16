/*
 
 CESettingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CESettingFileManager.h"
#import "CEErrors.h"


// General notification's userInfo keys
NSString *_Nonnull const CEOldNameKey = @"CEOldNameKey";
NSString *_Nonnull const CENewNameKey = @"CENewNameKey";


@implementation CESettingFileManager

#pragma mark Abstract Methods

//------------------------------------------------------
/// path extension for user setting file
- (nonnull NSString *)filePathExtension
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// list of names of setting file name (without extension)
- (nonnull NSArray<NSString *> *)settingNames
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// list of names of setting file name which are bundled (without extension)
- (nonnull NSArray<NSString *> *)bundledSettingNames
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// update internal cache data
- (void)updateCacheWithCompletionHandler:(void (^)())completionHandler
//------------------------------------------------------
{
    @throw nil;
}



#pragma mark Public Methods

//------------------------------------------------------
/// create setting name from a URL (don't care if it exists)
- (nonnull NSString *)settingNameFromURL:(nonnull NSURL *)fileURL
//------------------------------------------------------
{
    return [[fileURL lastPathComponent] stringByDeletingPathExtension];
}


//------------------------------------------------------
/// return a valid setting file URL for the setting name or nil if not exists
- (nullable NSURL *)URLForUsedSettingWithName:(nonnull NSString *)settingName
//------------------------------------------------------
{
    return [self URLForUserSettingWithName:settingName available:YES] ?: [self URLForBundledSettingWithName:settingName available:YES];
}


//------------------------------------------------------
/// return a setting file URL in the application's Resources domain (if available is YES, returns URL only if the file exists)
- (nullable NSURL *)URLForBundledSettingWithName:(nonnull NSString *)settingName available:(BOOL)available
//------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:settingName withExtension:[self filePathExtension] subdirectory:[self directoryName]];
    
    if (available) {
        return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
    } else {
        return URL;
    }
}


//------------------------------------------------------
/// return a setting file URL in the user's Application Support domain (if available is YES, returns URL only if the file exists)
- (nullable NSURL *)URLForUserSettingWithName:(nonnull NSString *)settingName available:(BOOL)available
//------------------------------------------------------
{
    NSURL *URL = [[[self userSettingDirectoryURL] URLByAppendingPathComponent:settingName] URLByAppendingPathExtension:[self filePathExtension]];
    
    if (available) {
        return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
    } else {
        return URL;
    }
}


//------------------------------------------------------
/// return a setting file URL in the user's Application Support domain or nil if not exists
- (nullable NSURL *)URLForUserSettingWithName:(nonnull NSString *)settingName
//------------------------------------------------------
{
    return [self URLForUserSettingWithName:settingName available:YES];
}


// ------------------------------------------------------
/// whether the setting name is one of the bundled settings
- (BOOL)isBundledSetting:(nonnull NSString *)settingName cutomized:(nullable BOOL *)isCustomized
// ------------------------------------------------------
{
    BOOL isBundled = [[self bundledSettingNames] containsObject:settingName];
    
    if (isBundled && isCustomized) {
        *isCustomized = ([self URLForUserSettingWithName:settingName available:YES] != nil);
    }
    return isBundled;
}


//------------------------------------------------------
/// return setting name appending localized " Copy" + number suffix without extension
- (nonnull NSString *)copiedSettingName:(nonnull NSString *)originalName
//------------------------------------------------------
{
    NSString *baseName = [originalName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *localizedCopy = NSLocalizedString(@" copy", nil);
    BOOL copiedState = NO;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"%@$", localizedCopy]
                                                                           options:0 error:nil];
    NSRange copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
    if (copiedStrRange.location != NSNotFound) {
        copiedState = YES;
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"%@ [0-9]+$", localizedCopy]
                                                          options:0 error:nil];
        copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
        if (copiedStrRange.location != NSNotFound) {
            copiedState = YES;
        }
    }
    NSString *copyString;
    if (copiedState) {
        copyString = [NSString stringWithFormat:@"%@%@", [baseName substringWithRange:NSMakeRange(0, copiedStrRange.location)], localizedCopy];
    } else {
        copyString = [NSString stringWithFormat:@"%@%@", baseName, localizedCopy];
    }
    NSMutableString *copiedSettingName = [copyString mutableCopy];
    NSUInteger i = 2;
    while ([[self settingNames] containsObject:copiedSettingName]) {
        [copiedSettingName setString:[NSString stringWithFormat:@"%@ %tu", copyString, i]];
        i++;
    }
    return [copiedSettingName copy];
}


// ------------------------------------------------------
/// validate whether the file name is valid (for a file name) and returns error if not
- (BOOL)validateSettingName:(nonnull NSString *)settingName originalName:(nonnull NSString *)originalSettingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // just case difference is OK
    if ([settingName caseInsensitiveCompare:originalSettingName] == NSOrderedSame) {
        return YES;
    }
    
    NSString *description;
    // a block to search in an array case insensitive
    __block NSString *duplicatedThemeName;
    BOOL (^caseInsensitiveContains)() = ^(id obj, NSUInteger idx, BOOL *stop){
        BOOL found = (BOOL)([obj caseInsensitiveCompare:settingName] == NSOrderedSame);
        if (found) { duplicatedThemeName = obj; }
        return found;
    };
    
    if ([settingName length] < 1) {  // empty
        description = NSLocalizedString(@"Name can’t be empty.", nil);
    } else if ([settingName containsString:@"/"]) {  // Containing "/" is invalid for a file name.
        description = NSLocalizedString(@"You can’t use a name that contains “/”.", nil);
    } else if ([settingName hasPrefix:@"."]) {  // Starting with "." is invalid for a file name.
        description = NSLocalizedString(@"You can’t use a name that begins with a dot “.”.", nil);
    } else if ([[self settingNames] indexOfObjectPassingTest:caseInsensitiveContains] != NSNotFound) {  // already exists
        description = [NSString stringWithFormat:NSLocalizedString(@"The name “%@” is already taken.", nil), duplicatedThemeName];
    }
    
    if (outError && description) {
        *outError = [NSError errorWithDomain:CEErrorDomain
                                        code:CEInvalidNameError
                                    userInfo:@{NSLocalizedDescriptionKey: description,
                                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please choose another name.", nil)}];
    }
    
    return (!description);
}


//------------------------------------------------------
/// delete user's file for the setting name
- (BOOL)removeSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserSettingWithName:settingName available:YES];
    
    if (!URL) { return YES; }  // not exist or already removed
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] trashItemAtURL:URL resultingItemURL:nil error:&error];
    
    if (!success) {
        NSLog(@"Error on setting deletion: %@", [error description]);
        if (outError && error) {
            *outError = [NSError errorWithDomain:CEErrorDomain
                                            code:CESettingDeletionFailedError
                                        userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"“%@” couldn’t be deleted.", nil), settingName],
                                                   NSLocalizedRecoverySuggestionErrorKey: [error localizedRecoverySuggestion],
                                                   NSURLErrorKey: URL,
                                                   NSUnderlyingErrorKey: error}];
        }
    }
    
    return success;
}


//------------------------------------------------------
/// restore the setting with name
- (BOOL)restoreSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserSettingWithName:settingName available:NO];
    
    if (!URL) { return YES; }  // not exist or already removed
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:URL error:outError];
    
    if (!success) {
        NSLog(@"Error. Could not restore \"%@\".", URL);
    }
    
    return success;
}


//------------------------------------------------------
/// duplicate the setting with name
- (BOOL)duplicateSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // create directory to save in user domain if not yet exist
    if (![self prepareUserSettingDirectory]) { return NO; }
    
    NSString *newSettingName = [self copiedSettingName:settingName];
    
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:[self URLForUsedSettingWithName:settingName]
                                                           toURL:[self URLForUserSettingWithName:newSettingName available:NO]
                                                           error:outError];
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// rename the setting with name
- (BOOL)renameSettingWithName:(nonnull NSString *)settingName toName:(nonnull NSString *)newSettingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // sanitize name
    newSettingName = [newSettingName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![self validateSettingName:newSettingName originalName:settingName error:outError]) {
        return NO;
    }
    
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:[self URLForUserSettingWithName:settingName available:NO]
                                                           toURL:[self URLForUserSettingWithName:newSettingName available:NO] error:outError];
    
    return success;
}


//------------------------------------------------------
/// export setting file to passed-in URL
- (BOOL)exportSettingWithName:(nonnull NSString *)settingName toURL:(nonnull NSURL *)URL error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    NSURL *sourceURL = [self URLForUserSettingWithName:settingName available:NO];
    
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:URL options:NSFileCoordinatorWritingForMoving
                                      error:&error
                                 byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:&error];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        if (outError) {
            *outError = error;
        }
        NSLog(@"Error on export: %@", [error description]);
    }
    
    return success;
}


//------------------------------------------------------
/// import setting at passed-in URL
- (BOOL)importSettingWithFileURL:(nonnull NSURL *)fileURL error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // create directory to save in user domain if not yet exist
    if (![self prepareUserSettingDirectory]) { return NO; }
    
    NSString *settingName = [self settingNameFromURL:fileURL];
    NSURL *destURL = [self URLForUserSettingWithName:settingName available:NO];
    
    // copy file
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges | NSFileCoordinatorReadingResolvesSymbolicLink
                           writingItemAtURL:destURL options:NSFileCoordinatorWritingForReplacing
                                      error:&error
                                 byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:nil];
         }
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (!success) {
        NSLog(@"Error on setting import: %@", [error description]);
        if (error && outError) {
            *outError = [NSError errorWithDomain:CEErrorDomain
                                            code:CESettingImportFailedError
                                        userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"“%@” couldn’t be imported.", nil), settingName],
                                                   NSLocalizedRecoverySuggestionErrorKey: [error localizedRecoverySuggestion],
                                                   NSURLErrorKey: fileURL,
                                                   NSUnderlyingErrorKey: error}];
        }
    }
    
    if (success) {
        // update internal cache
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}

@end
