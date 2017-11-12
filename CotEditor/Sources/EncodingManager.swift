/*
 
 EncodingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-24.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

@objc protocol EncodingHolder: class {
    
    func changeEncoding(_ sender: AnyObject?)
}



// MARK: -

private let UTF8Tag = Int(String.Encoding.utf8.rawValue)


final class EncodingManager: NSObject {
    
    // MARK: Public Properties
    
    static let shared = EncodingManager()
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.encodingList.rawValue, context: nil)
    }
    
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.encodingList.rawValue)
    }
    
    
    
    // MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == DefaultKeys.encodingList.rawValue {
            DispatchQueue.main.async { [weak self] in
                NotificationCenter.default.post(name: SettingFileManager.didUpdateSettingListNotification, object: self)
            }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return user's encoding priority list
    var defaultEncodings: [String.Encoding?] {
        
        let encodingNumbers = UserDefaults.standard[.encodingList]
        
        return encodingNumbers.map { encodingNumber in
            let cfEncoding = encodingNumber.uint32Value
            
            if cfEncoding == kCFStringEncodingInvalidId {
                return nil
            }
            
            return String.Encoding(cfEncoding: cfEncoding)
        }
    }
    
    
    /// returns corresponding NSStringEncoding from a encoding name
    class func encoding(name encodingName: String) -> String.Encoding? {
        
        return DefaultSettings.encodings.lazy
            .filter { $0 != kCFStringEncodingInvalidId }  // = separator
            .map { String.Encoding(cfEncoding: $0) }
            .first { encodingName == String.localizedName(of: $0) }
    }
    
    
    /// return copied encoding menu items
    func createEncodingMenuItems() -> [NSMenuItem] {
        
        return self.defaultEncodings.map { encoding in
            guard let encoding = encoding else {
                return NSMenuItem.separator()
            }
            
            let item = NSMenuItem()
            item.title = String.localizedName(of: encoding)
            item.tag = Int(encoding.rawValue)
            
            return item
        }
    }
    
    
    /// set available encoding menu items with action to passed-in menu
    func updateChangeEncodingMenu(_ menu: NSMenu) {
        
        menu.removeAllItems()
        
        for item in self.createEncodingMenuItems() {
            item.action = #selector(EncodingHolder.changeEncoding)
            item.target = nil
            menu.addItem(item)
            
            // add "UTF-8 with BOM" item just after the normal UTF-8
            if item.tag == UTF8Tag {
                let bomItem = NSMenuItem(title: String.localizedNameOfUTF8EncodingWithBOM,
                                         action: #selector(EncodingHolder.changeEncoding),
                                         keyEquivalent: "")
                bomItem.tag = -UTF8Tag  // negative value is sign for "with BOM"
                menu.addItem(bomItem)
            }
        }
    }
    
}
