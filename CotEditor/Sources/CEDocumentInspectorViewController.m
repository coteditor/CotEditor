/*
 
 CEDocumentInspectorViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
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

#import "CEDocumentInspectorViewController.h"
#import "CEDocumentAnalyzer.h"


@implementation CEDocumentInspectorViewController

// ------------------------------------------------------
/// let documentAnalyzer autoupdate
- (void)viewWillAppear
// ------------------------------------------------------
{
    [[self analyzer] setNeedsUpdateEditorInfo:YES];
    [[self analyzer] invalidateEditorInfo];
    
    [super viewWillAppear];
}


// ------------------------------------------------------
/// stop autoupdate documentAnalyzer
- (void)viewDidDisappear
// ------------------------------------------------------
{
    [[self analyzer] setNeedsUpdateEditorInfo:NO];
    
    [super viewDidDisappear];
}



# pragma Private Medhods

// ------------------------------------------------------
/// cast representedObject to analyzer
- (nullable CEDocumentAnalyzer *)analyzer
// ------------------------------------------------------
{
    return [self representedObject];
}

@end
