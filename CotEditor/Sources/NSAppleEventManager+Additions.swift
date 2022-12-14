//
//  NSAppleEventManager+Additions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

import Foundation.NSAppleEventManager

extension NSAppleEventManager {
    
    /// whether now is open/reopen event
    var isOpenEvent: Bool {
        
        guard
            let event = self.currentAppleEvent,
            event.eventClass == kCoreEventClass
        else { return false }
        
        return (event.eventID == kAEOpenApplication || event.eventID == kAEReopenApplication)
    }
}
