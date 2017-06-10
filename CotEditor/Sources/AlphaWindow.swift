/*
 
 AlphaWindow.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-10-31.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension Notification.Name {
    
    static let WindowDidChangeOpacity = Notification.Name("WindowDidChangeOpacity")
}



// MARK: -

final class AlphaWindow: NSWindow {
    
    // MARK: Public Properties
    
    var backgroundAlpha: CGFloat = 1.0 {
        
        didSet {
            backgroundAlpha = backgroundAlpha.within(min: 0.2, max: 1.0)
            self.backgroundColor = self.backgroundColor.withAlphaComponent(backgroundAlpha)
            self.isOpaque = (backgroundAlpha == 1.0)
            self.invalidateShadow()
        }
    }
    
    
    // MARK: Private Properties
    
    private var storedBackgroundAlpha: CGFloat?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        
        // make sure window title bar (incl. toolbar) is opaque
        //   -> It's actucally a bit dirty way but practically works well.
        //      Without this tweak, the title bar will be dyed in the background color on El Capitan. (2016-01 by 1024p)
        if let windowTitleView = self.standardWindowButton(.closeButton)?.superview {
            windowTitleView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
        
        // observe toggling Versions browsing
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterOpaqueMode), name: NSWindow.willEnterVersionBrowserNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(willExitOpaqueMode), name: NSWindow.willExitVersionBrowserNotification, object: self)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Window Methods
    
    /// notify about opacity change
    override var isOpaque: Bool {
        
        didSet {
            guard isOpaque != oldValue else { return }
            
            NotificationCenter.default.post(name: .WindowDidChangeOpacity, object: self)
        }
    }
    
    
    /// apply alpha value to input background color
    override var backgroundColor: NSColor! {
        
        didSet {
            super.backgroundColor = backgroundColor?.withAlphaComponent(self.backgroundAlpha)
        }
    }
    
    
    
    // MARK: Notifications
    
    /// entering Versions
    @objc private func willEnterOpaqueMode(_ notification: Notification) {
        
        self.storedBackgroundAlpha = self.backgroundAlpha
        self.backgroundAlpha = 1.0
    }
    
    
    /// exiting Versions
    @objc private func willExitOpaqueMode(_ notification: Notification) {
        
        if let backgroundAlpha = self.storedBackgroundAlpha {
            self.backgroundAlpha = backgroundAlpha
            self.storedBackgroundAlpha = nil
        }
    }

}



// MARK: Window Tabbing

@available(macOS 10.12, *)
extension AlphaWindow {
    
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
    
}
