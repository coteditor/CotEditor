/*
 
 CEProgressViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-06-07.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

#import "CEProgressViewController.h"


@interface CEProgressViewController ()

@property (nonatomic, nonnull) NSProgress *progress;
@property (nonatomic, nonnull, copy) NSString *message;

@property (nonatomic, nullable, weak) IBOutlet NSButton *button;

@end




#pragma mark -

@implementation CEProgressViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithProgress:(nonnull NSProgress *)progress message:(nonnull NSString *)message
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _progress = progress;
        _message = message;
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"ProgressView";
}



#pragma mark Public Methods

// ------------------------------------------------------
/// change state to done
- (void)doneWithButtonTitle:(nullable NSString *)title
// ------------------------------------------------------
{
    title = title ?: NSLocalizedString(@"OK", nil);
    
    [[self button] setTitle:title];
    [[self button] setAction:@selector(dismissController:)];
    [[self button] setKeyEquivalent:@"\r"];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// cancel current process
- (IBAction)cancel:(nullable id)sender
// ------------------------------------------------------
{
    [[self progress] cancel];
    
    [self dismissController:sender];
}

@end
