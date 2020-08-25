//
//  PreferencesTabViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-11-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

final class PreferencesTabViewController: NSTabViewController {
    
    private var lastFrameSize: NSSize?
    
    
    
    // MARK: -
    // MARK: Tab View Controller Methods
    
    override var selectedTabViewItemIndex: Int {
        
        didSet {
            if self.isViewLoaded {  // avoid storing initial state (set in the storyboard)
                UserDefaults.standard[.lastPreferencesPaneIdentifier] = self.tabViewItems[selectedTabViewItemIndex].identifier as? String
            }
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set fallback toolbar images for macOS 10.15
        if ProcessInfo().operatingSystemVersion.majorVersion < 11 {
            for item in self.tabViewItems {
                guard
                    let identifier = item.identifier as? String,
                    let image = NSImage(named: "Preferences/" + identifier)
                    else { continue }
                
                item.image = image
            }
        }
        
        // select last used pane
        if
            let identifier = UserDefaults.standard[.lastPreferencesPaneIdentifier],
            let item = self.tabViewItems.enumerated().first(where: { ($0.element.identifier as? String) == identifier })
        {
            self.selectedTabViewItemIndex = item.offset
        }
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.view.window!.title = self.tabViewItems[self.selectedTabViewItemIndex].label
    }
    
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        
        super.tabView(tabView, willSelect: tabViewItem)
        
        self.lastFrameSize = tabViewItem?.view?.frame.size
    }
    
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        
        super.tabView(tabView, didSelect: tabViewItem)
        
        guard let tabViewItem = tabViewItem else { return assertionFailure() }
        
        self.switchPane(to: tabViewItem)
    }
    
    
    
    // MARK: Private Methods
    
    /// resize window to fit to new view
    private func switchPane(to tabViewItem: NSTabViewItem) {
        
        guard let contentSize = self.lastFrameSize ?? tabViewItem.view?.frame.size else { return assertionFailure() }
        
        // initialize tabView's frame size
        guard let window = self.view.window else {
            self.view.frame.size = contentSize
            return
        }
        
        NSAnimationContext.runAnimationGroup({ _ in
            self.view.isHidden = true
            window.animator().setFrame(for: contentSize)
            
        }, completionHandler: { [weak self] in
            self?.view.isHidden = false
            window.title = tabViewItem.label
        })
    }
    
}



private extension NSWindow {
    
    /// calculate window frame for the given contentSize
    func setFrame(for contentSize: NSSize, flag: Bool = false) {
        
        let frameSize = self.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        let frame = NSRect(origin: self.frame.origin, size: frameSize)
            .offsetBy(dx: 0, dy: self.frame.height - frameSize.height)
        
        self.setFrame(frame, display: flag)
    }
    
}
