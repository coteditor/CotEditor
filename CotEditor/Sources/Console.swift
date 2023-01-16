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
    
    private(set) lazy var panelController = ConsolePanelController()
    
    
    
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
    
    // MARK: Lifecycle
    
    convenience init() {
        
        let viewController = ConsoleViewController()
        let panel = NSPanel(contentViewController: viewController)
        panel.styleMask = [.closable, .resizable, .titled, .fullSizeContentView, .utilityWindow]
        panel.isFloatingPanel = false
        panel.title = "Console".localized
        panel.setContentSize(NSSize(width: 360, height: 200))
        
        self.init(window: panel)
        
        self.windowFrameAutosaveName = "Console"
        
        let toolbar = NSToolbar()
        toolbar.delegate = self
        toolbar.isVisible = true
        toolbar.displayMode = .iconOnly
        panel.toolbar = toolbar
        panel.toolbarStyle = .unifiedCompact
    }
}



private extension NSToolbarItem.Identifier {
    
    private static let prefix = "com.coteditor.CotEditor.Console.ToolbarItem."
    
    static let clear = Self(Self.prefix + "clear")
}


extension ConsolePanelController: NSToolbarDelegate {
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        [.clear]
    }
    
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        
        [.clear]
    }
    
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
            case .clear:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.isBordered = true
                item.label = "Clear Log".localized
                item.toolTip = "Clear error log".localized
                item.image = NSImage(systemSymbolName: "trash", accessibilityDescription: item.label)
                item.action = #selector(ConsoleViewController.clear)
                return item
                
            default:
                return nil
        }
    }
}



// MARK: -

private final class ConsoleViewController: NSViewController {
    
    // MARK: Private Properties
    
    private weak var textView: NSTextView?
    
    
    // MARK: Lifecycle
    
    override func loadView() {
        
        let scrollView = NSTextView.scrollablePlainDocumentContentTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.isEditable = false
        textView.isIncrementalSearchingEnabled = true
        self.textView = textView
        self.view = scrollView
    }
    
    
    // MARK: Public Methods
    
    /// Append the given log message to the console.
    ///
    /// - Parameter log: The log to append.
    func append(log: Console.Log) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        let lastLocation = textView.string.length
        let attributedString = NSAttributedString(log.attributedString)
        
        textView.textStorage?.append(attributedString)
        NSAccessibility.post(element: textView, notification: .valueChanged)
        
        // scroll to make the message visible
        textView.scrollRangeToVisible(NSRange(location: lastLocation, length: attributedString.length))
    }
    
    
    /// Flush existing log.
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
