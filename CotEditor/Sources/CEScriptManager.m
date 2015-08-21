/*
 
 CEScriptManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-12.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEScriptManager.h"
#import "CEConsolePanelController.h"
#import "CEDocument.h"
#import "CEUtils.h"
#import "NSString+Sandboxing.h"
#import "Constants.h"


typedef NS_ENUM(NSUInteger, CEScriptOutputType) {
    CENoOutputType,
    CEReplaceSelectionType,
    CEReplaceAllTextType,
    CEInsertAfterSelectionType,
    CEAppendToAllTextType,
    CEPasteboardType
};

typedef NS_ENUM(NSUInteger, CEScriptInputType) {
    CENoInputType,
    CEInputSelectionType,
    CEInputAllTextType
};


@interface CEScriptManager ()

@property (nonatomic, nonnull) NSURL *scriptsDirectoryURL;

@end




#pragma mark -

@implementation CEScriptManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull instancetype)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // find Application Scripts folder
        _scriptsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:YES
                                                                         error:nil];
        
        // fallback directory creation for in case the app is not Sandboxed
        if (!_scriptsDirectoryURL) {
            NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
            NSURL *applicationSupport = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                                          inDomain:NSUserDomainMask appropriateForURL:nil
                                                                                 create:NO
                                                                                  error:nil];
            _scriptsDirectoryURL = [[applicationSupport URLByAppendingPathComponent:@"Application Scripts"]
                                    URLByAppendingPathComponent:bundleIdentifier isDirectory:YES];
            
            if (![_scriptsDirectoryURL checkResourceIsReachableAndReturnError:nil]) {
                [[NSFileManager defaultManager] createDirectoryAtURL:_scriptsDirectoryURL
                                         withIntermediateDirectories:YES attributes:@{} error:nil];
            }
        }
        
        [self buildScriptMenu:self];
        
        // run dummy AppleScript once for quick script launch
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultRunAppleScriptInLaunchingKey]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *source = @"tell application \"CotEditor\" to number of documents";
                NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithSource:source];
                [AppleScript executeAndReturnError:nil];
            });
        }
    }
    return self;
}



#pragma mark Public Methods

//------------------------------------------------------
/// build Script menu
- (void)buildScriptMenu:(nullable id)sender
//------------------------------------------------------
{
    NSMenu *menu = [[[NSApp mainMenu] itemAtIndex:CEScriptMenuIndex] submenu];
    [menu removeAllItems];

    [self addChildFileItemTo:menu fromDir:[self scriptsDirectoryURL]];
    
    BOOL isEmpty = [menu numberOfItems] == 0;
    
    NSMenuItem *copySampleMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Sample Scripts…", nil)
                                                                action:@selector(copySampleScriptToUserDomain:)
                                                         keyEquivalent:@""];
    [copySampleMenuItem setTarget:self];
    [copySampleMenuItem setToolTip:NSLocalizedString(@"Copy bundled sample scripts to the scripts folder.", nil)];
    [copySampleMenuItem setTag:CEDefaultScriptMenuItemTag];
    if (isEmpty) {
        [menu addItem:copySampleMenuItem];
    }
    
    NSMenuItem *separatorItem = [NSMenuItem separatorItem];
    [separatorItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:separatorItem];
    
    NSMenuItem *openMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Scripts Folder", nil)
                                                          action:@selector(openScriptFolder:)
                                                   keyEquivalent:@"a"];
    [openMenuItem setTarget:self];
    [openMenuItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:openMenuItem];
    
    if (!isEmpty) {
        [copySampleMenuItem setAlternate:YES];
        [copySampleMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [menu addItem:copySampleMenuItem];
    }
    
    NSMenuItem *updateMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Update Script Menu", nil)
                                                action:@selector(buildScriptMenu:)
                                         keyEquivalent:@""];
    [updateMenuItem setTarget:self];
    [updateMenuItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:updateMenuItem];
}


//------------------------------------------------------
/// return menu for context menu
- (nullable NSMenu *)contexualMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[[NSApp mainMenu] itemAtIndex:CEScriptMenuIndex] submenu] copy];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item tag] == CEDefaultScriptMenuItemTag) {
            [menu removeItem:item];
        }
    }
    
    return ([menu numberOfItems] > 0) ? menu : nil;
}



#pragma mark Action Messages

//------------------------------------------------------
/// launch script (invoked by menu item)
- (IBAction)launchScript:(nullable id)sender
//------------------------------------------------------
{
    NSURL *URL = [sender representedObject];
    
    if (!URL) { return; }

    // display alert and endup if file not exists
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The script “%@” does not exist.\n\nCheck it and do “Update Script Menu”.", @""), URL]];
        return;
    }
    
    NSString *extension = [URL pathExtension];

    // change behavior if modifier key is pressed
    NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
    if (modifierFlags == NSAlternateKeyMask) {  // open script file if Opt key is pressed
        BOOL success = YES;
        NSString *identifier = [[self AppleScriptExtensions] containsObject:extension] ? @"com.apple.ScriptEditor2" : [[NSBundle mainBundle] bundleIdentifier];
        success = [[NSWorkspace sharedWorkspace] openURLs:@[URL]
                                  withAppBundleIdentifier:identifier
                                                  options:0
                           additionalEventParamDescriptor:nil
                                        launchIdentifiers:NULL];
        
        // display alert if cannot open/select the script file
        if (!success) {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Could not open the script file “%@”.", nil), URL];
            [self showAlertWithMessage:message];
        }
        return;
        
    } else if (modifierFlags == (NSAlternateKeyMask | NSShiftKeyMask)) {  // reveal on Finder if Opt+Shift keys are pressed
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[URL]];
        return;
    }

    // run AppleScript
    if ([[self AppleScriptExtensions] containsObject:extension]) {
        [self runAppleScript:URL];
        
    // run Shell Script
    } else if ([[self scriptExtensions] containsObject:extension]) {
        // display alert if script file doesn't have execution permission
        NSNumber *isExecutable;
        [URL getResourceValue:&isExecutable forKey:NSURLIsExecutableKey error:nil];
        if (![isExecutable boolValue]) {
            [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Cannnot execute the script “%@”.\nShell script requires execute permission.\n\nCheck permission of the script file.", nil), URL]];
            return;
        }
        
        [self runShellScript:URL];
    }
}


// ------------------------------------------------------
/// open Script Menu folder in Finder
- (IBAction)openScriptFolder:(nullable id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[self scriptsDirectoryURL]]];
}


// ------------------------------------------------------
/// copy sample scripts to user domain
- (IBAction)copySampleScriptToUserDomain:(nullable id)sender
// ------------------------------------------------------
{
    // ask location to copy sample scripts
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setDirectoryURL:[self scriptsDirectoryURL]];
    [savePanel setNameFieldStringValue:@"Sample Scripts"];
    [savePanel setTitle:NSLocalizedString(@"Copy Sample Scripts", nil)];
    [savePanel setAllowedFileTypes:@[(NSString *)kUTTypeFolder]];
    [savePanel setShowsTagField:NO];
    [savePanel setMessage:[NSString stringWithFormat:NSLocalizedString(@"Scripts in “%@” will be listed in the script menu.", nil),
                           [[[self scriptsDirectoryURL] path] stringByAbbreviatingWithTildeInSandboxedPath]]];
    
    // run save panel
    NSInteger result = [savePanel runModal];
    if (result == NSFileHandlingPanelCancelButton) { return; }
    
    NSURL *destURL = [savePanel URL];
    NSURL *sourceURL = [[[NSBundle mainBundle] sharedSupportURL] URLByAppendingPathComponent:@"SampleScripts"];
    
    // copy
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:destURL error:&error];
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destURL error:&error];
    
    if (success) {
        [self buildScriptMenu:self];
    } else {
        NSLog(@"Error on %s: %@", __func__, [error localizedDescription]);
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// file extensions for UNIX scripts
- (nonnull NSArray *)scriptExtensions
// ------------------------------------------------------
{
    return @[@"sh", @"pl", @"php", @"rb", @"py", @"js"];
}


// ------------------------------------------------------
/// file extensions for AppleScript
- (nonnull NSArray *)AppleScriptExtensions
// ------------------------------------------------------
{
    return @[@"applescript", @"scpt"];
}


// ------------------------------------------------------
/// read input type from script
+ (CEScriptInputType)scanInputType:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSString *scannedString = nil;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"%%%{CotEditorXInput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXInput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&scannedString]) {
                break;
            }
        }
    }
    
    if ([scannedString isEqualToString:@"Selection"]) {
        return CEInputSelectionType;
        
    } else if ([scannedString isEqualToString:@"AllText"]) {
        return CEInputAllTextType;
    }
    
    return CENoInputType;
}


// ------------------------------------------------------
/// read output type from script
+ (CEScriptOutputType)scanOutputType:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSString *scannedString = nil;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"%%%{CotEditorXOutput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXOutput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&scannedString]) {
                break;
            }
        }
    }
    
    if ([scannedString isEqualToString:@"ReplaceSelection"]) {
        return CEReplaceSelectionType;
        
    } else if ([scannedString isEqualToString:@"ReplaceAllText"]) {
        return CEReplaceAllTextType;
        
    } else if ([scannedString isEqualToString:@"InsertAfterSelection"]) {
        return CEInsertAfterSelectionType;
        
    } else if ([scannedString isEqualToString:@"AppendToAllText"]) {
        return CEAppendToAllTextType;
        
    } else if ([scannedString isEqualToString:@"Pasteboard"]) {
        return CEPasteboardType;
    }
    
    return CENoOutputType;
}


// ------------------------------------------------------
/// return document content conforming to the input type
+ (nullable NSString *)inputStringWithType:(CEScriptInputType)inputType document:(nullable CEDocument *)document error:(NSError *__autoreleasing __nullable *)outError
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [document editor];
    
    // on no document found
    if (!editor) {
        switch (inputType) {
            case CEInputSelectionType:
            case CEInputAllTextType:
                if (outError) {
                    *outError = [NSError errorWithDomain:CEErrorDomain
                                                    code:CEScriptNoTargetDocumentError
                                                userInfo:@{NSLocalizedDescriptionKey: @"No document to scan input."}];
                }
                return nil;
                
            default:
                break;
        }
    }
    
    switch (inputType) {
        case CEInputSelectionType:
            // ([editor string] は改行コードLFの文字列を返すが、[editor selectedRange] は
            // 改行コードを反映させた範囲を返すので、「CR/LF」では使えない。そのため、
            // [[editor focusedTextView] selectedRange] を使う必要がある。2009-04-12
            return [[editor string] substringWithRange:[[editor focusedTextView] selectedRange]];
            
        case CEInputAllTextType:
            return [editor string];
            
        case CENoInputType:
            return nil;
    }
}


// ------------------------------------------------------
/// apply results conforming to the output type to the frontmost document
+ (BOOL)applyOutput:(nonnull NSString *)output document:(nullable CEDocument *)document outputType:(CEScriptOutputType)outputType error:(NSError *__autoreleasing __nullable *)outError
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [document editor];
    
    // on no document found
    if (!editor) {
        switch (outputType) {
            case CEReplaceSelectionType:
            case CEReplaceAllTextType:
            case CEInsertAfterSelectionType:
            case CEAppendToAllTextType:
                if (outError) {
                    *outError = [NSError errorWithDomain:CEErrorDomain
                                                    code:CEScriptNoTargetDocumentError
                                                userInfo:@{NSLocalizedDescriptionKey: @"Target document was not found."}];
                }
                return NO;
                
            default:
                break;
        }
    }
    
    switch (outputType) {
        case CEReplaceSelectionType:
            [editor insertTextViewString:output];
            break;
            
        case CEReplaceAllTextType:
            [editor replaceTextViewAllStringWithString:output];
            break;
            
        case CEInsertAfterSelectionType:
            [editor insertTextViewStringAfterSelection:output];
            break;
            
        case CEAppendToAllTextType:
            [editor appendTextViewString:output];
            break;
            
        case CEPasteboardType: {
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
            if (![pasteboard setString:output forType:NSStringPboardType]) {
                NSBeep();
            }
            break;
        }
        case CENoOutputType:
            break;  // do nothing
    }
    
    return YES;
}


//------------------------------------------------------
/// read files and create/add menu items
- (void)addChildFileItemTo:(nonnull NSMenu *)menu fromDir:(nonnull NSURL *)directoryURL
//------------------------------------------------------
{
    NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                  includingPropertiesForKeys:@[NSURLFileResourceTypeKey]
                                                                     options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:nil];
    
    for (NSURL *URL in URLs) {
        // ignore files/folders of which name starts with "_"
        if ([[URL lastPathComponent] hasPrefix:@"_"]) {  continue; }
        
        NSString *resourceType;
        NSString *extension = [URL pathExtension];
        [URL getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:nil];
        
        if ([resourceType isEqualToString:NSURLFileResourceTypeDirectory]) {
            NSString *title = [self scriptNameFromURL:URL];
            if ([title isEqualToString:@"-"]) {  // separator
                [menu addItem:[NSMenuItem separatorItem]];
                continue;
            }
            NSMenu *subMenu = [[NSMenu alloc] initWithTitle:title];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
            [item setTag:CEScriptMenuDirectoryTag];
            [menu addItem:item];
            [item setSubmenu:subMenu];
            [self addChildFileItemTo:subMenu fromDir:URL];
            
        } else if ([resourceType isEqualToString:NSURLFileResourceTypeRegular] &&
                   ([[self AppleScriptExtensions] containsObject:extension] || [[self scriptExtensions] containsObject:extension]))
        {
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [self keyEquivalentAndModifierMask:&modifierMask fromFileName:[URL lastPathComponent]];
            NSString *title = [self scriptNameFromURL:URL];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                          action:@selector(launchScript:)
                                                   keyEquivalent:keyEquivalent];
            [item setKeyEquivalentModifierMask:modifierMask];
            [item setRepresentedObject:URL];
            [item setTarget:self];
            [item setToolTip:NSLocalizedString(@"“Opt + click” to open in Script Editor.", nil)];
            [menu addItem:item];
        }
    }
}


//------------------------------------------------------
/// ファイル／フォルダ名からメニューアイテムタイトル名を生成
- (nonnull NSString *)scriptNameFromURL:(nonnull NSURL *)URL
//------------------------------------------------------
{
    NSString *fileName = [URL lastPathComponent];
    NSString *scriptName = [fileName stringByDeletingPathExtension];
    NSString *extnFirstChar = [[scriptName pathExtension] substringFromIndex:0];
    NSCharacterSet *specSet = [NSCharacterSet characterSetWithCharactersInString:@"^~$@"];

    // remove the number prefix ordering
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+\\)"
                                                                           options:0 error:nil];
    scriptName = [regex stringByReplacingMatchesInString:scriptName
                                                options:0
                                                  range:NSMakeRange(0, [scriptName length])
                                           withTemplate:@""];
    
    // remove keyboard shortcut definition
    if (([extnFirstChar length] > 0) && [specSet characterIsMember:[extnFirstChar characterAtIndex:0]]) {
        scriptName = [scriptName stringByDeletingPathExtension];
    }
    
    return scriptName;
}


//------------------------------------------------------
/// get keyboard shortcut from file name
- (nonnull NSString *)keyEquivalentAndModifierMask:(nonnull NSUInteger *)modifierMask fromFileName:(nonnull NSString *)fileName
//------------------------------------------------------
{
    NSString *keySpec = [[fileName stringByDeletingPathExtension] pathExtension];

    return [CEUtils keyEquivalentAndModifierMask:modifierMask fromString:keySpec includingCommandKey:YES];
}


//------------------------------------------------------
/// display alert message
- (void)showAlertWithMessage:(nonnull NSString *)message
//------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Script Error", nil)];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSCriticalAlertStyle];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert runModal];
    });
}


//------------------------------------------------------
/// read content of script file
- (nullable NSString *)stringOfScript:(nonnull NSURL *)URL
//------------------------------------------------------
{
    NSData *data = [NSData dataWithContentsOfURL:URL];
    
    if ([data length] == 0) { return nil; }
    
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    
    for (NSNumber *encodingNumber in encodings) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding([encodingNumber unsignedLongValue]);
        NSString *scriptString = [[NSString alloc] initWithData:data encoding:encoding];
        if (scriptString) {
            return scriptString;
        }
    }
    
    return nil;
}


//------------------------------------------------------
/// run AppleScript
- (void)runAppleScript:(nonnull NSURL *)URL
//------------------------------------------------------
{
    NSError *error = nil;
    NSUserAppleScriptTask *task = [[NSUserAppleScriptTask alloc] initWithURL:URL error:&error];
    
    __weak typeof(self) weakSelf = self;
    [task executeWithAppleEvent:nil completionHandler:^(NSAppleEventDescriptor *result, NSError *error) {
        typeof(self) self = weakSelf;  // strong self
        
        if (error) {
            [self showAlertWithMessage:[error localizedDescription]];
        }
    }];
}


//------------------------------------------------------
/// run UNIX script
- (void)runShellScript:(nonnull NSURL *)URL
//------------------------------------------------------
{
    NSError *error = nil;
    NSUserUnixTask *task = [[NSUserUnixTask alloc] initWithURL:URL error:&error];
    NSString *script = [self stringOfScript:URL];
    NSString *scriptName = [self scriptNameFromURL:URL];

    // show an alert and endup if script file cannot read
    if (!task || [script length] == 0) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Could not read the script “%@”.", nil), URL]];
        return;
    }
    
    // hold target document
    __weak CEDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];

    // read input
    CEScriptInputType inputType = [[self class] scanInputType:script];
    NSError *inputError = nil;
    __block NSString *input = [[self class] inputStringWithType:inputType document:document error:&inputError];
    if (inputError) {
        [self showScriptError:[inputError localizedDescription] scriptName:scriptName];
        return;
    }
    
    // get output type
    CEScriptOutputType outputType = [[self class] scanOutputType:script];
    
    // prepare file path as argument if available
    NSArray *arguments;
    if ([document fileURL]) {
        arguments = @[[[document fileURL] path]];
    }
    
    // pipes
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardInput:[inPipe fileHandleForReading]];
    [task setStandardOutput:[outPipe fileHandleForWriting]];
    [task setStandardError:[errPipe fileHandleForWriting]];
    
    // set input data asynchronously if available
    if ([input length] > 0) {
        [[inPipe fileHandleForWriting] setWriteabilityHandler:^(NSFileHandle *handle) {
            NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
            [handle writeData:data];
            [handle closeFile];
        }];
    }
    
    __weak typeof(self) weakSelf = self;
    __block BOOL cancelled = NO;  // user cancel state
    
    // read output asynchronously for safe with huge output
    [[outPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification
                                                                            object:[outPipe fileHandleForReading]
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *note)
     {
         [[NSNotificationCenter defaultCenter] removeObserver:observer];
         
         if (cancelled) { return; }
         
         typeof(self) self = weakSelf;  // strong self
         NSData *data = [note userInfo][NSFileHandleNotificationDataItem];
         NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         if (output) {
             NSError *error;
             [CEScriptManager applyOutput:output document:document outputType:outputType error:&error];
             if (error) {
                 [self showScriptError:[error localizedDescription] scriptName:scriptName];
             }
         }
     }];
    
    // execute
    [task executeWithArguments:arguments completionHandler:^(NSError *error)
     {
         typeof(self) self = weakSelf;  // strong self
         
         // on user cancel
         if ([[error domain] isEqualToString:NSPOSIXErrorDomain] && [error code] == ENOTBLK) {
             cancelled = YES;
             return;
         }
         
         NSData *errorData = [[errPipe fileHandleForReading] readDataToEndOfFile];
         NSString *errorMsg = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
         if ([errorMsg length] > 0) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self showScriptError:errorMsg scriptName:scriptName];
             });
         }
     }];
}


// ------------------------------------------------------
/// append message to console panel and show it
- (void)showScriptError:(nonnull NSString *)errorString scriptName:(nonnull NSString *)scriptName
// ------------------------------------------------------
{
    [[CEConsolePanelController sharedController] showWindow:self];
    [[CEConsolePanelController sharedController] appendMessage:errorString title:scriptName];
}

@end
