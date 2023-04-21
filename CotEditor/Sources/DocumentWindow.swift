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
//  © 2014-2023 1024jp
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

import Combine
import Cocoa

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
    
    @objc var backgroundAlpha: CGFloat = 1.0 {
        
        didSet {
            backgroundAlpha = backgroundAlpha.clamped(to: 0.2...1.0)
            
            guard !self.styleMask.contains(.fullScreen) else { return }
            
            self.isOpaque = (backgroundAlpha == 1.0)
            
            self.backgroundColor = self.isOpaque ? nil : self.contentBackgroundColor.withAlphaComponent(backgroundAlpha)
            
            self.invalidateShadow()
            self.contentView?.needsDisplay = true
            self.invalidateRestorableState()
        }
    }
    
    
    // MARK: Private Properties
    
    private var appearanceObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Window Methods
    
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {
        
        super.encodeRestorableState(with: coder, backgroundQueue: queue)
        
        coder.encode(self.backgroundAlpha, forKey: #keyPath(backgroundAlpha))
        coder.encode(self.level, forKey: #keyPath(level))
    }
    
    
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        
        if let alpha = coder.decodeObject(of: NSNumber.self, forKey: #keyPath(backgroundAlpha)) as? CGFloat, alpha != 1 {
            self.backgroundAlpha = alpha
        }
        if let level = coder.decodeObject(of: NSNumber.self, forKey: #keyPath(level)) as? NSWindow.Level, level == .floating {
            self.isFloating = true
        }
    }
    
    
    override var isOpaque: Bool {
        
        willSet {
            self.willChangeValue(for: \.isOpaque)
        }
        
        didSet {
            self.didChangeValue(for: \.isOpaque)
            
            guard isOpaque != oldValue else { return }
            
            self.invalidateTitlebarOpacity()
            
            if isOpaque {
                self.appearanceObserver = nil
            } else if self.appearanceObserver == nil {
                self.appearanceObserver = self.publisher(for: \.effectiveAppearance)
                    .sink { [weak self] _ in self?.invalidateTitlebarOpacity() }
            }
        }
    }
    
    
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        
        // workaround the issue that the initial window height could differ from the user-specified value
        // (macOS 13, 2022-11)
        if self.windowController?.isWindowLoaded == true,
           self.windowController?.document == nil,
           UserDefaults.standard[.windowHeight] > 0
        { return }
        
        super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
    }
    
    
    override func miniaturize(_ sender: Any?) {
        
        super.miniaturize(sender)
        
        // workaround an issue with Stage Manager (2023-04 macOS 13, FB12129976)
        if self.isFloating {
            self.level = .normal
        }
    }
    
    
    override func makeKey() {
        
        super.makeKey()
        
        // workaround an issue with Stage Manager (2023-04 macOS 13, FB12129976)
        if self.isFloating {
            self.level = .floating
        }
    }
    
    
    // MARK: Actions
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleTabBar):
                (item as? NSMenuItem)?.keyEquivalentModifierMask = [.command, .shift]
                (item as? NSMenuItem)?.keyEquivalent = "t"
                
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
    
    /// Wthether the window level is floating.
    private var isFloating: Bool = false {
        
        didSet {
            self.level = isFloating ? .floating : .normal
            self.invalidateRestorableState()
        }
    }
    
    
    /// Make sure window title bar (incl. toolbar) is opaque.
    private func invalidateTitlebarOpacity() {
        
        guard let titlebarView = self.standardWindowButton(.closeButton)?.superview else { return }
        
        // dirty manipulation to avoid the title bar being dyed in the window background color (2016-01).
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
        guard NSApp.mainMenu?.performKeyEquivalent(with: event) != true else { return true }
        
        guard let shortcut = Shortcut(keyDownEvent: event) else { return true }
        
        // toggle tab bar with ⌘⇧T`
        // -> This is needed under the case when "Show/Hide Tab Bar" menu item is not yet added to the View menu. (2020-01)
        if shortcut.modifierMask == [.command, .shift], shortcut.keyEquivalent == "T" {
            self.toggleTabBar(nil)
            return true
        }
        
        // select tabbed window with `⌘+number` (`⌘9` for the last tab)
        if shortcut.modifierMask == [.command],
           let number = Int(shortcut.keyEquivalent), number > 0,
           let windows = self.tabbedWindows,
           let window = (number == 9) ? windows.last : windows[safe: number - 1]  // 1-based to 0-based
        {
            window.tabGroup?.selectedWindow = window
            return true
        }
        
        return false
    }
}
