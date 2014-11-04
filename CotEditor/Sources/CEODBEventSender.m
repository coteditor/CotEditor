/*
 ==============================================================================
 CEODBEventSender
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-04 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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

@property (nonatomic) NSAppleEventDescriptor *fileSender;
@property (nonatomic) NSAppleEventDescriptor *fileToken;

@end




#pragma mark -

@implementation CEODBEventSender


#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
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

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// ファイルクライアントにファイル更新を通知する
- (void)sendModifiedEventWithURL:(NSURL *)URLToSave operation:(NSSaveOperationType)saveOperationType
// ------------------------------------------------------
{
    AEEventID type = (saveOperationType == NSSaveAsOperation) ? keyNewLocation : kAEModifiedFile;
    
    [self sendODBEventWithType:type URL:URLToSave];
}


// ------------------------------------------------------
/// ファイルクライアントにファイルクローズを通知する
- (void)sendCloseEventWithURL:(NSURL *)fileURL
// ------------------------------------------------------
{
    [self sendODBEventWithType:kAEClosedFile URL:fileURL];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// ファイルクライアントに通知を送る
- (void)sendODBEventWithType:(AEEventID)eventType URL:(NSURL *)fileURL
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
    
    // 複数回コールされてしまう場合の予防措置
    if (eventType == kAEClosedFile || eventType == keyNewLocation) {
        [self setFileSender:nil];
    }
}

@end
