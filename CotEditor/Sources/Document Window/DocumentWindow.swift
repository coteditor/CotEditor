//
//  DocumentWindow.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-10-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import Defaults
import Shortcut
import ControlUI

final class DocumentWindow: NSWindow {
    
    // MARK: Public Properties
    
    var contentBackgroundColor: NSColor = .controlBackgroundColor {
        
        didSet {
            guard !self.isOpaque, contentBackgroundColor != oldValue else { return }
            
            self.backgroundColor = contentBackgroundColor.withAlphaComponent(self.backgroundAlpha)
            self.invalidateShadow()
            self.contentView?.needsDisplay = true
        }
    }
    
    @objc dynamic var backgroundAlpha: Double = 1.0 {
        
        didSet {
            backgroundAlpha = backgroundAlpha.clamped(to: 0.2...1.0)
            
            guard !self.styleMask.contains(.fullScreen) else { return }
            
            self.isOpaque = (backgroundAlpha == 1.0)
            
            self.backgroundColor = self.isOpaque ? nil : self.contentBackgroundColor.withAlphaComponent(backgroundAlpha)
            
            self.invalidateShadow()
            self.contentView?.needsDisplay = true
        }
    }
    
    
    // MARK: Window Methods
    
    override static var restorableStateKeyPaths: [String] {
        
        super.restorableStateKeyPaths + [#keyPath(backgroundAlpha), #keyPath(level)]
    }
    
    
    override static func allowedClasses(forRestorableStateKeyPath keyPath: String) -> [AnyClass] {
    
        switch keyPath {
            case #keyPath(backgroundAlpha), #keyPath(level):
                [NSNumber.self]
            default:
                super.allowedClasses(forRestorableStateKeyPath: keyPath)
        }
    }
    
    
    override var isOpaque: Bool {
        
        willSet { self.willChangeValue(for: \.isOpaque) }
        didSet { self.didChangeValue(for: \.isOpaque) }
    }
    
    
    // MARK: Actions
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleKeepOnTop):
                (item as? any StatableItem)?.state = self.isFloating ? .on : .off
                
            default:
                break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    /// Toggle the window level between normal and floating.
    @IBAction func toggleKeepOnTop(_ sender: Any?) {
        
        self.isFloating.toggle()
    }
    
    
    // MARK: Private Methods
    
    /// Whether the window level is floating.
    private var isFloating: Bool {
        
        get { self.level == .floating }
        set { self.level = newValue ? .floating : .normal }
    }
}


// MARK: Window Tabbing

extension DocumentWindow {
    
    /// Settable window user tabbing preference (Don't forget to set to `nil` after use.).
    static var tabbingPreference: NSWindow.UserTabbingPreference?
    
    
    // MARK: Window Methods
    
    override class var userTabbingPreference: NSWindow.UserTabbingPreference {
        
        if let tabbingPreference = self.tabbingPreference {
            return tabbingPreference
        }
        
        if let tabbingPreference = NSWindow.UserTabbingPreference(rawValue: UserDefaults.standard[.windowTabbing]), tabbingPreference.rawValue >= 0 {  // -1 obeys system setting
            return tabbingPreference
        }
        
        return super.userTabbingPreference
    }
    
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        
        guard !super.performKeyEquivalent(with: event) else { return true }
        
        // select tabbed window with `⌘-number` (`⌘9` for the last tab)
        if
            self.tabbingMode != .disallowed,
            let shortcut = Shortcut(keyDownEvent: event),
            shortcut.modifiers == [.command],
            let number = Int(shortcut.keyEquivalent), number > 0,
            let windows = self.tabbedWindows,
            let window = (number == 9) ? windows.last : windows[safe: number - 1]  // 1-based to 0-based
        {
            // prefer existing shortcut that user might define
            guard NSApp.mainMenu?.performKeyEquivalent(with: event) != true else { return true }
            
            window.tabGroup?.selectedWindow = window
            return true
        }
        
        return false
    }
}
