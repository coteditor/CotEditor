//
//  NSWindow+SmallSizeToolbar.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-09-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

extension NSWindow {
    
    // MARK: Private Property
    
    /// Private method in AppKit
    private static let toggleUsingSmallToolbarIconsAction = Selector(("toggleUsingSmallToolbarIcons:"))
    
    
    
    // MARK: Public Methods
    
    var isToolbarConfigPanel: Bool {
        
        return self.className == "NSToolbarConfigPanel"
    }
    
    
    /// Remove "Use small size" menu item in the context menu of toolbar area.
    ///
    /// - Note:
    ///   This is really dirty way but works.
    ///   It actually doesn't matter if "Use Small Size" menu item cannot be removed.
    ///   What really matters is crashing, or any other unwanted side effects. So, be careful.
    ///   cf. https://forums.developer.apple.com/thread/21887
    final func removeSmallSizeToolbarContextMenuItem() {
        
        guard
            let contextMenu = self.contentView?.superview?.menu,
            let menuItem = contextMenu.items
                .first(where: { $0.action == Self.toggleUsingSmallToolbarIconsAction })
            else { return assertionFailure("No \"Use Small Size\" in the context menu.") }
        
        contextMenu.removeItem(menuItem)
    }
    
    
    /// Remove "Use small size" button in the toolbar customization sheet.
    final func removeSmallSizeToolbarButton() {
        
        guard
            let contentView = self.contentView,
            let toggleButton = contentView.descendants.lazy
                .compactMap({ $0 as? NSButton })
                .first(where: { $0.action == Self.toggleUsingSmallToolbarIconsAction })
            else { return assertionFailure("No \"Use Small Size\" in the sheet.") }
        
        toggleButton.isHidden = true
    }
    
}



private extension NSView {
    
    /// Find all subviews recursively.
    var descendants: [NSView] {
        
        return self.subviews + self.subviews.flatMap(\.descendants)
    }
    
}
