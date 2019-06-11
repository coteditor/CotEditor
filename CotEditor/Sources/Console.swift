//
//  Console.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-03-12.
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
    
    let panelController = NSWindowController.instantiate(storyboard: "ConsolePanel")
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    /// append given message to the console
    func append(log: Log) {
        
        (self.panelController.contentViewController as? ConsoleViewController)?.append(log: log)
    }
    
}




// MARK: -

final class ConsoleWindowController: NSWindowController {
    
    // MARK: Window Controller Methods
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        (self.window as! NSPanel).isFloatingPanel = false
        
        self.windowFrameAutosaveName = "Console"
    }
    
}



final class ConsoleViewController: NSViewController {
    
    // MARK: Private Properties
    
    private static let fontSize: CGFloat = 11
    
    private let messageParagraphStyle: NSParagraphStyle = {
        // indent for message body
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.headIndent = ConsoleViewController.fontSize
        paragraphStyle.firstLineHeadIndent = ConsoleViewController.fontSize
        return paragraphStyle
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    @IBOutlet private var textView: NSTextView?  // NSTextView cannot be weak
    @IBOutlet private weak var textFinder: NSTextFinder?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.textView!.font = .messageFont(ofSize: Self.fontSize)
        self.textView!.textContainerInset = NSSize(width: 0, height: 4)
    }
    
    
    
    // MARK: Public Methods
    
    /// append given message to the console
    func append(log: Console.Log) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let lastLocation = (textView.string as NSString).length
        let date = self.dateFormatter.string(from: log.date)
        let attrString = NSMutableAttributedString(string: "[" + date + "]")
        
        // append bold title
        if let title = log.title {
            let attrTitle = NSMutableAttributedString(string: " " + title)
            attrTitle.applyFontTraits(.boldFontMask, range: NSRange(1..<attrTitle.length))
            attrString.append(attrTitle)
        }
        
        // append indented message
        let attrMessage = NSAttributedString(string: "\n" + log.message + "\n", attributes: [.paragraphStyle: self.messageParagraphStyle])
        attrString.append(attrMessage)
        attrString.addAttributes([.foregroundColor: NSColor.labelColor], range: attrString.range)
        
        textView.textStorage?.append(attrString)
        NSAccessibility.post(element: textView, notification: .valueChanged)
        
        // scroll to make message visible
        textView.scrollRangeToVisible(NSRange(location: lastLocation, length: attrString.length))
    }
    
    
    /// flush console
    @IBAction func clear(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.string = ""
        NSAccessibility.post(element: textView, notification: .valueChanged)
    }
    
}



// MARK: - TextFinder Support

/// Map find actions to NSTextFinder, since find action key bindings are configured for TextFinder.
extension ConsoleViewController {
    
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
