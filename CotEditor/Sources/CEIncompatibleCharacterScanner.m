/*
 
 CEIncompatibleCharacterScanner.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
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

#import "CEIncompatibleCharacterScanner.h"
#import "CEIncompatibleCharacter.h"
#import "CEDocument.h"


static const NSTimeInterval kUpdateInterval = 0.42;


@interface CEIncompatibleCharacterScanner ()

@property (nonatomic, nullable, weak) NSTimer *updateTimer;
@property (nonatomic) BOOL needsUpdate;

// readonly
@property (readwrite, nonatomic, nullable, weak) CEDocument *document;  // weak to avoid cycle retain
@property (readwrite, nonatomic, nonnull) NSArray<CEIncompatibleCharacter *> *incompatibleCharacers;

@end




#pragma mark -

@implementation CEIncompatibleCharacterScanner

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_updateTimer invalidate];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithDocument:(nonnull CEDocument *)document
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _document = document;
        _needsUpdate = YES;
    }
    return self;
}


// ------------------------------------------------------
/// set update timer
- (void)invalidate
// ------------------------------------------------------
{
    [self setNeedsUpdate:YES];
    
    if (![[self delegate] documentNeedsUpdateIncompatibleCharacter:[self document]]) { return; }
    
    if ([[self updateTimer] isValid]) {
        [[self updateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:kUpdateInterval]];
    } else {
        [self setUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:kUpdateInterval
                                                              target:self
                                                            selector:@selector(scanWithTimer:)
                                                            userInfo:nil
                                                             repeats:NO]];
    }
}


// ------------------------------------------------------
/// scan immediately
- (void)scan
// ------------------------------------------------------
{
    [[self updateTimer] invalidate];
    
    [self setIncompatibleCharacers:[[[self document] string] scanIncompatibleCharactersForEncoding:[[self document] encoding]]];
    [self setNeedsUpdate:NO];
    
    if ([[self delegate] respondsToSelector:@selector(document:didUpdateIncompatibleCharacters:)]) {
        [[self delegate] document:[self document] didUpdateIncompatibleCharacters:[self incompatibleCharacers]];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// update incompatible chars afer interval
- (void)scanWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [[self updateTimer] invalidate];
    [self scan];
}

@end

