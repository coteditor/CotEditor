//
//  EncodingManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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

import Combine
import Cocoa

@objc protocol EncodingHolder: AnyObject {
    
    func changeEncoding(_ sender: NSMenuItem)
}



// MARK: -

private let UTF8Tag = Int(String.Encoding.utf8.rawValue)


final class EncodingManager: NSObject {
    
    // MARK: Public Properties
    
    static let shared = EncodingManager()
    
    let didUpdateSettingList: PassthroughSubject<Void, Never> = .init()
    
    
    // MARK: Private Properties
    
    private var encodingListObserver: UserDefaultsObservation?
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        // -> UserDefaults.standard[.encodingList] can be empty if the user's list contains negative values.
        //    It seems to be possible if the setting was made a long time ago. (2018-01 CotEditor 3.3.0)
        if UserDefaults.standard[.encodingList].isEmpty {
            self.sanitizeEncodingListSetting()
        }
        
        self.encodingListObserver = UserDefaults.standard.observe(key: .encodingList) { [weak self] _ in
            self?.didUpdateSettingList.send()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return user's encoding priority list
    var defaultEncodings: [String.Encoding?] {
        
        return UserDefaults.standard[.encodingList]
            .map { $0 != kCFStringEncodingInvalidId ? String.Encoding(cfEncoding: $0) : nil }
    }
    
    
    /// returns corresponding NSStringEncoding from a encoding name
    func encoding(name encodingName: String) -> String.Encoding? {
        
        return DefaultSettings.encodings.lazy
            .filter { $0 != kCFStringEncodingInvalidId }  // = separator
            .map { String.Encoding(cfEncoding: $0) }
            .first { encodingName == String.localizedName(of: $0) }
    }
    
    
    /// return copied encoding menu items
    func createEncodingMenuItems() -> [NSMenuItem] {
        
        return self.defaultEncodings.map { encoding in
            guard let encoding = encoding else {
                return .separator()
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
                let bomItem = NSMenuItem(title: String.localizedName(of: .utf8, withUTF8BOM: true),
                                         action: #selector(EncodingHolder.changeEncoding),
                                         keyEquivalent: "")
                bomItem.tag = -UTF8Tag  // negative value is sign for "with BOM"
                menu.addItem(bomItem)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// convert invalid encoding values (-1) to `kCFStringEncodingInvalidId`
    private func sanitizeEncodingListSetting() {
        
        guard
            let list = UserDefaults.standard.array(forKey: DefaultKeys.encodingList.rawValue) as? [Int],
            !list.isEmpty else {
                // just restore to default if failed
                UserDefaults.standard.restore(key: .encodingList)
                return
            }
        
        UserDefaults.standard[.encodingList] = list.map { CFStringEncoding(exactly: $0) ?? kCFStringEncodingInvalidId }
    }
    
}
