/*
 
 ThemeViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-12.
 
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
import ColorCode

protocol ThemeViewControllerDelegate: class {
    
    func didUpdate(theme: ThemeDictionary)
}



// MARK:

final class ThemeViewController: NSViewController, NSPopoverDelegate, NSTextFieldDelegate {
    
    dynamic var theme: ThemeDictionary? {
        willSet {
            // remove current observing (in case when the theme is restored)
            self.endThemeObserving()
            
            // observe input theme
            if let theme = newValue {
                self.observe(theme: theme)
            }
        }
        didSet {
            // add metadata's NSMutableDictionary beforehand for KVO by NSObjectController
            if self.theme?[DictionaryKey.metadata.rawValue] == nil {
                self.theme?[DictionaryKey.metadata.rawValue] = NSMutableDictionary()
            }
        }
    }
    dynamic var isBundled = false
    
    weak var delegate: ThemeViewControllerDelegate?
    
    
    private var isMetadataEdited = false
    @IBOutlet private var popover: NSPopover?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.popover?.delegate = nil  // avoid crash (2014-12-31)
        self.endThemeObserving()
    }
    
    
    override var nibName: String? {
        
        return "ThemeView"
    }
    
    
    
    // MARK: View Controller Methods
    
    /// finish current editing
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
    }
    
    
    /// theme is modified
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        self.notifyUpdate()
    }
    
    
    
    // MARK: Delegate
    
    /// meta data was possible edited
    override func controlTextDidChange(_ obj: Notification) {
        
        self.isMetadataEdited = true
    }
    
    
    /// popover closed
    func popoverDidClose(_ obj: Notification) {
        
        if self.isMetadataEdited {
            self.notifyUpdate()
            self.isMetadataEdited = false
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// apply system highlight color to color well
    @IBAction func applySystemSelectionColor(_ button: NSButton) {
        
        guard button.state == NSOnState else { return }
        
        let color = NSColor.selectedTextBackgroundColor
        let colorCode = color.usingColorSpaceName(NSCalibratedRGBColorSpace)?.colorCode(type: .hex)
        
        self.theme?[ThemeKey.selection.rawValue]?[ThemeKey.Sub.color.rawValue] = colorCode
    }
    
    
    /// show medatada of theme file via popover
    @IBAction func showMedatada(_ button: NSButton) {
        
        self.popover?.show(relativeTo: button.frame, of: self.view, preferredEdge: .maxY)
    }
    
    
    /// jump to theme's destribution URL
    @IBAction func jumpToURL(_ sender: Any?) {
        
        guard let address = self.theme?[DictionaryKey.metadata.rawValue]?[MetadataKey.distributionURL.rawValue] as? String,
              let url = URL(string: address) else
        {
                NSBeep()
                return
        }
        
        NSWorkspace.shared().open(url)
    }
    
    
    
    // MARK: Private Methods
    
    /// notify theme update to delegate
    private func notifyUpdate() {
        
        guard var theme = self.theme else { return }
        
        // remove metadata key if empty
        if theme[DictionaryKey.metadata.rawValue]?.count == 0 {
            theme[DictionaryKey.metadata.rawValue] = nil
        }
        
        self.delegate?.didUpdate(theme: theme)
    }
    
    
    /// start observing theme change
    private func observe(theme: ThemeDictionary) {
        
        for (key, subdict) in theme {
            guard key != DictionaryKey.metadata.rawValue else { continue }
            
            for subkey in subdict.allKeys {
                guard let keyPath = subkey as? String else { continue }
                
                subdict.addObserver(self, forKeyPath: keyPath, context: nil)
            }
        }
    }
    
    
    /// end observingcurrent theme
    private func endThemeObserving() {
        
        guard let theme = self.theme else { return }
        
        for (key, subdict) in theme {
            guard key != DictionaryKey.metadata.rawValue else { continue }
            
            for subkey in subdict.allKeys {
                guard let keyPath = subkey as? String else { continue }
                
                subdict.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }
    
}
