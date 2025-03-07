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
//  © 2014-2025 1024jp
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
import Defaults
import StringUtils

struct Console {
    
    struct Log: Hashable, Equatable, Identifiable {
        
        let id = UUID()
        
        var message: String
        var title: String?
        var date: Date = .now
    }
    
    
    struct DisplayOptions: OptionSet {
        
        let rawValue: Int
        
        static let title     = Self(rawValue: 1 << 0)
        static let timestamp = Self(rawValue: 1 << 1)
        
        static let all: Self = [.title, .timestamp]
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
        panel.hidesOnDeactivate = false
        panel.title = String(localized: "Console", table: "Console", comment: "window title")
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
    
    
    /// Appends given message to the console.
    ///
    /// - Parameters:
    ///   - log: The console log to show.
    ///   - options: The metadata to display in the console.
    func append(log: Console.Log, options: Console.DisplayOptions = .all) {
        
        (self.contentViewController as! ConsoleViewController).append(log: log, options: options)
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
                item.label = String(localized: "Clear Log", table: "Console", comment: "toolbar item label")
                item.toolTip = item.label
                item.image = NSImage(systemSymbolName: "trash", accessibilityDescription: item.label)
                item.action = #selector(ConsoleViewController.clearAll)
                return item
                
            default:
                return nil
        }
    }
}


// MARK: -

private final class ConsoleViewController: NSViewController, TextSizeChanging {
    
    // MARK: Private Properties
    
    @ViewLoading private var textView: NSTextView
    
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
    
    /// Appends the given log message to the console.
    ///
    /// - Parameters:
    ///   - log: The log to append.
    ///   - options: The metadata to display in the console.
    func append(log: Console.Log, options: Console.DisplayOptions) {
        
        let textView = self.textView
        let lastLocation = textView.string.length
        let attributedString = log.attributedString(fontSize: self.fontSize, options: options)
        let range = NSRange(location: lastLocation, length: attributedString.length)
        
        textView.textStorage?.append(attributedString)
        NSAccessibility.post(element: textView, notification: .valueChanged)
        
        // scroll to make the message visible
        textView.scrollRangeToVisible(range)
    }
    
    
    // MARK: Actions
    
    /// Flushes existing log.
    @IBAction func clearAll(_ sender: Any?) {
        
        self.textView.string = ""
        NSAccessibility.post(element: self.textView, notification: .valueChanged)
    }
    
    
    /// Increases content font size.
    @IBAction func biggerFont(_ sender: Any?) {
        
        self.fontSize += 1
    }
    
    
    /// Decreases content font size.
    @IBAction func smallerFont(_ sender: Any?) {
        
        guard UserDefaults.standard[.consoleFontSize] > NSFont.smallSystemFontSize else { return }
        
        self.fontSize -= 1
    }
    
    
    /// Restores content font size to the default.
    @IBAction func resetFont(_ sender: Any?) {
        
        UserDefaults.standard.restore(key: .consoleFontSize)
        self.fontSize = UserDefaults.standard[.consoleFontSize]
    }
    
    
    // MARK: Private Methods
    
    /// Changes font size of the text view.
    ///
    /// - Parameter fontSize: The new font size.
    private func changeFontSize(_ fontSize: Double) {
        
        guard let storage = self.textView.textStorage else { return }
        
        storage.beginEditing()
        storage.enumerateAttribute(.font, type: NSFont.self, in: storage.range) { (font, range, _) in
            storage.addAttribute(.font, value: font.withSize(fontSize), range: range)
        }
        storage.endEditing()
    }
}


// MARK: -

private extension NSAttributedString.Key {
    
    static let consoleLogID = NSAttributedString.Key(rawValue: "consoleLogID")
}


private extension Console.Log {
    
    private enum Part {
        
        case timestamp
        case title
        case message
    }
    
    
    /// Returns attributed string to display in the console.
    ///
    /// - Parameters:
    ///   - fontSize: The font size.
    ///   - options: The display options.
    /// - Returns: An attributed string.
    func attributedString(fontSize: Double, options: Console.DisplayOptions) -> sending NSAttributedString {
        
        var string = NSMutableAttributedString()
        
        // header
        if options.contains(.timestamp) {
            let dateFormat = Date.ISO8601FormatStyle(timeZone: .current)
                .year()
                .month()
                .day()
                .dateTimeSeparator(.space)
                .time(includingFractionalSeconds: false)
            string += NSAttributedString(string: "[\(self.date.formatted(dateFormat))]",
                                         attributes: [.font: Self.font(for: .timestamp, size: fontSize)])
        }
        if options.contains(.title), let title = self.title {
            string += NSAttributedString(string: " " + title,
                                         attributes: [.font: Self.font(for: .title, size: fontSize)])
        }
        if string.length > 0 {
            string += NSAttributedString(string: "\n")
        }
        
        // body
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.headIndent = 10
        paragraphStyle.firstLineHeadIndent = 10
        string += NSAttributedString(string: self.message + "\n",
                                     attributes: [.font: Self.font(for: .message, size: fontSize),
                                                  .paragraphStyle: paragraphStyle])
        
        // all
        string.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .consoleLogID: self.id,
        ], range: string.range)
        
        return string
    }
    
    
    private static func font(for part: Part, size: Double) -> sending NSFont {
        
        switch part {
            case .timestamp:
                    .monospacedDigitSystemFont(ofSize: size, weight: .regular)
            case .title:
                    .systemFont(ofSize: size, weight: .semibold)
            case .message:
                    .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }
}
