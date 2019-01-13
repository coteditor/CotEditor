//
//  ThemeViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-12.
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
import ColorCode

protocol ThemeViewControllerDelegate: AnyObject {
    
    func didUpdate(theme: ThemeManager.ThemeDictionary)
}



// MARK: -

final class ThemeViewController: NSViewController {
    
    // MARK: Public Properties
    
    @objc dynamic var theme: ThemeManager.ThemeDictionary? {
        
        willSet {
            // remove current observing (in case when the theme is restored)
            self.endThemeObserving()
        }
        
        didSet {
            // observe input theme
            self.beginThemeObserving()
            
            // add metadata's NSMutableDictionary beforehand for KVO by NSObjectController
            if self.theme?[DictionaryKey.metadata.rawValue] == nil {
                self.theme?[DictionaryKey.metadata.rawValue] = NSMutableDictionary()
            }
        }
    }
    
    @objc dynamic var isBundled = false
    
    weak var delegate: ThemeViewControllerDelegate?
    
    
    // MARK: Private Properties
    
    private var storedMetadata: NSDictionary?
    private var observedKeys: Set<String> = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.endThemeObserving()
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
    }
    
    
    override func viewDidAppear() {
        
        super.viewDidAppear()
        
        // workaround for macOS 10.12 where NSColorWell do not update while the view is hidden
        // (2019-01 macOS 10.14)
        if NSAppKitVersion.current < .macOS10_13 {
            let theme = self.theme
            self.theme = nil
            self.theme = theme
        }
    }
    
    
    
    // MARK: View Controller Methods
    
    /// finish current editing
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
    }
    
    
    /// send data to metadata popover
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard let destinationController = segue.destinationController as? ThemeMetaDataViewController else { return }
        
        destinationController.representedObject = self.theme
        destinationController.isBundled = self.isBundled
        self.storedMetadata = self.theme?[DictionaryKey.metadata.rawValue]?.copy() as? NSDictionary
    }
    
    
    /// metadata popover closed
    override func dismiss(_ viewController: NSViewController) {
        
        if viewController is ThemeMetaDataViewController,
            self.storedMetadata != self.theme?[DictionaryKey.metadata.rawValue]
        {
            self.notifyUpdate()
        }
        
        super.dismiss(viewController)
    }
    
    
    /// theme is modified
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case let keyPath? where self.observedKeys.contains(keyPath):
            self.notifyUpdate()
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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
    
    
    /// begin observing theme change
    private func beginThemeObserving() {
        
        guard let theme = self.theme else { return }
        
        self.observedKeys.removeAll()
        for (key, subdict) in theme {
            guard key != DictionaryKey.metadata.rawValue else { continue }
            
            for case let keyPath as String in subdict.allKeys {
                subdict.addObserver(self, forKeyPath: keyPath, context: nil)
                self.observedKeys.update(with: keyPath)
            }
        }
    }
    
    
    /// end observing current theme
    private func endThemeObserving() {
        
        guard let theme = self.theme else { return }
        
        self.observedKeys.removeAll()
        for (key, subdict) in theme {
            guard key != DictionaryKey.metadata.rawValue else { continue }
            
            for case let keyPath as String in subdict.allKeys {
                subdict.removeObserver(self, forKeyPath: keyPath)
            }
        }
    }
    
}
