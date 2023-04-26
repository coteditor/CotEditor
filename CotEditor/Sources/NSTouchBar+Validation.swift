//
//  NSTouchBar+Validation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-12-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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
import Combine

protocol TouchBarItemValidations: AnyObject {
    
    func validateTouchBarItem(_ item: NSTouchBarItem) -> Bool
}



extension NSTouchBar {
    
    /// flag to enable automatic touch bar item validation
    static var isAutomaticValidationEnabled = false {
        
        didSet {
            TouchBarValidator.shared.isEnabled = isAutomaticValidationEnabled
        }
    }
    
    
    
    /// validate currently visible touch bar items
    func validateVisibleItems() {
        
        guard self.isVisible else { return }
        
        for identifier in self.itemIdentifiers {
            guard let item = self.item(forIdentifier: identifier), item.isVisible else { continue }
            
            switch item {
                case let item as NSCustomTouchBarItem:
                    item.validate()
                    
                case let item as NSGroupTouchBarItem:
                    item.groupTouchBar.validateVisibleItems()
                    
                case let item as NSPopoverTouchBarItem:
                    item.popoverTouchBar.validateVisibleItems()
                    item.pressAndHoldTouchBar?.validateVisibleItems()
                    
                default: break
            }
        }
    }
}



// MARK: -

private final class TouchBarValidator {
    
    // MARK: Public Properties
    
    static let shared = TouchBarValidator()
    
    
    var isEnabled: Bool = false {
        
        didSet {
            guard isEnabled != oldValue else { return }
            
            if isEnabled {
                self.applicationObserver = NotificationCenter.default.publisher(for: NSApplication.didUpdateNotification)
                    .sink { [weak self] _ in self?.validateTouchBarIfNeeded() }
            } else {
                self.applicationObserver = nil
            }
        }
    }
    
    
    
    // MARK: Private Properties
    
    private weak var validationTimer: Timer?
    private var applicationObserver: AnyCancellable?
    
    
    private enum ValidationDelay: TimeInterval {
        
        case normal = 0.1
        case lazy = 0.85
    }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() { }
    
    
    deinit {
        self.validationTimer?.invalidate()
    }
    
    
    
    // MARK: Private Methods
    
    /// validate current touch bar
    @objc private func validateTouchBar(timer: Timer?) {
        
        self.validationTimer?.invalidate()
        
        NSApp.touchBar?.validateVisibleItems()
        
        guard let firstResponder = NSApp.mainWindow?.firstResponder else { return }
        
        for responder in sequence(first: firstResponder, next: \.nextResponder) {
            responder.touchBar?.validateVisibleItems()
        }
    }
    
    
    /// check necessity of touch bar validation and schedule with a delay if needed
    private func validateTouchBarIfNeeded() {
        
        assert(self.isEnabled)
        
        // skip validation for specific events just like NSToolbar does
        // -> See Apple's API reference for NSToolbar's `validateVisibleItems()` to see which events should be skipped:
        //      cf. https://developer.apple.com/reference/appkit/nstoolbar/1516947-validatevisibleitems
        let delay: ValidationDelay
        switch NSApp.currentEvent?.type {
            case .leftMouseDragged,
                 .rightMouseDragged,
                 .otherMouseDragged,
                 .mouseEntered,
                 .mouseExited,
                 .scrollWheel,
                 .cursorUpdate,
                 .keyDown,
                 .mouseMoved,
                 nil:
                return
                
            case .keyUp,
                 .flagsChanged:
                delay = .lazy
                
            default:
                delay = .normal
        }
        
        // schedule validation with delay
        // -> A tiny delay makes sense:
        //      1. To wait for state change.
        //      2. To gather multiple events.
        if let timer = self.validationTimer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: ValidationDelay.normal.rawValue)
        } else {
            self.validationTimer = Timer.scheduledTimer(timeInterval: delay.rawValue,
                                                        target: self,
                                                        selector: #selector(validateTouchBar(timer:)),
                                                        userInfo: nil,
                                                        repeats: false)
            self.validationTimer?.tolerance = 0.1 * delay.rawValue
        }
    }
}



// MARK: -

extension NSCustomTouchBarItem: NSValidatedUserInterfaceItem {
    
    /// validate item if content view is NSControl
    fileprivate func validate() {
        
        // validate content control
        guard
            let control = self.control,
            let validator = control.target
                ?? control.action.flatMap({ NSApp.target(forAction: $0, to: control.target, from: self) }) as AnyObject?
        else { return }
        
        switch validator {
            case let validator as any TouchBarItemValidations:
                control.isEnabled = validator.validateTouchBarItem(self)
            case let validator as any NSUserInterfaceValidations:
                control.isEnabled = validator.validateUserInterfaceItem(self)
            default: break
        }
    }
    
    
    
    // MARK: Validated User Interface Item Protocol
    
    public var action: Selector? {
        
        self.control?.action
    }
    
    
    public var tag: Int {
        
        self.control?.tag ?? 0
    }
    
    
    
    // MARK: Private Methods
    
    private var control: NSControl? {
        
        self.view as? NSControl
    }
}
