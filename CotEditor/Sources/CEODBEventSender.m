/*
 
 CEODBEventSender.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-04.

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

#import "CEODBEventSender.h"
#import "ODBEditorSuite.h"


@interface CEODBEventSender ()

@property (nonatomic, nullable) NSAppleEventDescriptor *fileSender;
@property (nonatomic, nullable) NSAppleEventDescriptor *fileToken;

@end




#pragma mark -

@implementation CEODBEventSender


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSAppleEventDescriptor *descriptor, *AEPropDescriptor, *fileSender, *fileToken;
        
        descriptor = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        
        fileSender = [descriptor paramDescriptorForKeyword:keyFileSender];
        
        if (fileSender) {
            fileToken = [descriptor paramDescriptorForKeyword:keyFileSenderToken];
        } else {
            AEPropDescriptor = [descriptor paramDescriptorForKeyword:keyAEPropData];
            fileSender = [AEPropDescriptor paramDescriptorForKeyword:keyFileSender];
            fileToken = [AEPropDescriptor paramDescriptorForKeyword:keyFileSenderToken];
        }
        
        if (fileSender) {
            _fileSender = fileSender;
            if (fileToken) {
                _fileToken = fileToken;
            }
        }
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// notify the file update to the file client
- (void)sendModifiedEventWithURL:(nonnull NSURL *)URLToSave operation:(NSSaveOperationType)saveOperationType
// ------------------------------------------------------
{
    AEEventID type = (saveOperationType == NSSaveAsOperation) ? keyNewLocation : kAEModifiedFile;
    
    [self sendODBEventWithType:type URL:URLToSave];
}


// ------------------------------------------------------
/// nofity the file closing to the file client
- (void)sendCloseEventWithURL:(nonnull NSURL *)fileURL
// ------------------------------------------------------
{
    [self sendODBEventWithType:kAEClosedFile URL:fileURL];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// send a notification to the file client
- (void)sendODBEventWithType:(AEEventID)eventType URL:(nonnull NSURL *)fileURL
// ------------------------------------------------------
{
    if (!fileURL) { return; }
    
    OSType creatorCode = [[self fileSender] typeCodeValue];
    if (creatorCode == 0) { return; }
    
    NSAppleEventDescriptor *creatorDescriptor, *eventDescriptor, *fileDescriptor;
    
    creatorDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature
                                                                       bytes:&creatorCode
                                                                      length:sizeof(OSType)];
    
    eventDescriptor = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite
                                                               eventID:eventType
                                                      targetDescriptor:creatorDescriptor
                                                              returnID:kAutoGenerateReturnID
                                                         transactionID:kAnyTransactionID];
    
    NSData *urlData = [[fileURL absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    fileDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL
                                                                     data:urlData];
    [eventDescriptor setParamDescriptor:fileDescriptor forKeyword:keyDirectObject];
    
    if ([self fileToken]) {
        [eventDescriptor setParamDescriptor:[self fileToken] forKeyword:keySenderToken];
    }
    
    AESendMessage([eventDescriptor aeDesc], NULL, kAENoReply, kAEDefaultTimeout);
    
    // avoid calling multiple times
    if (eventType == kAEClosedFile || eventType == keyNewLocation) {
        [self setFileSender:nil];
    }
}

@end
