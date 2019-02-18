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
//  © 2014-2019 1024jp
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

import Cocoa

final class StatusBarController: NSViewController {
    
    // MARK: Private Properties
    
    private var defaultsObservers: [UserDefaultsObservation] = []
    private let byteCountFormatter = ByteCountFormatter()
    
    @objc private dynamic var editorStatus: NSAttributedString?
    @objc private dynamic var documentStatus: NSAttributedString?
    @objc private dynamic var showsReadOnly = false
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.defaultsObservers.forEach { $0.invalidate() }
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.byteCountFormatter.isAdaptive = false
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("status bar".localized)
        
        // observe change in defaults
        let editorDefaultKeys: [DefaultKeys] = [
            .showStatusBarLines,
            .showStatusBarChars,
            .showStatusBarWords,
            .showStatusBarLocation,
            .showStatusBarLine,
            .showStatusBarColumn,
            ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: editorDefaultKeys) { [unowned self] (_, _) in
            self.updateEditorStatus()
        }
        let documentDefaultKeys: [DefaultKeys] = [
            .showStatusBarEncoding,
            .showStatusBarLineEndings,
            .showStatusBarFileSize,
            ]
        self.defaultsObservers += UserDefaults.standard.observe(keys: documentDefaultKeys) { [unowned self] (_, _) in
            self.updateDocumentStatus()
        }
    }
    
    
    /// request analyzer to update editor info
    override func viewDidAppear() {
        
        super.viewDidAppear()
        
        self.documentAnalyzer?.needsUpdateStatusEditorInfo = true
    }
    
    
    /// request analyzer to stop updating editor info
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.documentAnalyzer?.needsUpdateStatusEditorInfo = false
    }
    
    
    
    // MARK: Public Methods
    
    weak var documentAnalyzer: DocumentAnalyzer? {
        
        willSet {
            guard let analyzer = documentAnalyzer else { return }
            
            analyzer.needsUpdateStatusEditorInfo = false
            
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: analyzer)
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateFileInfoNotification, object: analyzer)
            NotificationCenter.default.removeObserver(self, name: DocumentAnalyzer.didUpdateModeInfoNotification, object: analyzer)
        }
        
        didSet {
            guard let analyzer = documentAnalyzer else { return }
            
            analyzer.needsUpdateStatusEditorInfo = !self.view.isHiddenOrHasHiddenAncestor
            
            NotificationCenter.default.addObserver(self, selector: #selector(updateEditorStatus), name: DocumentAnalyzer.didUpdateEditorInfoNotification, object: analyzer)
            NotificationCenter.default.addObserver(self, selector: #selector(updateDocumentStatus), name: DocumentAnalyzer.didUpdateFileInfoNotification, object: analyzer)
            NotificationCenter.default.addObserver(self, selector: #selector(updateDocumentStatus), name: DocumentAnalyzer.didUpdateModeInfoNotification, object: analyzer)
            
            self.updateEditorStatus()
            self.updateDocumentStatus()
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// update left side text
    @objc private func updateEditorStatus() {
        
        assert(Thread.isMainThread)
        
        guard !self.view.isHiddenOrHasHiddenAncestor else { return }
        guard let info = self.documentAnalyzer?.info else { return }
        
        let appearance = self.view.effectiveAppearance
        let defaults = UserDefaults.standard
        let status = NSMutableAttributedString()
        
        if defaults[.showStatusBarLines] {
            status.appendFormattedState(value: info.lines, label: "Lines", appearance: appearance)
        }
        if defaults[.showStatusBarChars] {
            status.appendFormattedState(value: info.chars, label: "Characters", appearance: appearance)
        }
        if defaults[.showStatusBarWords] {
            status.appendFormattedState(value: info.words, label: "Words", appearance: appearance)
        }
        if defaults[.showStatusBarLocation] {
            status.appendFormattedState(value: info.location, label: "Location", appearance: appearance)
        }
        if defaults[.showStatusBarLine] {
            status.appendFormattedState(value: info.line, label: "Line", appearance: appearance)
        }
        if defaults[.showStatusBarColumn] {
            status.appendFormattedState(value: info.column, label: "Column", appearance: appearance)
        }
        
        // truncate tail
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        status.addAttribute(.paragraphStyle, value: paragraphStyle, range: status.string.nsRange)
        
        self.editorStatus = status
    }
    
    
    /// update right side text and readonly icon state
    @objc private func updateDocumentStatus() {
        
        assert(Thread.isMainThread)
        
        guard !self.view.isHiddenOrHasHiddenAncestor else { return }
        guard let info = self.documentAnalyzer?.info else { return }
        
        let defaults = UserDefaults.standard
        let status = NSMutableAttributedString()
        
        if defaults[.showStatusBarEncoding] {
            status.appendFormattedState(value: info.encoding, label: nil)
        }
        if defaults[.showStatusBarLineEndings] {
            status.appendFormattedState(value: info.lineEndings, label: nil)
        }
        if defaults[.showStatusBarFileSize] {
            let fileSize = self.byteCountFormatter.string(for: info.fileSize)
            status.appendFormattedState(value: fileSize, label: nil)
        }
        
        self.documentStatus = status
        self.showsReadOnly = info.isReadOnly
    }
    
}



// MARK: -

private extension NSMutableAttributedString {
    
    /// append formatted state
    func appendFormattedState(value: String?, label: String?, appearance: NSAppearance = .current) {
        
        if !self.string.isEmpty {
            self.append(NSAttributedString(string: "   "))
        }
        
        if let label = label {
            let labelColor: NSColor = appearance.isDark
                ? NSColor.secondaryLabelColor
                : NSColor.labelColor.withAlphaComponent(0.6)
            let attrLabel = NSAttributedString(string: (label + ": ").localized,
                                               attributes: [.foregroundColor: labelColor])
            self.append(attrLabel)
        }
        
        let attrValue: NSAttributedString = {
            if let value = value {
                return NSAttributedString(string: value)
            } else {
                return NSAttributedString(string: "-",
                                          attributes: [.foregroundColor: NSColor.disabledControlTextColor])
            }
        }()
        
        self.append(attrValue)
    }
    
}
