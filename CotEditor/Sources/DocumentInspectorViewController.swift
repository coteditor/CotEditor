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
//  © 2016-2023 1024jp
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

final class FileInfo: NSObject {
    
    @objc dynamic var creationDate: String?
    @objc dynamic var modificationDate: String?
    @objc dynamic var fileSize: String?
    @objc dynamic var path: String?
    @objc dynamic var owner: String?
    @objc dynamic var permission: String?
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


final class DocumentInspectorViewController: NSViewController, DocumentOwner {
    
    // MARK: Public Properties
    
    var document: Document { didSet { self.updateDocument() } }
    
    
    // MARK: Private Properties
    
    private var analyzer: DocumentAnalyzer  { self.document.analyzer }
    
    private var documentObservers: Set<AnyCancellable> = []
    
    @objc private(set) dynamic var fileInfo: FileInfo = .init()
    @objc private(set) dynamic var encoding: String = "–"
    @objc private(set) dynamic var lineEndings: String = "–"
    @objc private(set) dynamic var editorInfo: EditorInfo = .init()
    
    @IBOutlet private var tokenFormatter: TokenFormatter?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init?(document: Document, coder: NSCoder) {
        
        self.document = document
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityLabel(String(localized: "Document Inspector"))
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.observeDocument()
        self.analyzer.updatesAll = true
        self.analyzer.invalidate()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.documentObservers.removeAll()
        self.analyzer.updatesAll = false
    }
    
    
    
    // MARK: Private Methods
    
    private func updateDocument() {
        
        self.analyzer.updatesAll = self.isViewShown
        
        if self.isViewShown {
            self.observeDocument()
        }
    }
    
    
    /// Synchronizes UI with related document values.
    private func observeDocument() {
        
        self.documentObservers = [
            self.document.publisher(for: \.fileURL, options: .initial)
                .map { $0?.path }
                .receive(on: DispatchQueue.main)
                .assign(to: \.path, on: self.fileInfo),
            
            self.document.$fileAttributes
                .receive(on: DispatchQueue.main)
                .sink { [weak self] attributes in
                    guard let info = self?.fileInfo else { return }
                    
                    let dateFormat = Date.FormatStyle(date: .abbreviated, time: .shortened)
                    
                    info.creationDate = (attributes?[.creationDate] as? Date)?.formatted(dateFormat)
                    info.modificationDate = (attributes?[.modificationDate] as? Date)?.formatted(dateFormat)
                    info.fileSize = (attributes?[.size] as? UInt64)?.formatted(.byteCount(style: .file, includesActualByteCount: true))
                    info.owner = attributes?[.ownerAccountName] as? String
                    info.permission = (attributes?[.posixPermissions] as? UInt16)?.formatted(.filePermissions)
                },
            
            self.document.$fileEncoding
                .map(\.localizedName)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.encoding = $0 },
            
            self.document.$lineEnding
                .map(\.name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.lineEndings = $0 },
            
            self.document.analyzer.$result
                .receive(on: DispatchQueue.main)
                .sink { [info = self.editorInfo] result in
                    info.chars = result.characters.formatted
                    info.lines = result.lines.formatted
                    info.words = result.words.formatted
                    info.location = result.location?.formatted()
                    info.line = result.line?.formatted()
                    info.column = result.column?.formatted()
                    info.unicode = result.unicode
                },
        ]
    }
}
