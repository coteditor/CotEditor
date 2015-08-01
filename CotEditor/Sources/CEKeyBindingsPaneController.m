/*
 
 CEKeyBindingsPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

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

#import "CEKeyBindingsPaneController.h"
#import "CEKeyBindingSheetController.h"


@implementation CEKeyBindingsPaneController

#pragma mark Action Messages

// ------------------------------------------------------
/// open key bindng edit sheet
- (IBAction)openKeyBindingEditSheet:(nullable id)sender
// ------------------------------------------------------
{
    // display sheet and start modal loop
    // (will end on CEKeyBindingSheetController's `closeSheet:`)
    CEKeyBindingSheetController *sheetController = [[CEKeyBindingSheetController alloc] initWithMode:[sender tag]];
    NSWindow *sheet = [sheetController window];
    
    [NSApp beginSheet:sheet
       modalForWindow:[[self view] window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    [NSApp runModalForWindow:sheet];
    
    // close sheet
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    [[[self view] window] makeKeyAndOrderFront:self];
}

@end
