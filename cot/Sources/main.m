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
//                NSURL *URL = [NSURL fileURLWithFileSystemRepresentation:argv[i] isDirectory:NO relativeToURL:currentURL];  // on 10.9 and later
                NSURL *URL = [currentURL URLByAppendingPathComponent:[NSString stringWithUTF8String:argv[i]] isDirectory:NO];
                
                // validate file paths
                BOOL isDirectory;
                BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[URL path] isDirectory:&isDirectory];
                
                if (exists && !isDirectory) {
                    [URLs addObject:[URL URLByStandardizingPath]];
                    
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
            exit(EXIT_FAILURE);
        }
        
        // launch CotEditor
        [CotEditor open:URLs];
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
