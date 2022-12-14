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
//  © 2014-2022 1024jp
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
    
    fileprivate struct Log {
        
        var message: String
        var title: String?
        var date: Date = .now
    }
    
    
    
    // MARK: Public Properties
    
    static let shared = Console()
    
    private(set) lazy var panelController: NSWindowController = NSStoryboard(name: "ConsolePanel").instantiateInitialController()!
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    /// Append given message to the console.
    ///
    /// - Parameters:
    ///   - message: The messege to show.
    ///   - title: The title of the message.
    @MainActor func show(message: String, title: String?) {
        
        let log = Console.Log(message: message, title: title)
        
        self.panelController.showWindow(nil)
        (self.panelController.contentViewController as? ConsoleViewController)?.append(log: log)
    }
}



// MARK: -

final class ConsolePanelController: NSWindowController {
    
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
    
    private let messageFont: NSFont = .monospacedSystemFont(ofSize: ConsoleViewController.fontSize, weight: .regular)
    
    private let messageParagraphStyle: NSParagraphStyle = {
        // indent for message body
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.headIndent = ConsoleViewController.fontSize
        paragraphStyle.firstLineHeadIndent = ConsoleViewController.fontSize
        return paragraphStyle
    }()
    
    @IBOutlet private weak var textView: NSTextView?
    @IBOutlet private weak var textFinder: NSTextFinder?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.textView!.textContainerInset = NSSize(width: 0, height: 4)
    }
    
    
    
    // MARK: Public Methods
    
    /// append given message to the console
    fileprivate func append(log: Console.Log) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let lastLocation = (textView.string as NSString).length
        let date = log.date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateTimeSeparator(.space).time(includingFractionalSeconds: false))
        
        let attrString = NSMutableAttributedString(string: "[" + date + "]")
        
        // append bold title
        if let title = log.title {
            let attrTitle = NSMutableAttributedString(string: " " + title)
            attrTitle.applyFontTraits(.boldFontMask, range: NSRange(1..<attrTitle.length))
            attrString.append(attrTitle)
        }
        
        // append indented message
        let attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: self.messageParagraphStyle,
                                                         .font: self.messageFont]
        let attrMessage = NSAttributedString(string: "\n" + log.message + "\n", attributes: attributes)
        attrString.append(attrMessage)
        
        attrString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: attrString.range)
        
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
