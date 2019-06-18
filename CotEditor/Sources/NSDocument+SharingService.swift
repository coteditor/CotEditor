//
//  NSDocument+SharingService.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2019 1024jp
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

import AppKit

extension NSDocument {
    
    /// show Share Service menu (invoked by a toolbar item)
    @IBAction func showShareMenu(_ sender: NSView) {
        
        let sharingServicePicker = NSSharingServicePicker(items: [self])
        
        sharingServicePicker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
    
}
