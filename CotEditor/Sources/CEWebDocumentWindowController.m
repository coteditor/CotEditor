/*
 
 CEWebDocumentWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-20.
 
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

@import WebKit;
#import "CEWebDocumentWindowController.h"


@interface CEWebDocumentWindowController () <WebPolicyDelegate>

@property (nonatomic, nullable) IBOutlet WebView *webView;

@property (nonatomic, nonnull) NSURL *fileURL;

@end




#pragma mark -

@implementation CEWebDocumentWindowController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initializer
- (nonnull instancetype)initWithDocumentName:(nonnull NSString *)name
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _fileURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"html"];
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"WebDocumentWindow";
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    [[[self webView] mainFrame] loadRequest:[NSURLRequest requestWithURL:[self fileURL]]];
}



#pragma mark Delegate

// ------------------------------------------------------
/// open external link in default browser
- (void)webView:(nonnull WebView *)webView decidePolicyForNavigationAction:(nonnull NSDictionary *)actionInformation request:(nonnull NSURLRequest *)request frame:(nonnull WebFrame *)frame decisionListener:(nonnull id<WebPolicyDecisionListener>)listener
// ------------------------------------------------------
{
    if (![[request URL] host]) {
        [listener use];
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

@end
