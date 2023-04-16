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
//  © 2014-2023 1024jp
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

final class EncodingManager {
    
    // MARK: Public Properties
    
    static let shared = EncodingManager()
    
    @Published private(set) var encodings: [String.Encoding?] = []
    
    
    // MARK: Private Properties
    
    private var encodingListObserver: AnyCancellable?
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        // -> UserDefaults.standard[.encodingList] can be empty if the user's list contains negative values.
        //    It seems to be possible if the setting was made a long time ago. (2018-01 CotEditor 3.3.0)
        if UserDefaults.standard[.encodingList].isEmpty {
            self.sanitizeEncodingListSetting()
        }
        
        self.encodingListObserver = UserDefaults.standard.publisher(for: .encodingList, initial: true)
            .map { $0.map { $0 != kCFStringEncodingInvalidId ? String.Encoding(cfEncoding: $0) : nil } }
            .sink { [weak self] in self?.encodings = $0 }
    }
    
    
    
    // MARK: Public Methods
    
    /// returns corresponding NSStringEncoding from an encoding name
    func encoding(name encodingName: String) -> String.Encoding? {
        
        DefaultSettings.encodings.lazy
            .filter { $0 != kCFStringEncodingInvalidId }  // = separator
            .map { String.Encoding(cfEncoding: $0) }
            .first { encodingName == String.localizedName(of: $0) }
    }
    
    /// returns corresponding NSStringEncoding from an IANA char set name
    func encoding(ianaCharSetName: String) -> String.Encoding? {
        
        DefaultSettings.encodings.lazy
            .filter { $0 != kCFStringEncodingInvalidId }  // = separator
            .map { String.Encoding(cfEncoding: $0) }
            .first { $0.ianaCharSetName?.caseInsensitiveCompare(ianaCharSetName) == .orderedSame }
    }
    
    
    /// return copied encoding menu items
    func createEncodingMenuItems() -> [NSMenuItem] {
        
        self.encodings.map { encoding in
            guard let encoding else { return .separator() }
            
            let item = NSMenuItem()
            item.title = String.localizedName(of: encoding)
            item.tag = Int(encoding.rawValue)
            
            return item
        }
    }
    
    
    /// set available encoding menu items with action to passed-in menu
    func updateChangeEncodingMenu(_ menu: NSMenu) {
        
        menu.items.removeAll { $0.action == #selector((any EncodingHolder).changeEncoding) }
        
        for item in self.createEncodingMenuItems() {
            item.action = #selector((any EncodingHolder).changeEncoding)
            item.target = nil
            menu.addItem(item)
            
            // add "UTF-8 with BOM" item just after the normal UTF-8
            if item.tag == FileEncoding(encoding: .utf8).tag {
                let fileEncoding = FileEncoding(encoding: .utf8, withUTF8BOM: true)
                let bomItem = NSMenuItem(title: fileEncoding.localizedName,
                                         action: #selector((any EncodingHolder).changeEncoding),
                                         keyEquivalent: "")
                bomItem.tag = fileEncoding.tag
                menu.addItem(bomItem)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// convert invalid encoding values (-1) to `kCFStringEncodingInvalidId`
    private func sanitizeEncodingListSetting() {
        
        guard
            let list = UserDefaults.standard.array(forKey: DefaultKeys.encodingList.rawValue) as? [Int],
            !list.isEmpty
        else {
            // just restore to default if failed
            UserDefaults.standard.restore(key: .encodingList)
            return
        }
        
        UserDefaults.standard[.encodingList] = list.map { CFStringEncoding(exactly: $0) ?? kCFStringEncodingInvalidId }
    }
}
