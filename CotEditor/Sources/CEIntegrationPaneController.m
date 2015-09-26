/*
 
 CEIntegrationPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-20.

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

#import "CEIntegrationPaneController.h"


static NSString *_Nonnull const kPreferredSymbolicLinkPath = @"/usr/local/bin/cot";
static NSString *_Nonnull const kLearnMorePath = @"http://coteditor.com/cot";


@interface CEIntegrationPaneController ()

@property (nonatomic, nonnull) NSURL *preferredLinkURL;
@property (nonatomic, nonnull) NSURL *linkURL;  // binding
@property (nonatomic, getter=isInstalled) BOOL installed;
@property (nonatomic, nullable, copy) NSString *warning;

@end




#pragma mark -

@implementation CEIntegrationPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _preferredLinkURL = [NSURL fileURLWithPath:kPreferredSymbolicLinkPath];
        _linkURL = _preferredLinkURL;
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [self setInstalled:[self validateSymlink]];
}


// ------------------------------------------------------
/// update warnings before view appears (only on OS X 10.10 and later)
- (void)viewWillAppear
// ------------------------------------------------------
{
    [super viewWillAppear];
    
    [self setInstalled:[self validateSymlink]];
}



#pragma mark Action Messages

// ------------------------------------------------------
///  "Learn More" button is clicked
- (IBAction)learnMore:(nullable id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kLearnMorePath]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// check the destination of symlink and return whether 'cot' command is exists at '/usr/local/bin/'
- (BOOL)validateSymlink
// ------------------------------------------------------
{
    // reset once
    [self setWarning:nil];
    
    // not installed yet (= can install)
    if (![[self linkURL] checkResourceIsReachableAndReturnError:nil]) {
        return NO;
    }
    
    // ???: `URLByResolvingSymlinksInPath` doesn't work correctly on OS X 10.10 SDK, so I use a legacy way (2015-08).
//    NSURL *linkDestinationURL = [[self linkURL] URLByResolvingSymlinksInPath];
    NSURL *linkDestinationURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager]
                                                        destinationOfSymbolicLinkAtPath:[[self linkURL] path] error:nil]];
    
    // if it is not a symlink (treat as "installed")
    if ([linkDestinationURL isEqual:[self linkURL]]) {
        return YES;
    }
    
    // FIXME: just treat as installed when a symlink exists
    return YES;
}

@end
