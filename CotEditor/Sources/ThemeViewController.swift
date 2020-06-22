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
//  © 2014-2020 1024jp
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
    
    func didUpdate(theme: Theme)
}


final class ThemeViewController: NSViewController {
    
    // MARK: Public Properties
    
    @objc dynamic var theme: Theme? {
        
        didSet {
            // add metadata beforehand for KVO by NSObjectController
            if theme?.metadata == nil {
                theme?.metadata = Metadata()
            }
        }
    }
    
    @objc dynamic var isBundled = false
    
    weak var delegate: ThemeViewControllerDelegate?
    
    
    // MARK: Private Properties
    
    private var storedMetadata: Metadata?
    private var themeObserver: NSObjectProtocol?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        if let observer = self.themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        if let observer = self.themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        self.themeObserver = NotificationCenter.default.addObserver(forName: Theme.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.notifyUpdate()
        }
    }
    
    
    /// finish current editing
    override func viewWillDisappear() {
        
        super.viewWillDisappear()
        
        self.endEditing()
        
        if let observer = self.themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    /// send data to metadata popover
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard let destinationController = segue.destinationController as? ThemeMetaDataViewController else { return }
        
        destinationController.representedObject = self.theme?.metadata
        destinationController.isBundled = self.isBundled
        self.storedMetadata = self.theme?.metadata
    }
    
    
    /// metadata popover closed
    override func dismiss(_ viewController: NSViewController) {
        
        if viewController is ThemeMetaDataViewController,
            self.storedMetadata != self.theme?.metadata
        {
            self.notifyUpdate()
        }
        
        super.dismiss(viewController)
    }
    
    
    
    // MARK: Private Methods
    
    /// notify theme update to delegate
    private func notifyUpdate() {
        
        guard let theme = self.theme else { return }
        
        // remove metadata key if empty
        if theme.metadata?.isEmpty ?? false {
            theme.metadata = nil
        }
        
        self.delegate?.didUpdate(theme: theme)
    }
    
}


extension Theme {
    
    static let didChangeNotification = Notification.Name("ThemeDidChangeNotification")
    
    
    override func setValue(_ value: Any?, forKeyPath keyPath: String) {
        
        super.setValue(value, forKeyPath: keyPath)
        
        NotificationCenter.default.post(name: Theme.didChangeNotification, object: self)
    }
    
}
