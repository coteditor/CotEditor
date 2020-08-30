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

final class StatusBarController: NSViewController {
    
    // MARK: Public Properties
    
    weak var document: Document? {
        
        didSet {
            if let document = document, self.isViewShown {
                self.setup(for: document)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private var documentObservers: Set<AnyCancellable> = []
    private var encodingListObserver: AnyCancellable?
    private var defaultsObservers: [AnyCancellable] = []
    
    @objc private dynamic var editorStatus: NSAttributedString?
    @objc private dynamic var fileSize: NSNumber?
    
    @IBOutlet private weak var encodingPopUpButton: NSPopUpButton?
    @IBOutlet private weak var lineEndingPopUpButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if ProcessInfo().operatingSystemVersion.majorVersion < 11 {
            (self.view as? NSVisualEffectView)?.material = .windowBackground
        }
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("status bar".localized)
    }
    
    
    /// request analyzer to update editor info
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // observe popup menu line-up change
        self.buildEncodingPopupButton()
        self.encodingListObserver = EncodingManager.shared.didUpdateSettingList
            .sink { [weak self] _ in self?.buildEncodingPopupButton() }
        
        // observe change in defaults
        let editorDefaultKeys: [DefaultKey<Bool>] = [
            .showStatusBarLines,
            .showStatusBarChars,
            .showStatusBarWords,
            .showStatusBarLocation,
            .showStatusBarLine,
            .showStatusBarColumn,
        ]
        self.defaultsObservers = editorDefaultKeys
            .map { UserDefaults.standard.publisher(key: $0).sink { [weak self] _ in self?.updateEditorStatus() } }
        
        guard let document = self.document else { return assertionFailure() }
        
        self.setup(for: document)
    }
    
    
    /// request analyzer to stop updating editor info
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.encodingListObserver = nil
        self.defaultsObservers.removeAll()
        
        self.document?.analyzer.shouldUpdateStatusEditorInfo = false
        
        self.documentObservers.removeAll()
    }
    
    
    
    // MARK: Private Methods
    
    /// Update UI and observaion for the given document.
    private func setup(for document: Document) {
        
        document.analyzer.shouldUpdateStatusEditorInfo = true
        document.analyzer.invalidateEditorInfo()
        
        self.invalidateEncodingSelection()
        self.invalidateLineEndingSelection(to: document.lineEnding)
        
        // observe editor info update
        document.analyzer.publisher(for: \.info.editor)
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateEditorStatus() }
            .store(in: &self.documentObservers)
        document.analyzer.publisher(for: \.info.file.fileSize)
            .removeDuplicates()
            .sink { [weak self] in self?.fileSize = $0 }
            .store(in: &self.documentObservers)
        
        // observe document status change
        document.didChangeEncoding
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.invalidateEncodingSelection() }
            .store(in: &self.documentObservers)
        document.didChangeLineEnding
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.invalidateLineEndingSelection(to: $0) }
            .store(in: &self.documentObservers)
    }
    
    
    /// update left side text
    private func updateEditorStatus() {
        
        assert(Thread.isMainThread)
        
        guard let info = self.document?.analyzer.info.editor else { return }
        
        let defaults = UserDefaults.standard
        var status: [NSAttributedString] = []
        
        if defaults[.showStatusBarLines] {
            status.append(.formatted(label: "Lines") + .formatted(state: info.lines))
        }
        if defaults[.showStatusBarChars] {
            status.append(.formatted(label: "Characters") + .formatted(state: info.chars))
        }
        if defaults[.showStatusBarWords] {
            status.append(.formatted(label: "Words") + .formatted(state: info.words))
        }
        if defaults[.showStatusBarLocation] {
            status.append(.formatted(label: "Location") + .formatted(state: info.location))
        }
        if defaults[.showStatusBarLine] {
            status.append(.formatted(label: "Line") + .formatted(state: info.line))
        }
        if defaults[.showStatusBarColumn] {
            status.append(.formatted(label: "Column") + .formatted(state: info.column))
        }
        
        let attrStatus = status.joined(separator: .init(string: "   ")).mutable
        
        // truncate tail
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.lineBreakMode = .byTruncatingTail
        attrStatus.addAttribute(.paragraphStyle, value: paragraphStyle, range: attrStatus.range)
        
        self.editorStatus = attrStatus
    }
    
    
    /// build encoding popup item
    private func buildEncodingPopupButton() {
        
        guard let popUpButton = self.encodingPopUpButton else { return }
        
        EncodingManager.shared.updateChangeEncodingMenu(popUpButton.menu!)
        
        popUpButton.insertItem(withTitle: "File Encoding".localized, at: 0)
        popUpButton.item(at: 0)?.isEnabled = false
        
        self.invalidateEncodingSelection()
    }
    
    
    /// select item in the encoding popup menu
    private func invalidateLineEndingSelection(to lineEnding: LineEnding) {
        
        self.lineEndingPopUpButton?.selectItem(withTag: lineEnding.index)
    }
    
    
    /// select item in the line ending menu
    private func invalidateEncodingSelection() {
        
        guard let fileEncoding = self.document?.fileEncoding else { return }
        
        self.encodingPopUpButton?.selectItem(withTag: fileEncoding.tag)
    }
    
}



// MARK: -

private extension NSAttributedString {
    
    /// Formatted state for status bar.
    static func formatted(state: String?) -> Self {
        
        if let state = state {
            return Self(string: state)
        } else {
            return Self(string: "-", attributes: [.foregroundColor: NSColor.disabledControlTextColor])
        }
    }
    
    
    /// Formatted label for status bar.
    static func formatted(label: String) -> Self {
        
        return Self(string: (label + ": ").localized, attributes: [.foregroundColor: NSColor.secondaryLabelColor])
    }
    
}
