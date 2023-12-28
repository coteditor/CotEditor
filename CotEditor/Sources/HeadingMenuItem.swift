//
//  HeadingMenuItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2023 1024jp
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

public extension NSMenuItem {
    
    /// A back deployed version of the NSMenuItem.sectionHeader(title:) method.
    ///
    /// - Parameter title: The title to display.
    /// - Returns: A menu item.
    @backDeployed(before: macOS 14)
    static func sectionHeader(title: String) -> NSMenuItem {
        
        HeadingMenuItem(title: title)
    }
}


public final class HeadingMenuItem: NSMenuItem {
    
    // MARK: Lifecycle
    
    public convenience init(title: String) {
        
        self.init(title: title, action: nil, keyEquivalent: "")
        self.isEnabled = false
        
        self.updateAttributedTitle()
    }
    
    
    public override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.updateAttributedTitle()
    }
    
    
    public override var isSectionHeader: Bool {
        
        true
    }
    
    
    // MARK: Private Methods
    
    /// Makes the menu item label heading style.
    private func updateAttributedTitle() {
        
        self.attributedTitle = NSAttributedString(string: self.title, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium),
            .foregroundColor: NSColor.disabledControlTextColor,
        ])
    }
}
