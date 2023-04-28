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

import AppKit
import Combine

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
    
    /// User file encoding.
    var defaultEncoding: FileEncoding {
        
        get {
            let encoding = String.Encoding(rawValue: UserDefaults.standard[.encodingInNew])
            let availableEncoding = String.availableStringEncodings.contains(encoding) ? encoding : .utf8
            let withBOM = (availableEncoding == .utf8) && UserDefaults.standard[.saveUTF8BOM]
            
            return FileEncoding(encoding: availableEncoding, withUTF8BOM: withBOM)
        }
        
        set {
            UserDefaults.standard[.encodingInNew] = newValue.encoding.rawValue
            UserDefaults.standard[.saveUTF8BOM] = newValue.withUTF8BOM
        }
    }
    
    
    /// Return corresponding String.Encoding from an encoding name.
    ///
    /// - Parameter encodingName: The name of the encoding to find.
    /// - Returns: A string encoding or nil.
    func encoding(name encodingName: String) -> String.Encoding? {
        
        self.encodings
            .compactMap { $0 }
            .first { encodingName == String.localizedName(of: $0) }
    }
    
    
    /// Return corresponding String.Encoding from an IANA charset name.
    ///
    /// - Parameter encodingName: The IANA charset name of the encoding to find.
    /// - Returns: A string encoding or nil.
    func encoding(ianaCharSetName: String) -> String.Encoding? {
        
        self.encodings.lazy
            .compactMap { $0 }
            .first { $0.ianaCharSetName?.caseInsensitiveCompare(ianaCharSetName) == .orderedSame }
    }
    
    
    /// Set available encoding menu items with action `changeEncoding(_:)` to the passed-in menu.
    ///
    /// - Parameter menu: The menu to update its items.
    func updateChangeEncodingMenu(_ menu: NSMenu) {
        
        var fileEncodings = self.encodings
            .map { $0.flatMap { FileEncoding(encoding: $0) } }
        
        // add "UTF-8 with BOM" item just after the normal UTF-8
        if let index = fileEncodings.firstIndex(where: { $0?.encoding == .utf8 }) {
            fileEncodings.insert(FileEncoding(encoding: .utf8, withUTF8BOM: true),
                                 at: index + 1)
        }
        
        let action = #selector((any EncodingHolder).changeEncoding)
        
        menu.items.removeAll { $0.action == action }
        menu.items += fileEncodings.map { encoding in
            guard let encoding else { return .separator() }
            
            let item = NSMenuItem(title: encoding.localizedName, action: action, keyEquivalent: "")
            item.tag = encoding.tag
            
            return item
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Convert invalid encoding values (-1) to `kCFStringEncodingInvalidId`.
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
