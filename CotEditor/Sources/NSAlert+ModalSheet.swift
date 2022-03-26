//
//  NSAlert+ModalSheet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-11-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

extension NSAlert {
    
    /// display alert as a sheet attached to the specified window but wait until sheet close like normal `runModal()`
    @MainActor func runModal(for sheetWindow: NSWindow) -> NSApplication.ModalResponse {
        
        self.beginSheetModal(for: sheetWindow) { (returnCode: NSApplication.ModalResponse) in
            NSApp.stopModal(withCode: returnCode)
        }
        
        return NSApp.runModal(for: self.window)
    }
    
}
