/*
 ==============================================================================
 cot.m
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-11-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
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

@import Foundation;
#import "CotEditor.h"


static NSString *const kBundleIdentifier = @"com.coteditor.CotEditor";

static NSString *const kFiles = @"files";
static NSString *const kVersionOption = @"version";
static NSString *const kHelpOption = @"help";
static NSString *const kBackgroundOption = @"background";
static NSString *const kNewOption = @"new";
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




#pragma mark -

const char* version(void)
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    return [version UTF8String];
}


void usage(void)
{
    printf("cot %s - command-line utility for CotEditor.\n", version());
    printf("Usage: cot [options] [file ...]\n");
    printf("Options:\n");
    printf("    -n, --new             Create a new blank document.\n");
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
                         @{kNameKey:kNewOption, kParamKey:@[@"--new", @"-n"], kTypeKey:@(BoolType)},
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
            printf("cot %s\n", version());
            exit(0);
        }
        
        // read piped text if exists
        NSString *input = nil;
        if (!isatty(fileno(stdin))) {
            NSFileHandle *inputHandler = [NSFileHandle fileHandleWithStandardInput];
            NSData *data = [inputHandler availableData];
            input = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        // validate file paths
        NSMutableArray *URLs = [NSMutableArray array];
        for (NSString *path in arguments[kFiles]) {
            BOOL isDirectory;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
            
            if (exists && !isDirectory) {
                NSURL *URL = [[NSURL fileURLWithPath:path isDirectory:NO] URLByStandardizingPath];
                [URLs addObject:URL];
                
            } else if ([arguments[kFiles] count] == 1) {
                printf("%s is not readable file.\n", [path UTF8String]);
                exit(1);
            }
        }
        
        // create scriptable application object
        NSURL *applicationURL = [[NSBundle mainBundle] bundleURL];  // CotEditor.app
        CotEditorApplication *CotEditor;
        if ([[applicationURL pathExtension] isEqualToString:@"app"]) {
            CotEditor = [SBApplication applicationWithURL:applicationURL];
        } else {
            CotEditor = [SBApplication applicationWithBundleIdentifier:kBundleIdentifier];
        }
        
        if (!CotEditor) {
            printf("Failed open CotEditor.\n");
            exit(1);
        }
        
        // launch CotEditor
        [CotEditor open:URLs];
        if (![arguments[kBackgroundOption] boolValue]) {
            [CotEditor activate];
        }
        
        // create new document
        CotEditorDocument *document;
        if (input && [URLs count] == 0) {  // with piped text
            document = [[[CotEditor classForScriptingClass:@"document"] alloc] init];
            
            [[CotEditor documents] addObject:document];
            [[document selection] setContents:(CotEditorAttributeRun *)input];
            [[document selection] setRange:@[@0, @0]];
            
        } else if ([arguments[kNewOption] boolValue]) {  // brank document
            document = [[[CotEditor classForScriptingClass:@"document"] alloc] init];
            
            [[CotEditor documents] addObject:document];
        }
        
        // jump to location
        if (arguments[kLineOption] || arguments[kColumnOption]) {
            document = document ? : [[CotEditor documents] firstObject];
            
            if (!document) { exit(0); }
            
            NSInteger line = [arguments[kLineOption] integerValue];  // 1 based
            NSInteger column = [arguments[kColumnOption] integerValue];
            
            // sanitize line number
            NSArray *lines = [[document contents] paragraphs];
            if (line == 0) {
                line = 1;
            } else if  (line < 0) {  // negative line number counts from the last line
                line = [lines count] - labs(line) + 1;
            }
            
            // count location of line head
            NSIndexSet *lineIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, line - 1)];
            NSInteger loc = 0;
            for (CotEditorParagraph *line in [lines objectsAtIndexes:lineIndexSet]) {
                loc += [[line characters] count];
            }
            
            // sanitize column number
            CotEditorParagraph *lastLine = lines[line - 1];
            column = MIN(column, [[lastLine characters] count] - 1);
            
            // set selection range
            [[document selection] setRange:@[@(loc + column), @0]];
            
            // jump
            [document scrollToCaret];
        }
    }
    
    return 0;
}
