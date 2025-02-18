//
//  FontPicker.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

struct FontPicker: View {
    
    private var label: String
    @Binding private var font: NSFont
    
    @State private var delegate: Delegate?
    
    
    init(_ label: String, selection: Binding<NSFont>) {
        
        self.label = label
        self._font = selection
    }
    
    
    var body: some View {
        
        Button(self.label) {
            self.delegate = Delegate { manager in
                self.font = manager.convert(self.font)
            }
            NSFontManager.shared.target = self.delegate
            NSFontPanel.shared.setPanelFont(self.font, isMultiple: false)
            NSFontPanel.shared.orderBack(nil)
        }.onDisappear {
            NSFontManager.shared.target = nil
            NSFontManager.shared.fontPanel(false)?.close()
        }
    }
    
    
    private final class Delegate {
        
        var action: (NSFontManager) -> Void
        
        
        init(action: @escaping (NSFontManager) -> Void) {
            
            self.action = action
        }
        
        
        /// The font selection in the font panel did update.
        @objc func changeFont(_ sender: NSFontManager) {
            
            self.action(sender)
        }
        
        
        /// Restricts items to display in the font panel.
        @objc func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
            
            [.collection, .face, .size]
        }
    }
}
