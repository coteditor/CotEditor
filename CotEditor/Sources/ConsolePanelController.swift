//
//  ConsolePanelController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-03-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

// Constants
private let consoleFontSize: CGFloat = 11.0

final class Console {
    
    struct Log {
        
        var message: String
        var title: String?
        var date: Date
        
        
        init(message: String, title: String?) {
            
            self.message = message
            self.title = title
            self.date = Date()
        }
        
    }
    
    
    
    // MARK: Public Properties
    
    static let shared = Console()
    
    private(set) var logs: [Log] = []
    
    
    // MARK: Private Properties
    
    private let panelController = ConsolePanelController()
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    func showPanel() {
        
        self.panelController.showWindow(self)
    }
    
    
    /// append given message to the console
    func append(log: Log) {
        
        self.logs.append(log)
        self.panelController.append(message: log.message, title: log.title)
    }
    
}



private final class ConsolePanelController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = ConsolePanelController()
    
    
    // MARK: Private Properties
    
    private let fontSize: CGFloat = consoleFontSize
    
    private let messageParagraphStyle: NSParagraphStyle = {
        // indent for message body
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.headIndent = consoleFontSize
        paragraphStyle.firstLineHeadIndent = consoleFontSize
        return paragraphStyle
    }()
    
    private let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return formatter
    }()
    
    @IBOutlet private var textView: NSTextView?  // NSTextView cannot be weak
    @IBOutlet private weak var textFinder: NSTextFinder?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var windowNibName: NSNib.Name? {
        
        return NSNib.Name("ConsolePanel")
    }
    
    
    
    // MARK: WindowController Methods
    
    /// setup UI
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        (self.window as? NSPanel)?.isFloatingPanel = false
    
        self.textView?.font = NSFont.messageFont(ofSize: self.fontSize)
        self.textView?.textContainerInset = NSSize(width: 0.0, height: 4.0)
    }
    
    
    
    // MARK: Public Methods
    
    /// append given message to the console
    func append(message: String, title: String?) {
        
        let lastLocation = self.textView?.textStorage?.length ?? 0
        let date = self.dateFormatter.string(from: Date())
        let attrString = NSMutableAttributedString(string: "[" + date + "]")
        
        // append bold title
        if let title = title {
            let attrTitle = NSMutableAttributedString(string: " " + title)
            attrTitle.applyFontTraits(.boldFontMask, range: NSRange(location: 1, length: title.utf16.count))
            attrString.append(attrTitle)
        }
        
        // append indented message
        let attrMessage = NSAttributedString(string: "\n" + message + "\n", attributes: [.paragraphStyle: self.messageParagraphStyle])
        attrString.append(attrMessage)
        attrString.addAttributes([.foregroundColor: NSColor.labelColor], range: attrString.string.nsRange)
        
        self.textView?.textStorage?.append(attrString)
        
        // scroll to make message visible
        self.textView?.scrollRangeToVisible(NSRange(location: lastLocation, length: attrString.length))
    }
    
    
    /// flush console
    @IBAction func cleanConsole(_ sender: Any?) {
        
        guard let textView = self.textView else { return }
        
        textView.string = ""
        NSAccessibility.post(element: textView, notification: .valueChanged)
    }
    
}



// MARK: - TextFinder Support

/// Map find actions to NSTextFinder, since find action key bindings are configured for TextFinder.
extension ConsolePanelController {
    
    /// bridge find action to NSTextFinder
    @IBAction func showFindPanel(_ sender: Any?) {
        
        self.textFinder?.performAction(.showFindInterface)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func findNext(_ sender: Any?) {
        
        self.textFinder?.performAction(.nextMatch)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func findPrevious(_ sender: Any?) {
        
        self.textFinder?.performAction(.previousMatch)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func useSelectionForFind(_ sender: Any?) {
        
        self.textFinder?.performAction(.setSearchString)
    }
    
}
