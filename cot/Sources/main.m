/*
 
 main.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-11-24.
 
 ------------------------------------------------------------------------------
 
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

@import Foundation;
#import <getopt.h>
#import "CotEditor.h"


// constants
static NSString *const kBundleIdentifier = @"com.coteditor.CotEditor";




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


int main(int argc, char *argv[])
{
    @autoreleasepool {
        // options
        bool isBackground = false;
        bool isNew = false;
        bool wantsJump = false;
        long line = 1;  // 1 based
        long column = 0;
        
        // parse options
        static struct option longopts[] = {
            {"version",    no_argument,       NULL, 'v'},
            {"help",       no_argument,       NULL, 'h'},
            {"background", no_argument,       NULL, 'g'},
            {"new",        no_argument,       NULL, 'n'},
            {"line",       required_argument, NULL, 'l'},
            {"column",     required_argument, NULL, 'c'},
            {0, 0, 0, 0}
        };
        int option = -1;
        while ((option = getopt_long(argc, argv, "vhgnl:c:", longopts, NULL)) != -1) {
            switch (option) {
                case 'v':  // version
                    printf("cot %s\n", version());  // display version
                    exit(EXIT_SUCCESS);
                    
                case 'h':  // help
                    usage();  // display usage
                    exit(EXIT_SUCCESS);
                    
                case 'g':  // background
                    isBackground = true;
                    break;
                    
                case 'n':  // new
                    isNew = true;
                    break;
                    
                case 'l':  // line
                    line = atol(optarg);
                    wantsJump = true;
                    break;
                    
                case 'c':  //column
                    column = atol(optarg);
                    wantsJump = true;
                    break;
                    
                case '?':  // invalid option
                    exit(EXIT_FAILURE);
            }
        }
        
        // parse parameters
        NSMutableArray *URLs = [NSMutableArray array];
        if (argc - optind > 0) {  // if parameter exists
            // get user's current directory
            NSDictionary *env = [[NSProcessInfo processInfo] environment];
            NSURL *currentURL = env[@"PWD"] ? [NSURL fileURLWithPath:env[@"PWD"]] : nil;
            
            // convert chars to NSURL
            for(int i = optind; i < argc; i++) {
//                NSURL *URL = [[NSURL fileURLWithFileSystemRepresentation:argv[i] isDirectory:NO relativeToURL:currentURL] URLByStandardizingPath];  // on 10.9 and later
                NSURL *URL = [[currentURL URLByAppendingPathComponent:[NSString stringWithUTF8String:argv[i]] isDirectory:NO] URLByStandardizingPath];
                
                if (!URL) { continue; }
                
                // validate file paths
                BOOL isDirectory;
                BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[URL path] isDirectory:&isDirectory];
                
                if (exists && !isDirectory) {
                    [URLs addObject:URL];
                    
                } else if ([URLs count] == 1) {
                    printf("%s is not readable file.\n", argv[i]);
                    exit(EXIT_FAILURE);
                }
            }
        }
        
        // read piped text if exists
        NSString *input = nil;
        if (!isatty(fileno(stdin))) {
            NSFileHandle *inputHandler = [NSFileHandle fileHandleWithStandardInput];
            NSData *data = [inputHandler availableData];
            input = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        // launch CotEditor
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kBundleIdentifier
                                                             options:NSWorkspaceLaunchWithoutActivation
                                      additionalEventParamDescriptor:nil
                                                    launchIdentifier:nil];
        
        // create scriptable application object
        CotEditorApplication *CotEditor = [SBApplication applicationWithBundleIdentifier:kBundleIdentifier];
        
        if (!CotEditor) {
            printf("Failed open CotEditor.\n");
            exit(EXIT_FAILURE);
        }
        
        // launch CotEditor
        [[NSWorkspace sharedWorkspace] launchApplication:kBundleIdentifier];
        
        // Due to Sandboxing, the following `open:` method doesn't work.
        //     [CotEditor open:URLs];
        // So, we let AppleScript command run directly to open given file paths.
        // I'm not sure it confirms to Apple's Mac App Store agreement, but at least it works... (2015-08 by 1024jp)
        for (NSURL *URL in URLs) {
            NSString *path = [[URL absoluteString] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            NSString *source = [NSString stringWithFormat:@"tell app \"CotEditor\" to open POSIX file \"%@\"", path];
            NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
            [script executeAndReturnError:nil];
        }
        
        if (!isBackground) {
            [CotEditor activate];
        }
        
        // create new document
        CotEditorDocument *document;
        if (input && [URLs count] == 0) {  // with piped text
            document = [[[CotEditor classForScriptingClass:@"document"] alloc] init];
            
            [[CotEditor documents] addObject:document];
            [[document selection] setContents:(CotEditorAttributeRun *)input];
            [[document selection] setRange:@[@0, @0]];
            
        } else if (isNew) {  // brank document
            document = [[[CotEditor classForScriptingClass:@"document"] alloc] init];
            
            [[CotEditor documents] addObject:document];
        }
        
        // jump to location
        if (wantsJump) {
            document = document ? : [[CotEditor documents] firstObject];
            
            if (!document) { exit(EXIT_SUCCESS); }
            
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
    
    exit(EXIT_SUCCESS);
}
