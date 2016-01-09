/*
 
 CESyntaxValidationViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-09-08.
 
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

#import "CESyntaxValidationViewController.h"
#import "CESyntaxManager.h"


@interface CESyntaxValidationViewController ()

@property (nonatomic, nullable, copy) NSString *result;


// readonly
@property (readwrite, nonatomic) BOOL didValidate;

@end




#pragma mark -

@implementation CESyntaxValidationViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"SyntaxValidationView";
}



#pragma mark Public Methods

// ------------------------------------------------------
/// validate style and insert the results to text view (return: number of errors)
- (NSUInteger)validate
// ------------------------------------------------------
{
    NSArray<NSDictionary<NSString *, NSString *> *> *results = [[CESyntaxManager sharedManager] validateSyntax:[self representedObject]];
    NSUInteger numberOfErrors = [results count];
    NSMutableString *message = [NSMutableString string];
    
    if (numberOfErrors == 0) {
        [message appendString:NSLocalizedString(@"No error was found.", nil)];
    } else if (numberOfErrors == 1) {
        [message appendString:NSLocalizedString(@"An error was found!", nil)];
    } else {
        [message appendFormat:NSLocalizedString(@"%i errors were found!", nil), numberOfErrors];
    }
    
    for (NSDictionary<NSString *, id> *result in results) {
        [message appendFormat:@"\n\n%@: [%@] %@\n\t> %@",
         result[CESyntaxValidationTypeKey],
         result[CESyntaxValidationRoleKey],
         result[CESyntaxValidationStringKey],
         result[CESyntaxValidationMessageKey]];
    }
    
    [self setResult:message];
    
    return numberOfErrors;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// start syntax style validation
- (IBAction)startValidation:(nullable id)sender
// ------------------------------------------------------
{
    [self validate];
}

@end
