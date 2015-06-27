/*
 ==============================================================================
 CEODBEventSender
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-04 by 1024jp
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
