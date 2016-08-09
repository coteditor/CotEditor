/*
 
 EncodingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-24.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension Notification.Name {
    
    /// Posted when current encoding list menu items is ready to build
    static let EncodingListDidUpdate = Notification.Name("EncodingListDidUpdate")
}


@objc protocol EncodingHolder: class {
    
    func changeEncoding(_ sender: AnyObject?)
}



// MARK:

final class EncodingManager: NSObject {
    
    // MARK: Public Properties
    
    static let shared = EncodingManager()

    
    // MARK: Private Properties
    
    private let UTF8Tag = Int(String.Encoding.utf8.rawValue)
    private var _menuItems = [NSMenuItem]()
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        self.buildEncodingMenuItems()
        
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.encodingList.rawValue, context: nil)
    }
    
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.encodingList.rawValue)
    }
    
    
    
    // MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        if keyPath == DefaultKeys.encodingList.rawValue {
            self.buildEncodingMenuItems()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return user's encoding priority list
    var defaultEncodings: [String.Encoding?] {
        
        let encodingNumbers = Defaults[.encodingList]
        
        return encodingNumbers.map { encodingNumber in
            let cfEncoding = encodingNumber.uint32Value
            
            if cfEncoding == kCFStringEncodingInvalidId {
                return nil
            }
            
            return String.Encoding(cfEncoding: cfEncoding)
        }
    }
    
    
    /// returns corresponding NSStringEncoding from a encoding name
    class func encoding(fromName encodingName: String) -> String.Encoding? {
        
        for cfEncoding in DefaultEncodings {
            guard cfEncoding != kCFStringEncodingInvalidId else { continue }  // = separator
            
            let encoding = String.Encoding(cfEncoding: cfEncoding)
            if encodingName == String.localizedName(of: encoding) {
                return encoding
            }
        }
        
        return nil
    }
    
    
    /// return copied encoding menu items
    var encodingMenuItems: [NSMenuItem] {
        
        return self._menuItems.map { $0.copy() as! NSMenuItem }
    }
    
    
    /// set available encoding menu items with action to passed-in menu
    func updateChangeEncodingMenu(_ menu: NSMenu) {
        
        menu.removeAllItems()
        
        for item in self.encodingMenuItems {
            item.action = #selector(EncodingHolder.changeEncoding(_:))
            item.target = nil
            menu.addItem(item)
            
            // add "UTF-8 with BOM" item just after the normal UTF-8
            if item.tag == UTF8Tag {
                let bomItem = NSMenuItem(title: String.localizedNameOfUTF8EncodingWithBOM,
                                         action: #selector(EncodingHolder.changeEncoding(_:)),
                                         keyEquivalent: "")
                bomItem.tag = -UTF8Tag  // negative value is sign for "with BOM"
                menu.addItem(bomItem)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// build encoding menu items
    private func buildEncodingMenuItems() {
        
        self._menuItems = self.defaultEncodings.map { encoding in
            guard let encoding = encoding else {
                return NSMenuItem.separator()
            }
            
            let item = NSMenuItem()
            item.title = String.localizedName(of: encoding)
            item.tag = Int(encoding.rawValue)
            
            return item
        }
        
        // notify that new encoding menu items was created
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .EncodingListDidUpdate, object: self)
        }
    }
    
}
