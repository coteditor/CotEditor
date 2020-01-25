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
//  © 2014-2019 1024jp
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

import Cocoa

final class DocumentWindow: NSWindow {
    
    // MARK: Notification Names
    
    static let didChangeOpacityNotification = Notification.Name("WindowDidChangeOpacity")
    
    
    // MARK: Public Properties
    
    var contentBackgroundColor: NSColor = .controlBackgroundColor {
        
        didSet {
            guard !self.isOpaque, contentBackgroundColor != oldValue else { return }
            
            self.backgroundColor = contentBackgroundColor.withAlphaComponent(self.backgroundAlpha)
            self.invalidateShadow()
            self.contentView?.needsDisplay = true
        }
    }
    
    @objc var backgroundAlpha: CGFloat = 1.0 {
        
        didSet {
            backgroundAlpha = backgroundAlpha.clamped(to: 0.2...1.0)
            
            self.isOpaque = (backgroundAlpha == 1.0)
            self.backgroundColor = self.isOpaque ? nil : self.contentBackgroundColor.withAlphaComponent(backgroundAlpha)
            
            self.invalidateShadow()
            self.contentView?.needsDisplay = true
        }
    }
    
    
    // MARK: Private Properties
    
    private var appearanceObserver: NSKeyValueObservation?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        
        self.appearanceObserver = self.observe(\.effectiveAppearance) { [weak self] (_, _) in
            guard let self = self, !self.isOpaque else { return }
            
            self.invalidateTitlebarOpacity()
        }
    }
    
    
    deinit {
        self.appearanceObserver?.invalidate()
    }
    
    
    
    // MARK: Window Methods
    
    /// keys to be restored from the last session
    override class var restorableStateKeyPaths: [String] {
        
        return super.restorableStateKeyPaths + [
            #keyPath(backgroundAlpha),
        ]
    }
    
    
    /// notify about opacity change
    override var isOpaque: Bool {
        
        didSet {
            guard isOpaque != oldValue else { return }
            
            self.invalidateTitlebarOpacity()
            
            NotificationCenter.default.post(name: DocumentWindow.didChangeOpacityNotification, object: self)
        }
    }
    
    
    /// resore UI state
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if coder.containsValue(forKey: #keyPath(backgroundAlpha)) {
            self.backgroundAlpha = CGFloat(coder.decodeDouble(forKey: #keyPath(backgroundAlpha)))
        }
    }
    
    
    /// store UI state
    override func encodeRestorableState(with coder: NSCoder) {
        
        super.encodeRestorableState(with: coder)
        
        coder.encode(Double(self.backgroundAlpha), forKey: #keyPath(backgroundAlpha))
    }
    
    
    
    // MARK: Private Methods
    
    /// make sure window title bar (incl. toolbar) is opaque
    private func invalidateTitlebarOpacity() {
        
        guard let titlebarView = self.titlebarView else { return }
        
        // dirty manupulation to avoid the title bar being dyed in the window background color (2016-01).
        titlebarView.wantsLayer = !self.isOpaque
        titlebarView.layer?.backgroundColor = self.isOpaque ? nil : NSColor.windowBackgroundColor.cgColor(for: self.effectiveAppearance)
    }

}



// MARK: Window Tabbing

extension DocumentWindow {
    
    /// settable window user tabbing preference (Don't forget to set to `nil` after use.)
    static var tabbingPreference: NSWindow.UserTabbingPreference?
    
    
    
    // MARK: Window Methods
    
    override class var userTabbingPreference: NSWindow.UserTabbingPreference {
        
        if let tabbingPreference = self.tabbingPreference {
            return tabbingPreference
        }
        
        if let tabbingPreference = NSWindow.UserTabbingPreference(rawValue: UserDefaults.standard[.windowTabbing]), tabbingPreference.rawValue >= 0 {  // -1 obays system setting
            return tabbingPreference
        }
        
        return super.userTabbingPreference
    }
    
    
    /// process user's shortcut input
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        
        guard !super.performKeyEquivalent(with: event) else { return true }
        
        // prefer existing shortcut that user might define
        guard !NSApp.mainMenu!.performKeyEquivalent(with: event) else { return true }
        
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting(.numericPad)
        
        // toggle tab bar with ⌘⇧T`
        // -> This is needed under the case when "Show/Hide Tab Bar" menu item is not yet added to the View menu. (2020-01)
        if modifierFlags == [.command, .shift], event.characters == "t" {
            self.toggleTabBar(nil)
            return true
        }
        
        // select tabbed window with `⌘+number` (`⌘9` for the last tab)
        if
            modifierFlags == [.command],
            let characters = event.charactersIgnoringModifiers,
            let number = Int(characters), number > 0,
            let windows = self.tabbedWindows,
            let window = (number == 9) ? windows.last : windows[safe: number - 1]  // 1-based to 0-based
        {
            window.tabGroup?.selectedWindow = window
            return true
        }
        
        return false
    }
    
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        // programmatically set the shortcut for "Show/Hide Tab Bar", which is inserted by AppKit automatically.
        switch menuItem.action {
        case #selector(toggleTabBar):
            menuItem.keyEquivalentModifierMask = [.command, .shift]
            menuItem.keyEquivalent = "t"
        default:
            break
        }
        
        return super.validateMenuItem(menuItem)
    }
    
}


// MARK: -

private extension NSWindow {
    
    var titlebarView: NSVisualEffectView? {
        
        return self.standardWindowButton(.closeButton)?.superview as? NSVisualEffectView
    }
    
}
