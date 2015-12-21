/*
 
 CESyntaxTermsEditViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-11-28.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CESyntaxTermsEditViewController.h"

@interface CESyntaxTermsEditViewController ()

@property (nonatomic, nonnull, copy) NSString *syntaxType;


@property (nonatomic, nullable) IBOutlet NSArrayController *termsController;

@end




#pragma mark -

@implementation CESyntaxTermsEditViewController

// ------------------------------------------------------
/// initializer
- (nullable instancetype)initWithStynaxType:(NSString *)syntaxType
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _syntaxType = syntaxType;
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"SyntaxTermsEditView";
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_termsController unbind:NSContentArrayBinding];
}


// ------------------------------------------------------
/// setup binding with desired key
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // bind
    [[self termsController] bind:NSContentArrayBinding
                        toObject:self
                     withKeyPath:[NSString stringWithFormat:@"representedObject.%@", [self syntaxType]]
                         options:nil];
}

@end
