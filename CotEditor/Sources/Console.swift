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

import Cocoa

final class Console {
    
    struct Log {
        
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
    ///   - log: The console log to show.
    @MainActor func show(log: Log) {
        
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
        let attributedString = NSAttributedString(log.attributedString)
        
        textView.textStorage?.append(attributedString)
        NSAccessibility.post(element: textView, notification: .valueChanged)
        
        // scroll to make the message visible
        textView.scrollRangeToVisible(NSRange(location: lastLocation, length: attributedString.length))
    }
    
    
    /// flush console
    @IBAction func clear(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.string = ""
        NSAccessibility.post(element: textView, notification: .valueChanged)
    }
}



private extension Console.Log {
    
    private static let fontSize: Double = 11
    
    private static let paragraphStyle: NSParagraphStyle = {
        
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.headIndent = Self.fontSize
        paragraphStyle.firstLineHeadIndent = Self.fontSize
        
        return paragraphStyle
    }()
    
    
    var attributedString: AttributedString {
        
        let dateFormat = Date.ISO8601FormatStyle(timeZone: .current)
            .year()
            .month()
            .day()
            .dateTimeSeparator(.space)
            .time(includingFractionalSeconds: false)
        var string = AttributedString("[\(self.date.formatted(dateFormat))]")
        
        // append bold title
        if let title = self.title {
            var attrTitle = AttributedString(title)
            attrTitle.font = .systemFont(ofSize: 0, weight: .semibold)
            string += " " + attrTitle
        }
        
        // append indented message
        var message = AttributedString(self.message)
        message.font = .monospacedSystemFont(ofSize: Self.fontSize, weight: .regular)
        message.paragraphStyle = Self.paragraphStyle
        string += "\n" + message + "\n"
        
        string.foregroundColor = .labelColor
        
        return string
    }
}
