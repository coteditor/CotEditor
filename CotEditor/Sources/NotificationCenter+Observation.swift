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
    
    func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NotificationObservation {
        
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
        
        if let observer = self.observer {
            self.notificationCenter?.removeObserver(observer)
        }
        self.observer = nil
    }
    
}
