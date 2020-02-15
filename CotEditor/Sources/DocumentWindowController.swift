//
//  DocumentWindowController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2013-2020 1024jp
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

final class DocumentWindowController: NSWindowController {
    
    // MARK: Private Properties
    
    private var windowAlphaObserver: UserDefaultsObservation?
    private var appearanceModeObserver: UserDefaultsObservation?
    
    @IBOutlet private var toolbarController: ToolbarController?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.windowAlphaObserver?.invalidate()
        self.appearanceModeObserver?.invalidate()
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        // -> Do not use "document" for autosave name because somehow windows forget the size with that name (2018-09)
        self.windowFrameAutosaveName = "Document Window"
        
        // set window size
        let contentSize = NSSize(width: UserDefaults.standard[.windowWidth],
                                 height: UserDefaults.standard[.windowHeight])
        self.window!.setContentSize(contentSize)
        (self.contentViewController as! WindowContentViewController).restoreAutosavingState()
        
        // set background alpha
        (self.window as? DocumentWindow)?.backgroundAlpha = UserDefaults.standard[.windowAlpha]
        
        // observe opacity setting change
        self.windowAlphaObserver?.invalidate()
        self.windowAlphaObserver = UserDefaults.standard.observe(key: .windowAlpha, options: [.new]) { [weak self] change in
            (self?.window as? DocumentWindow)?.backgroundAlpha = change.new!
        }
        
        // observe appearance setting change
        if #available(macOS 10.14, *) {
            self.appearanceModeObserver?.invalidate()
            self.appearanceModeObserver = UserDefaults.standard.observe(key: .documentAppearance, options: .initial) { [weak self] _ in
                self?.window?.appearance = {
                    switch UserDefaults.standard[.documentAppearance] {
                    case .default: return nil
                    case .light:   return NSAppearance(named: .aqua)
                    case .dark:    return NSAppearance(named: .darkAqua)
                    }
                }()
            }
        }
    }
    
    
    /// apply passed-in document instance to window
    override unowned(unsafe) var document: AnyObject? {
        
        didSet {
            guard let document = document as? Document else { return }
            
            self.toolbarController!.document = document
            self.contentViewController!.representedObject = document
            
            // -> In case when the window was created as a restored window (the right side ones in the browsing mode)
            if document.isInViewingMode, let window = self.window as? DocumentWindow {
                window.backgroundAlpha = 1.0
            }
        }
    }
    
    
    
    // MARK: Actions
    
    /// show editor opacity slider as popover
    @IBAction func showOpacitySlider(_ sender: Any?) {
        
        guard
            let window = self.window as? DocumentWindow,
            let origin = sender as? NSView ?? self.contentViewController?.view,
            let sliderViewController = self.storyboard?.instantiateController(withIdentifier: "Opacity Slider") as? NSViewController,
            let contentViewController = self.contentViewController
            else { return assertionFailure() }
        
        sliderViewController.representedObject = window.backgroundAlpha
        
        contentViewController.present(sliderViewController, asPopoverRelativeTo: .zero, of: origin,
                                      preferredEdge: .maxY, behavior: .transient)
    }
    
    
    /// change editor opacity via toolbar
    @IBAction func changeOpacity(_ sender: NSSlider) {
        
        (self.window as! DocumentWindow).backgroundAlpha = CGFloat(sender.doubleValue)
    }
    
}



extension DocumentWindowController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
        case #selector(showOpacitySlider):
            return self.window?.styleMask.contains(.fullScreen) == false
        case nil:
            return false
        default:
            return true
        }
    }
    
}



extension DocumentWindowController: NSWindowDelegate {
    
    // MARK: Window Delegate
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillEnterVersionBrowser(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillExitFullScreen(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    func windowWillExitVersionBrowser(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    
    // MARK: Private Methods
    
    private func restoreWindowOpacity() {
        
        guard let window = self.window as? DocumentWindow else { return }
        
        window.isOpaque = (window.backgroundAlpha == 1)
    }
    
}
