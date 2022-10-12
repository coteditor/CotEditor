//
//  DocumentInspectorViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

final class FileInfo: NSObject {
    
    @objc dynamic var creationDate: Date?
    @objc dynamic var modificationDate: Date?
    @objc dynamic var fileSize: NSNumber?
    @objc dynamic var url: URL?
    @objc dynamic var owner: String?
    @objc dynamic var permission: NSNumber?
}


final class EditorInfo: NSObject {
    
    @objc dynamic var lines: String?
    @objc dynamic var chars: String?
    @objc dynamic var words: String?
    
    @objc dynamic var location: String?  // cursor location from the beginning of document
    @objc dynamic var line: String?      // current line
    @objc dynamic var column: String?    // cursor location from the beginning of line
    
    @objc dynamic var unicode: String?   // Unicode of selected single character (or surrogate-pair)
}


final class DocumentInspectorViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var documentObservers: Set<AnyCancellable> = []
    private var document: Document?  { self.representedObject as? Document }
    private var analyzer: DocumentAnalyzer?  { self.document?.analyzer }
    
    @objc private(set) dynamic var fileInfo: FileInfo = .init()
    @objc private(set) dynamic var encoding: String = "–"
    @objc private(set) dynamic var lineEndings: String = "–"
    @objc private(set) dynamic var editorInfo: EditorInfo = .init()
    
    @IBOutlet private var dateFormatter: DateFormatter?
    @IBOutlet private var byteCountFormatter: ByteCountFormatter?
    @IBOutlet private var filePermissionsFormatter: FilePermissionsFormatter?
    @IBOutlet private var tokenFormatter: TokenFormatter?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityLabel("Document Insepector".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard let document = self.document else { return assertionFailure() }
        
        self.subscribe(document)
        self.analyzer?.updatesAll = true
        self.analyzer?.invalidate()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.documentObservers.removeAll()
        self.analyzer?.updatesAll = false
    }
    
    
    override var representedObject: Any? {
        
        willSet {
            self.analyzer?.updatesAll = false
            self.documentObservers.removeAll()
        }
        
        didSet {
            assert(representedObject == nil || representedObject is Document,
                   "representedObject of \(self.className) must be an instance of \(Document.className())")
            
            self.analyzer?.updatesAll = self.isViewShown
            
            if self.isViewShown, let document = self.document {
                self.subscribe(document)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Synchronize UI with related document values.
    ///
    /// - Parameter document: The document to observe.
    private func subscribe(_ document: Document) {
        
        document.publisher(for: \.fileURL, options: .initial)
            .receive(on: DispatchQueue.main)
            .assign(to: \.url, on: self.fileInfo)
            .store(in: &self.documentObservers)
        
        document.$fileAttributes
            .receive(on: DispatchQueue.main)
            .sink { [info = self.fileInfo] (attributes) in
                info.creationDate = attributes?[.creationDate] as? Date
                info.modificationDate = attributes?[.modificationDate] as? Date
                info.fileSize = attributes?[.size] as? NSNumber
                info.owner = attributes?[.ownerAccountName] as? String
                info.permission = attributes?[.posixPermissions] as? NSNumber
            }
            .store(in: &self.documentObservers)
        
        document.$fileEncoding
            .map(\.localizedName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.encoding = $0 }
            .store(in: &self.documentObservers)
        
        document.$lineEnding
            .map(\.name)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.lineEndings = $0 }
            .store(in: &self.documentObservers)
        
        document.analyzer.$result
            .receive(on: DispatchQueue.main)
            .sink { [info = self.editorInfo] (result) in
                info.chars = result.characters.formatted
                info.lines = result.lines.formatted
                info.words = result.words.formatted
                info.location = result.location?.formatted()
                info.line = result.line?.formatted()
                info.column = result.column?.formatted()
                info.unicode = result.unicode
            }
            .store(in: &self.documentObservers)
    }
    
}
