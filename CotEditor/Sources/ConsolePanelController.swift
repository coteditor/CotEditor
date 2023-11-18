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

import AppKit

struct Console {
    
    struct Log {
        
        var message: String
        var title: String?
        var date: Date = .now
    }
}



// MARK: -

final class ConsolePanelController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = ConsolePanelController()
    
    
    // MARK: Lifecycle
    
    init() {
        
        let viewController = ConsoleViewController()
        let panel = NSPanel(contentViewController: viewController)
        panel.styleMask = [.closable, .resizable, .titled, .fullSizeContentView, .utilityWindow]
        panel.isFloatingPanel = false
        panel.title = String(localized: "Console")
        panel.setContentSize(NSSize(width: 360, height: 200))
        
        super.init(window: panel)
        
        self.windowFrameAutosaveName = "Console"
        
        let toolbar = NSToolbar()
        toolbar.delegate = self
        toolbar.isVisible = true
        toolbar.displayMode = .iconOnly
        panel.toolbar = toolbar
        panel.toolbarStyle = .unifiedCompact
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// Append given message to the console.
    ///
    /// - Parameters:
    ///   - log: The console log to show.
    func append(log: Console.Log) {
        
        (self.contentViewController as! ConsoleViewController).append(log: log)
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
                item.label = String(localized: "Clear Log")
                item.toolTip = String(localized: "Clear error log")
                item.image = NSImage(systemSymbolName: "trash", accessibilityDescription: item.label)
                item.action = #selector(ConsoleViewController.clearAll)
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
    
    private var fontSize: Double = max(UserDefaults.standard[.consoleFontSize], NSFont.smallSystemFontSize) {
        
        didSet {
            UserDefaults.standard[.consoleFontSize] = fontSize
            self.changeFontSize(fontSize)
        }
    }
    
    
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
        let attributedString = log.attributedString(fontSize: self.fontSize)
        let range = NSRange(location: lastLocation, length: attributedString.length)
        
        textView.textStorage?.append(attributedString)
        NSAccessibility.post(element: textView, notification: .valueChanged)
        
        // scroll to make the message visible
        textView.scrollRangeToVisible(range)
    }
    
    
    // MARK: Actions
    
    /// Flush existing log.
    @IBAction func clearAll(_ sender: Any?) {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        textView.string = ""
        NSAccessibility.post(element: textView, notification: .valueChanged)
    }
    
    
    /// Increase content font size.
    @IBAction func biggerFont(_ sender: Any?) {
        
        self.fontSize += 1
    }
    
    
    /// Decrease content font size.
    @IBAction func smallerFont(_ sender: Any?) {
        
        guard UserDefaults.standard[.consoleFontSize] > NSFont.smallSystemFontSize else { return }
        
        self.fontSize -= 1
    }
    
    
    /// Restore content font size to the default.
    @IBAction func resetFont(_ sender: Any?) {
        
        UserDefaults.standard.restore(key: .consoleFontSize)
        self.fontSize = UserDefaults.standard[.consoleFontSize]
    }
    
    
    // MARK: Private Methods
    
    /// Change font size of the text view.
    ///
    /// - Parameter fontSize: The new font size.
    private func changeFontSize(_ fontSize: Double) {
        
        guard let storage = self.textView?.textStorage else { return }
        
        storage.beginEditing()
        storage.enumerateAttribute(.consolePart, type: Console.Log.Part.self, in: storage.range) { (part, range, _) in
            storage.addAttributes(part.attributes(fontSize: fontSize), range: range)
        }
        storage.endEditing()
    }
}



// MARK: -

private extension NSAttributedString.Key {
    
    static let consolePart = Self("consolePart")
}


private extension Console.Log {
    
    enum Part {
        
        case timestamp
        case title
        case message
    }
    
    
    func attributedString(fontSize: Double) -> NSAttributedString {
        
        var string = NSMutableAttributedString()
        
        // header
        let dateFormat = Date.ISO8601FormatStyle(timeZone: .current)
            .year()
            .month()
            .day()
            .dateTimeSeparator(.space)
            .time(includingFractionalSeconds: false)
        string += NSAttributedString(string: "[\(self.date.formatted(dateFormat))]",
                                     attributes: Part.timestamp.attributes(fontSize: fontSize))
        if let title = self.title {
            string += NSAttributedString(string: " " + title, attributes: Part.title.attributes(fontSize: fontSize))
        }
        string += NSAttributedString(string: "\n")
        
        // body
        string += NSAttributedString(string: self.message + "\n", attributes: Part.message.attributes(fontSize: fontSize))
        
        // style
        string.addAttribute(.foregroundColor, value: NSColor.labelColor, range: string.range)
        
        return string
    }
}


private extension Console.Log.Part {
    
    func attributes(fontSize: Double) -> [NSAttributedString.Key: Any] {
        
        switch self {
            case .timestamp:
                return [
                    .consolePart: self,
                    .font: NSFont.systemFont(ofSize: fontSize),
                ]
                
            case .title:
                return [
                    .consolePart: self,
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                ]
                
            case .message:
                let paragraphStyle = NSParagraphStyle.default.mutable
                paragraphStyle.headIndent = fontSize
                paragraphStyle.firstLineHeadIndent = fontSize
                
                return [
                    .consolePart: self,
                    .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                    .paragraphStyle: paragraphStyle,
                ]
        }
    }
}
