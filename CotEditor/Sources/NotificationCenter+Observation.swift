//
//  NotificationCenter+Observation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-06-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import Foundation

extension NotificationCenter {
    
    /// Add an entry to the notification center's dispatch table that includes a notification queue and a block to add to the queue, and an optional notification name and sender.
    ///
    /// You don't need to remove the token from tne notification center on its deallocation. See the reference of the NotificationCener's version `.addObserver(forName:object:queue:using) -> NSObjectProcotol` for details.
    ///
    /// - Parameters:
    ///   - name: The name of the notification for which to register the observer.
    ///   - obj: The object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
    ///   - queue: The operation queue to which block should be added. If you pass `nil`, the block is run synchronously on the posting thread.
    ///   - block: The block to be executed when the notification is received.
    ///   - notification: The notification.
    /// - Returns: A wrapper of the token object to act as the observer.
    func addObserver(forName name: NSNotification.Name?, object obj: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (_ notification: Notification) -> Void) -> NotificationObservation {
        
        let observer: NSObjectProtocol = self.addObserver(forName: name, object: obj, queue: queue, using: block)
        
        return NotificationObservation(observer: observer, for: self)
    }
    
}



final class NotificationObservation {
    
    // MARK: Private Properties
    
    private var observer: NSObjectProtocol?
    private weak var notificationCenter: NotificationCenter?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    fileprivate init(observer: NSObjectProtocol, for notificationCenter: NotificationCenter) {
        
        self.observer = observer
        self.notificationCenter = notificationCenter
    }
    
    
    deinit {
        self.invalidate()
    }
    
    
    
    // MARK: Public Methods
    
    func invalidate() {
        
        guard let observer = self.observer else { return }
        
        assert(self.notificationCenter != nil)
        
        self.notificationCenter?.removeObserver(observer)
        self.observer = nil
    }
    
}
