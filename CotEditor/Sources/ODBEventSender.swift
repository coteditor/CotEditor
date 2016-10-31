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
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

final class ODBEventSender {
    
    // MARK: Enum
    
    enum EventType {
        
        case modified
        case newLocation
        case closed
        
        
        var eventID: AEEventID {
            
            switch self {
            case .modified: return kAEModifiedFile
            case .newLocation: return keyNewLocation
            case .closed: return kAEClosedFile
            }
        }
        
    }
    
    
    // MARK: Private Properties
    
    private let senderData: Data
    private let token: NSAppleEventDescriptor?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init?(event descriptor: NSAppleEventDescriptor) {
        
        guard
            let sender = descriptor.paramDescriptor(forKeyword: keyFileSender),
            sender.typeCodeValue != 0
            else { return nil }
        
        self.senderData = sender.data
        self.token = descriptor.paramDescriptor(forKeyword: keyFileSenderToken)
    }
    
    
    
    // MARK: Public Methods
    
    /// send a notification to the file client
    @discardableResult
    func sendEvent(type: EventType, fileURL: URL) -> Bool {
        
        let target = NSAppleEventDescriptor(descriptorType: typeApplSignature, data: self.senderData)
        let event = NSAppleEventDescriptor.appleEvent(withEventClass: kODBEditorSuite,
                                                      eventID: type.eventID,
                                                      targetDescriptor: target,
                                                      returnID: AEReturnID(kAutoGenerateReturnID),
                                                      transactionID: AETransactionID(kAnyTransactionID))
        
        let urlData = fileURL.absoluteString.data(using: .utf8)
        if let fileDescriptor = NSAppleEventDescriptor(descriptorType: typeFileURL, data: urlData) {
            event.setParam(fileDescriptor, forKeyword: keyDirectObject)
        }
        
        if let token = self.token {
            event.setParam(token, forKeyword: keySenderToken)
        }
        
        let err = AESendMessage(event.aeDesc, nil, AESendMode(kAENoReply), kAEDefaultTimeout)
        
        return (err == noErr)
    }
    
}
