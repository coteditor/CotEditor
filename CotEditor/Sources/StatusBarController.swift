//
//  StatusBarController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-07-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

@MainActor final class StatusBarController: NSViewController {
    
    // MARK: Public Properties
    
    var document: Document {
        
        didSet {
            if self.isViewShown {
                self.observeDocument()
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private var documentObservers: Set<AnyCancellable> = []
    private var encodingListObserver: AnyCancellable?
    private var defaultsObserver: AnyCancellable?
    
    @objc private dynamic var editorStatus: NSAttributedString?
    @objc private dynamic var fileSize: String?
    
    @IBOutlet private weak var encodingPopUpButton: NSPopUpButton?
    @IBOutlet private weak var lineEndingPopUpButton: NSPopUpButton?
    
    
    
    // MARK: Lifecycle
    
    init?(document: Document, coder: NSCoder) {
        
        self.document = document
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // build line endings pop-up
        self.buildLineEndingPopUpButton()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(String(localized: "Status Bar"))
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // observe popup menu line-up change
        self.encodingListObserver = EncodingManager.shared.$encodings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.buildEncodingPopUpButton() }
        
        // observe changes in defaults
        let editorDefaultKeys: [DefaultKey<Bool>] = [
            .showStatusBarLines,
            .showStatusBarChars,
            .showStatusBarWords,
            .showStatusBarLocation,
            .showStatusBarLine,
            .showStatusBarColumn,
        ]
        let publishers = editorDefaultKeys.map { UserDefaults.standard.publisher(for: $0) }
        self.defaultsObserver = Publishers.MergeMany(publishers)
            .map { _ in UserDefaults.standard.statusBarEditorInfo }
            .sink { [weak self] in
                guard let document = self?.document else { return }
                document.analyzer.statusBarRequirements = $0
                self?.editorStatus = self?.statusAttributedString(result: document.analyzer.result, types: $0)
            }
        
        self.observeDocument()
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.encodingListObserver = nil
        self.defaultsObserver = nil
        
        self.document.analyzer.statusBarRequirements = []
        self.documentObservers.removeAll()
    }
    
    
    
    // MARK: Private Methods
    
    /// Synchronizes UI with related document values.
    private func observeDocument() {
        
        self.document.analyzer.statusBarRequirements = UserDefaults.standard.statusBarEditorInfo
        self.document.analyzer.invalidate()
        
        self.documentObservers = [
            // observe editor info update
            self.document.analyzer.$result
                .removeDuplicates()
                .map { [weak self] in self?.statusAttributedString(result: $0, types: UserDefaults.standard.statusBarEditorInfo) }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.editorStatus = $0 },
            
            // observe file size
            self.document.$fileAttributes
                .map { $0?.size }
                .removeDuplicates()
                .map { $0?.formatted(.byteCount(style: .file, spellsOutZero: false)) }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.fileSize = $0 },
            
            // observe document status change
            self.document.$fileEncoding
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.encodingPopUpButton?.selectItem(withTag: $0.tag) },
            self.document.$lineEnding
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.lineEndingPopUpButton?.selectItem(withTag: $0.index) },
        ]
    }
    
    
    /// Builds the left side text.
    ///
    /// - Parameters:
    ///   - result: The editor count result.
    ///   - types: The editor info types to display.
    /// - Returns: An attributed string to display.
    @MainActor private func statusAttributedString(result: EditorCountResult, types: EditorInfoTypes) -> NSAttributedString {
        
        var status: [NSAttributedString] = []
        
        if types.contains(.lines) {
            let label = String(localized: "Lines: ")
            status.append(.formatted(label: label) + .formatted(state: result.lines.formatted))
        }
        if types.contains(.characters) {
            let label = String(localized: "Characters: ")
            status.append(.formatted(label: label) + .formatted(state: result.characters.formatted))
        }
        if types.contains(.words) {
            let label = String(localized: "Words: ")
            status.append(.formatted(label: label) + .formatted(state: result.words.formatted))
        }
        if types.contains(.location) {
            let label = String(localized: "Location: ")
            status.append(.formatted(label: label) + .formatted(state: result.location?.formatted()))
        }
        if types.contains(.line) {
            let label = String(localized: "Line: ")
            status.append(.formatted(label: label) + .formatted(state: result.line?.formatted()))
        }
        if types.contains(.column) {
            let label = String(localized: "Column: ")
            status.append(.formatted(label: label) + .formatted(state: result.column?.formatted()))
        }
        
        let attrStatus = status.joined(separator: "   ").mutable
        
        // truncate tail
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        attrStatus.addAttribute(.paragraphStyle, value: paragraphStyle, range: attrStatus.range)
        
        return attrStatus
    }
    
    
    /// Builds the encoding pop-up button.
    @MainActor private func buildEncodingPopUpButton() {
        
        guard
            let popUpButton = self.encodingPopUpButton,
            let menu = popUpButton.menu
        else { return assertionFailure() }
        
        EncodingManager.shared.updateChangeEncodingMenu(menu)
        
        popUpButton.selectItem(withTag: self.document.fileEncoding.tag)
    }
    
    
    /// Builds the line ending pop-up menu.
    @MainActor private func buildLineEndingPopUpButton() {
        
        guard let menu = self.lineEndingPopUpButton?.menu else { return assertionFailure() }
        
        menu.items += LineEnding.allCases.map { lineEnding in
            let item = NSMenuItem()
            item.title = lineEnding.name
            item.tag = lineEnding.index
            item.toolTip = lineEnding.longName
            item.action = #selector(Document.changeLineEnding(_:))
            item.isHidden = !lineEnding.isBasic
            item.keyEquivalentModifierMask = lineEnding.isBasic ? [] : [.option]
            
            return item
        }
    }
}



// MARK: -

private extension UserDefaults {
    
    /// The info types needed to be calculated.
    var statusBarEditorInfo: EditorInfoTypes {
        
        EditorInfoTypes()
            .union(self[.showStatusBarChars] ? .characters : [])
            .union(self[.showStatusBarLines] ? .lines : [])
            .union(self[.showStatusBarWords] ? .words : [])
            .union(self[.showStatusBarLocation] ? .location : [])
            .union(self[.showStatusBarLine] ? .line : [])
            .union(self[.showStatusBarColumn] ? .column : [])
    }
}


private extension NSAttributedString {
    
    /// Returns formatted state for status bar.
    ///
    /// - Parameter state: The content string.
    /// - Returns: An attributed string.
    static func formatted(state: String?) -> Self {
        
        if let state {
            Self(string: state)
        } else {
            Self(string: "-", attributes: [.foregroundColor: NSColor.disabledControlTextColor])
        }
    }
    
    
    /// Returns formatted label for status bar.
    ///
    /// - Parameter label: Localized label.
    /// - Returns: An attributed string.
    static func formatted(label: String) -> Self {
        
        Self(string: label, attributes: [.foregroundColor: NSColor.secondaryLabelColor])
    }
}
