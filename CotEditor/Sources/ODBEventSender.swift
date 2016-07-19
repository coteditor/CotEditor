/*
 
 ODBEventSender.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-07-04.
 
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

import Cocoa

class ODBEventSender: NSObject {  // TODO: to struct
    
    // MARK: Private Properties
    
    private let fileSender: NSAppleEventDescriptor?
    private let fileToken: NSAppleEventDescriptor?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        let descriptor = NSAppleEventManager.shared().currentAppleEvent
        
        var fileSender, fileToken: NSAppleEventDescriptor?
        
        fileSender = descriptor?.paramDescriptor(forKeyword: keyFileSender)
        
        if fileSender != nil {
            fileToken = descriptor?.paramDescriptor(forKeyword: keyFileSenderToken)
            
        } else {
            let aePropDescriptor = descriptor?.paramDescriptor(forKeyword: keyAEPropData)
            fileSender = aePropDescriptor?.paramDescriptor(forKeyword: keyFileSender)
            fileToken = aePropDescriptor?.paramDescriptor(forKeyword: keyFileSenderToken)
        }
        
        self.fileSender = fileSender
        self.fileToken = (fileSender != nil) ? fileToken : nil
        
        super.init()
    }
    
    
    
    // MARK: Public Methods
    
    /// notify the file update to the file client
    func sendModifiedEvent(fileURL: URL, operation: NSSaveOperationType)  {
        
        let type = (operation == .saveAsOperation) ? keyNewLocation : kAEModifiedFile
        
        self.sendEvent(type: type, fileURL: fileURL)
    }
    
    
    /// nofity the file closing to the file client
    func sendCloseEvent(fileURL: URL) {
        
        self.sendEvent(type: kAEClosedFile, fileURL: fileURL)
    }
    
    
    
    // MARK: Private Methods
    
    /// send a notification to the file client
    private func sendEvent(type eventType: AEEventID, fileURL: URL) {
        
        guard var creatorCode = self.fileSender?.typeCodeValue, creatorCode != 0 else { return }
        
        let creatorDescriptor = NSAppleEventDescriptor(descriptorType: typeApplSignature,
                                                       bytes: &creatorCode,
                                                       length: sizeof(OSType.self))
        
        let eventDescriptor = NSAppleEventDescriptor.appleEvent(withEventClass: 0,
                                                                eventID: eventType,
                                                                targetDescriptor: creatorDescriptor,
                                                                returnID: AEReturnID(kAutoGenerateReturnID),
                                                                transactionID: AETransactionID(kAnyTransactionID))
        
        let urlData = fileURL.absoluteString?.data(using: .utf8)
        if let fileDescriptor = NSAppleEventDescriptor(descriptorType: typeFileURL, data: urlData) {
            eventDescriptor.setParam(fileDescriptor, forKeyword: keyDirectObject)
        }
        
        if let fileToken = self.fileToken {
            eventDescriptor.setParam(fileToken, forKeyword: keySenderToken)
        }
        
        AESendMessage(eventDescriptor.aeDesc, nil, AESendMode(kAENoReply), kAEDefaultTimeout)
    }
    
}
