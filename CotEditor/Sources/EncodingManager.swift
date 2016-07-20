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

@objc protocol EncodingHolder {
    
    func changeEncoding(_ sender: AnyObject?)
}



// MARK:

class EncodingManager: NSObject {
    
    // MARK: Public Properties
    
    static let shared = EncodingManager()
    
    /// Posted when current encoding list menu items is ready to build
    static let ListDidUpdateNotification = Notification.Name("CEEncodingListDidUpdate")

    
    // MARK: Private Properties
    
    private let UTF8Tag = Int(String.Encoding.utf8.rawValue)
    private var _menuItems = [NSMenuItem]()
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
        
        self.buildEncodingMenuItems()
        
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKey.encodingList.rawValue, options: .new, context: nil)
    }
    
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKey.encodingList.rawValue)
    }
    
    
    
    // MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        if keyPath == DefaultKey.encodingList.rawValue {
            self.buildEncodingMenuItems()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return user's encoding priority list
    var defaultEncodings: [String.Encoding?] {
        
        var encodings: [String.Encoding?] = []
        let encodingNumbers = UserDefaults.standard.array(forKey: DefaultKey.encodingList.rawValue) as! [NSNumber]
        
        for encodingNumber in encodingNumbers {
            let cfEncoding = encodingNumber.uint32Value
            
            if cfEncoding == kCFStringEncodingInvalidId {
                encodings.append(nil)
                continue
            }
          
            let encoding = String.Encoding(cfEncoding: cfEncoding)
            
            encodings.append(encoding)
        }
        
        return encodings
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
        
        var items = [NSMenuItem]()
        
        for encoding in self.defaultEncodings {
            guard let encoding = encoding else {
                items.append(NSMenuItem.separator())
                continue
            }
            
            let menuTitle = String.localizedName(of: encoding)
            
            let item = NSMenuItem(title: menuTitle, action: nil, keyEquivalent: "")
            item.tag = Int(encoding.rawValue)
            items.append(item)
        }
        
        self._menuItems = items
        
        // notify that new encoding menu items was created
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: EncodingManager.ListDidUpdateNotification, object: self)
        }
    }
    
}
