/*
 ==============================================================================
 cot.m
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-11-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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

@import Cocoa;
@import AppleScriptObjC;


static NSString *const kBundleIdentifier = @"com.coteditor.CotEditor";

static NSString *const kFiles = @"files";
static NSString *const kVersionOption = @"version";
static NSString *const kHelpOption = @"help";
static NSString *const kBackgroundOption = @"background";
static NSString *const kLineOption = @"line";
static NSString *const kColumnOption = @"column";

static NSString *const kNameKey = @"name";
static NSString *const kParamKey = @"param";
static NSString *const kTypeKey = @"type";
typedef NS_ENUM(NSUInteger, OptionTypes) {
    BoolType,
    IntType,
    StringType,
};


@protocol RemoteEditorControllerProtocol <NSObject>

- (void)jumpToLine:(NSNumber *)line column:(NSNumber *)column;
- (void)createNewDocument:(NSString *)contents;

@end




#pragma mark -

const char* version(void)
{
    NSURL *URL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:kBundleIdentifier];
    NSBundle *bundle = [NSBundle bundleWithURL:URL];
    
    return [[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String];
}


void usage(void)
{
    printf("cot %s - command-line utility for CotEditor.\n", version());
    printf("Usage: cot [options] [file ...]\n");
    printf("Options:\n");
    printf("    -l, --line <line>     Jump to specific line in opened document.\n");
    printf("    -c, --column <column> Jump to specific column in opened document.\n");
    printf("    -g, --background      Do not bring the application to the foreground.\n");
    printf("    -h, --help            Show this help.\n");
    printf("    -v, --version         Print version information.\n");
}


NSDictionary* parseArguments(NSArray *args)
{
    NSMutableDictionary *parsedArgs = [NSMutableDictionary dictionary];
    NSMutableArray *files = [NSMutableArray array];
    
    NSArray *options = @[@{kNameKey:kVersionOption, kParamKey:@[@"--version", @"-v"], kTypeKey:@(BoolType)},
                         @{kNameKey:kHelpOption, kParamKey:@[@"--help", @"-h"], kTypeKey:@(BoolType)},
                         @{kNameKey:kBackgroundOption, kParamKey:@[@"--background", @"-g"], kTypeKey:@(BoolType)},
                         @{kNameKey:kLineOption, kParamKey:@[@"--line", @"-l"], kTypeKey:@(IntType)},
                         @{kNameKey:kColumnOption, kParamKey:@[@"--column", @"-c"], kTypeKey:@(IntType)},
                         ];
    NSRegularExpression *optRegex = [NSRegularExpression regularExpressionWithPattern:@"^-[-a-z]" options:0 error:nil];
    
    BOOL isFirst = YES;
    NSString *lastKey = nil;
    for (NSString *arg in args) {
        if (isFirst) {  // first argument is path to command itself
            isFirst = NO;
            
        } else if ([[optRegex matchesInString:arg options:0 range:NSMakeRange(0, [arg length])] count] > 0) {
            for (NSDictionary *option in options) {
                if ([option[kParamKey] containsObject:arg]) {
                    if ([option[kTypeKey] unsignedIntegerValue] == BoolType) {
                        parsedArgs[option[kNameKey]] = @YES;
                        lastKey = nil;
                    } else {
                        lastKey = option[kNameKey];
                    }
                    break;
                }
            }
            
        } else if (lastKey) {
            parsedArgs[lastKey] = arg;
            lastKey = nil;
            
        } else {
            [files addObject:arg];
        }
    }
    parsedArgs[kFiles] = [files copy];
    
    
    return [parsedArgs copy];
}


int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSDictionary *arguments = parseArguments([[NSProcessInfo processInfo] arguments]);
        
        // display usage
        if ([arguments[kHelpOption] boolValue]) {
            usage();
            exit(0);
        }
        
        // display version
        if ([arguments[kVersionOption] boolValue]) {
            printf("CotEditor %s\n", version());
            exit(0);
        }
        
        // read piped text if exists
        NSString *input;
        if (!isatty(fileno(stdin))) {
            NSFileHandle *inputHandler = [NSFileHandle fileHandleWithStandardInput];
            NSData *data = [inputHandler availableData];
            input = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        NSMutableArray *URLs = [NSMutableArray array];
        NSWorkspaceLaunchOptions options = 0;
        
        // validate file paths
        for (NSString *path in arguments[kFiles]) {
            NSURL *URL = [NSURL fileURLWithPath:path isDirectory:NO];
            
            if ([arguments[kFiles] count] == 1 && ![URL checkResourceIsReachableAndReturnError:nil]) {
                printf("%s is not valid file.\n", [path UTF8String]);
                exit(1);
            }
            
            NSDictionary *info = [URL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLIsReadableKey] error:nil];
            if (![info[NSURLIsDirectoryKey] boolValue] && [info[NSURLIsReadableKey] boolValue]) {
                [URLs addObject:URL];
            }
        }
        
        // open in background
        if ([arguments[kBackgroundOption] boolValue]) {
            options |= NSWorkspaceLaunchWithoutActivation;
        }
        
        // launch CotEditor
        BOOL success = [[NSWorkspace sharedWorkspace] openURLs:URLs
                                       withAppBundleIdentifier:kBundleIdentifier
                                                       options:options
                                additionalEventParamDescriptor:nil
                                             launchIdentifiers:NULL];
        
        if (!success) {
            printf("Failed open CotEditor.\n");
            exit(1);
        }
        
        if (arguments[kLineOption] || arguments[kColumnOption] || input) {
            // load AppleScript
            NSURL *URL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:kBundleIdentifier];
            NSBundle *bundle = [NSBundle bundleWithURL:URL];
            [bundle loadAppleScriptObjectiveCScripts];
            Class RemoteEditorController = NSClassFromString(@"RemoteEditorController");
            id<RemoteEditorControllerProtocol> editorController = [[RemoteEditorController alloc] init];
            
            // create new document with piped text
            if (input && [URLs count] == 0) {
                [editorController createNewDocument:input];
            }
            
            // jump to location
            if (arguments[kLineOption]|| arguments[kColumnOption]) {
                NSInteger line = [arguments[kLineOption] integerValue];
                NSInteger column = [arguments[kColumnOption] integerValue];
                [editorController jumpToLine:@(line) column:@(column)];
            }
        }
    }
    
    return 0;
}
