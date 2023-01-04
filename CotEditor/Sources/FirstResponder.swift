//
//  FirstResponder.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import AppKit

extension View {
    
    /// Provide access to the Cocoa responder chain.
    ///
    /// - Parameter firstResponder: The first responder.
    func responderChain(to firstResponder: FirstResponder) -> some View {
        
        self.background(MessageSender(responder: firstResponder))
    }
}



@propertyWrapper
final class FirstResponder {
    
    fileprivate weak var sender: NSControl?
    
    
    var wrappedValue: FirstResponder {
        
        self
    }
    
    
    /// Send the action message to the first responder, namely `nil`.
    ///
    /// - Parameters:
    ///   - action: The action message to send.
    ///   - tag: The tag to be owned by the message sender.
    /// - Returns: `true` if the action was successfully sent; otherwise `false`.
    @discardableResult
    func performAction(_ action: Selector, tag: Int = 0) -> Bool {
        
        self.sender?.tag = tag
        
        return NSApp.sendAction(action, to: nil, from: self.sender)
    }
}



private struct MessageSender: NSViewRepresentable {
    
    let responder: FirstResponder
    
    
    func makeNSView(context: Context) -> NSControl {
        
        NSControl()
    }
    
    
    func updateNSView(_ nsView: NSControl, context: Context) {
        
        self.responder.sender = nsView
    }
}
