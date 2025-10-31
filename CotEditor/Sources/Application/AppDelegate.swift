//
//  AppDelegate.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2013-2025 1024jp
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
import SwiftUI
import Combine
import OSLog
import ControlUI
import Defaults
import FileEncoding
import LineEnding
import StringUtils

@available(macOS, deprecated: 26)
let isLiquidGlass = if #available(macOS 26, *) { true } else { false }


extension Logger {
    
    static let app = Logger(subsystem: "com.coteditor.CotEditor", category: "application")
}


@MainActor @objc protocol EncodingChanging: AnyObject {
    
    func changeEncoding(_ sender: NSMenuItem)
}


@MainActor @objc protocol ThemeChanging: AnyObject {
    
    func changeTheme(_ sender: NSMenuItem)
}


@MainActor @objc protocol SyntaxChanging: AnyObject {
    
    func changeSyntax(_ sender: NSMenuItem)
    func recolorAll(_ sender: Any?)
}


@MainActor @objc protocol TextSizeChanging: AnyObject {
    
    func biggerFont(_ sender: Any?)
    func smallerFont(_ sender: Any?)
    func resetFont(_ sender: Any?)
}


@main
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Enums
    
    private enum AppWebURL: String {
        
        case website = "https://coteditor.com"
        case issueTracker = "https://github.com/coteditor/CotEditor/issues"
        
        var url: URL  { URL(string: self.rawValue)! }
    }
    
    
    private enum BundleIdentifier {
        
        static let scriptEditor = "com.apple.ScriptEditor2"
    }
    
    
    // MARK: Public Properties
    
    var needsRelaunch = false
    
    
    // MARK: Private Properties
    
    private var menuUpdateObservers: Set<AnyCancellable> = []
    
    private lazy var settingsWindowController = SettingsWindowController<SettingsPane>()
    private weak var aboutPanel: NSPanel?
    private weak var whatsNewPanel: NSPanel?
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxesMenu: NSMenu?
    @IBOutlet private weak var lineEndingsMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    @IBOutlet private weak var normalizationMenu: NSMenu?
    @IBOutlet private weak var snippetMenu: NSMenu?
    @IBOutlet private weak var multipleReplaceMenu: NSMenu?
    @IBOutlet private weak var scriptMenu: NSMenu?
    
    
    // MARK: Lifecycle
    
    override init() {
        
        // register default setting values
        let defaults = DefaultSettings.defaults
            .compactMapValues(\.self)
            .mapKeys(\.rawValue)
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared.initialValues = defaults
    }
    
    
    // MARK: Application Delegate
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        // -> Setting `automaticTerminationSupportEnabled` programmatically doesn't appear to be working.
        //    (2024-11, macOS 15.1, FB15979536)
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = true
        if Document.autosavesInPlace {
            ProcessInfo.processInfo.enableSuddenTermination()
        }
        
        _ = DocumentController.shared
        
        self.prepareMainMenu()
        
        #if SPARKLE
        UpdaterManager.shared.setup()
        #endif
    }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        KeyBindingManager.shared.applyShortcutsToMainMenu()
        
        NSApp.servicesProvider = ServicesProvider()
        NSTouchBar.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        let lastVersion = UserDefaults.standard[.lastVersion].flatMap(Int.init)
        
        // show What's New panel for the latest minor update
        if let lastVersion, lastVersion < NewFeature.buildNumber {
            self.showWhatsNew(nil)
        }
        
        // store the latest version
        // -> Migration processes should be completed up to this point.
        let thisVersion = Bundle.main.bundleVersion
        if lastVersion == nil || Int(thisVersion)! > lastVersion! {
            UserDefaults.standard[.lastVersion] = thisVersion
        }
    }
    
    
    func applicationWillTerminate(_ notification: Notification) {
        
        if self.needsRelaunch {
            NSApp.relaunch()
        }
    }
    
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        // be called on the open event when iCloud Drive is disabled (2024-05, macOS 14).
        // -> Otherwise, NSDocumentController.openDocument(_:) is directly called on launch.
        
        (DocumentController.shared as? DocumentController)?.performOnLaunchAction()
        
        return false
    }
    
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        // only on the *re*-open event (not called on the app launch)
        
        // Because the default reopen behavior varies depending on various conditions,
        // such as NSQuitAlwaysKeepsWindows, the iCloud Drive availability, etc,
        // execute the action directly by self (2024-05, macOS 14).
        if !flag {
            (DocumentController.shared as? DocumentController)?.performOnLaunchAction(isReopen: true)
            return false
        } else {
            // -> bring a document in the Dock to the front if any exists.
            return true
        }
    }
    
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        
        assert(Thread.isMainThread)
        
        let urls = filenames.map { URL(filePath: $0) }
        let isAutomaticTabbing = (DocumentWindow.userTabbingPreference == .inFullScreen) && (urls.count > 1)
        
        Task {
            let reply: NSApplication.DelegateReply = await withThrowingTaskGroup { group in
                for url in urls {
                    group.addTask { try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true) }
                }
                
                var firstWindowOpened = false
                var reply: NSApplication.DelegateReply = .failure
                
                while let result = await group.nextResult() {
                    switch result {
                        case .success(let (_, documentWasAlreadyOpen)):
                            reply = .success
                            // on first window opened
                            // -> The first document needs to open a new window.
                            if isAutomaticTabbing, !documentWasAlreadyOpen, !firstWindowOpened {
                                DocumentWindow.tabbingPreference = .always
                                firstWindowOpened = true
                            }
                        case .failure(let error):
                            let cancelled = (error as? CocoaError)?.code == .userCancelled
                            if cancelled {
                                reply = (reply == .failure) ? .cancel : reply
                            } else {
                                // ask user for opening file
                                NSApp.presentError(error)
                            }
                    }
                }
                
                return reply
            }
            
            if isAutomaticTabbing {
                DocumentWindow.tabbingPreference = nil
            }
            
            NSApp.reply(toOpenOrPrint: reply)
        }
    }
    
    
    // MARK: Action Messages
    
    /// Activates self and perform New menu action (from Dock menu).
    @IBAction func newDocumentActivatingApplication(_ sender: Any?) {
        
        NSApp.activate()
        NSDocumentController.shared.newDocument(sender)
    }
    
    
    /// Shows the about panel.
    @IBAction func showAboutPanel(_ sender: Any?) {
        
        let panel = self.aboutPanel ?? NSPanel(view: AboutView(), title: String(localized: "About \(Bundle.main.bundleName)", table: "About", comment: "%@ is app name"))
        panel.makeKeyAndOrderFront(sender)
        
        self.aboutPanel = panel
    }
    
    
    /// Shows the What's New panel.
    @IBAction func showWhatsNew(_ sender: Any?) {
        
        let panel = self.whatsNewPanel ?? NSPanel(view: WhatsNewView())
        panel.makeKeyAndOrderFront(sender)
        
        self.whatsNewPanel = panel
    }
    
    
    /// Shows the Settings window.
    @IBAction func showSettingsWindow(_ sender: Any?) {
        
        self.settingsWindowController.showWindow(sender)
    }
    
    
    /// Shows the Quick Action command bar.
    @IBAction func showQuickActions(_ sender: Any?) {
        
        if CommandBarWindowController.shared.window?.isVisible == true {
            CommandBarWindowController.shared.close()
        } else {
            CommandBarWindowController.shared.showWindow(sender)
        }
    }
    
    
    /// Shows Snippet pane in the Settings window.
    @IBAction func showSnippetEditor(_ sender: Any?) {
        
        self.settingsWindowController.openPane(.snippets)
    }
    
    
    /// Shows the Encoding List to customize encodings list.
    @IBAction func showEncodingsListEditor(_ sender: Any?) {
        
        self.settingsWindowController.openPane(.format)
        Task {
            try await Task.sleep(for: .seconds(0.3))
            NSApp.sendAction(#selector((any EncodingsListHolder).showEncodingsListView), to: nil, from: nil)
        }
    }
    
    
    /// Shows the Color panel with the color code control.
    @IBAction func editColorCode(_ sender: Any?) {
        
        ColorCodePanelController.shared.showWindow()
    }
    
    
    /// Shows console panel.
    @IBAction func showConsolePanel(_ sender: Any?) {
        
        ConsolePanelController.shared.showWindow(sender)
    }
    
    
    /// Opens OSA script dictionary in Script Editor.
    @IBAction func openAppleScriptDictionary(_ sender: Any?) {
        
        guard let scriptEditorURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: BundleIdentifier.scriptEditor) else { return }
        
        let appURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        
        NSWorkspace.shared.open([appURL], withApplicationAt: scriptEditorURL, configuration: configuration)
    }
    
    
    /// Opens a specific page in the system Help viewer.
    @IBAction func openHelpAnchor(_ sender: any NSUserInterfaceItemIdentification) {
        
        guard let identifier = sender.identifier else { return assertionFailure() }
        
        NSHelpManager.shared.openHelpAnchor(identifier.rawValue, inBook: Bundle.main.helpBookName)
    }
    
    
    /// Opens the application web site (coteditor.com) in the default web browser.
    @IBAction func openWebSite(_ sender: Any?) {
        
        NSWorkspace.shared.open(AppWebURL.website.url)
    }
    
    
    /// Opens the bug report page in the default web browser.
    @IBAction func reportBug(_ sender: Any?) {
        
        NSWorkspace.shared.open(AppWebURL.issueTracker.url)
    }
    
    
    /// Opens a new bug report window.
    @IBAction func createBugReport(_ sender: Any?) {
        
        let report = IssueReport()
        
        // open as document
        do {
            let document = try (NSDocumentController.shared as! DocumentController).openUntitledDocument(contents: report.template, title: report.title, display: true)
            document.setSyntax(name: SyntaxName.markdown)
        } catch {
            NSApp.presentError(error)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Prepares the main menu.
    private func prepareMainMenu() {
        
        assert(NSApp.mainMenu != nil)
        
        guard self.menuUpdateObservers.isEmpty else { return assertionFailure() }
        
        self.updateEncodingMenu(self.encodingsMenu!)
        
        self.lineEndingsMenu?.items = LineEnding.allCases.map { lineEnding in
            let item = NSMenuItem()
            item.title = "\(lineEnding.description) (\(lineEnding.label))"
            item.tag = lineEnding.index
            item.action = #selector(Document.changeLineEnding(_:))
            item.isHidden = !lineEnding.isBasic
            item.keyEquivalentModifierMask = lineEnding.isBasic ? [] : [.option]
            
            return item
        }
        
        SyntaxManager.shared.$settingNames
            .map { names in
                names.map { name in
                    let item = NSMenuItem(title: name, action: #selector((any SyntaxChanging).changeSyntax), keyEquivalent: "")
                    item.representedObject = name
                    return item
                }
            }
            .sink { [weak self] items in
                guard let menu = self?.syntaxesMenu else { return }
                
                let recolorItem = menu.items.first { $0.action == #selector((any SyntaxChanging).recolorAll) }
                let noneItem = NSMenuItem(title: String(localized: "SyntaxName.none", defaultValue: "None"), action: #selector((any SyntaxChanging).changeSyntax), keyEquivalent: "")
                noneItem.representedObject = SyntaxName.none
                
                menu.removeAllItems()
                menu.addItem(noneItem)
                menu.addItem(.separator())
                menu.items += items
                menu.addItem(.separator())
                menu.addItem(recolorItem!)
            }
            .store(in: &self.menuUpdateObservers)
        
        ThemeManager.shared.$settingNames
            .map { $0.map { NSMenuItem(title: $0, action: #selector((any ThemeChanging).changeTheme), keyEquivalent: "") } }
            .assign(to: \.items, on: self.themesMenu!)
            .store(in: &self.menuUpdateObservers)
        
        SnippetManager.shared.menu = self.snippetMenu!
        ScriptManager.shared.menu = self.scriptMenu!
        
        // build Unicode normalization menu items
        self.normalizationMenu?.items = (UnicodeNormalizationForm.standardForms + [nil] +
                                         UnicodeNormalizationForm.modifiedForms)
        .map { form in
            guard let form else { return .separator() }
            
            let item = NSMenuItem()
            item.title = form.localizedName
            item.action = #selector(EditorTextView.normalizeUnicode(_:))
            item.representedObject = form
            item.tag = form.tag  // for the shortcut customization
            item.toolTip = form.localizedDescription
            return item
        }
        
        // build multiple replacement menu items
        ReplacementManager.shared.$settingNames
            .sink { [weak self] names in
                guard let menu = self?.multipleReplaceMenu else { return }
                
                let manageItem = menu.items.last
                menu.items = names.map { name in
                    let item = NSMenuItem()
                    item.title = name
                    item.action = #selector(NSTextView.performTextFinderAction)
                    item.tag = TextFinder.Action.multipleReplace.rawValue
                    item.representedObject = name
                    return item
                } + [
                    .separator(),
                    manageItem!,
                ]
            }
            .store(in: &self.menuUpdateObservers)
    }
}


extension AppDelegate: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        switch menu {
            case self.encodingsMenu:
                self.updateEncodingMenu(menu, checksDocument: true)
            default:
                break
        }
    }
    
    
    /// Updates the Text Encoding menu.
    ///
    /// By considering the document, if the document's file encoding isn't already in the list, it is inserted at the top of the list.
    ///
    /// - Parameters:
    ///   - menu: The menu to update.
    ///   - checksDocument: `true` to consider the currently targeted document.
    private func updateEncodingMenu(_ menu: NSMenu, checksDocument: Bool = false) {
        
        let action = #selector((any EncodingChanging).changeEncoding)
        var fileEncodings = EncodingManager.shared.fileEncodings
        
        if checksDocument,
           let document = NSApp.target(forAction: action) as? Document,
           !fileEncodings.contains(document.fileEncoding)
        {
            fileEncodings.insert(contentsOf: [document.fileEncoding, nil], at: 0)
        }
        
        menu.items = fileEncodings.map { fileEncoding in
            switch fileEncoding {
                case .some(let fileEncoding):
                    let item = NSMenuItem()
                    item.title = fileEncoding.localizedName
                    item.action = action
                    item.representedObject = fileEncoding
                    return item
                case .none:
                    return .separator()
            }
        } + [
            .separator(),
            NSMenuItem(title: String(localized: "Customize Encodings List…", table: "MainMenu"), action: #selector(showEncodingsListEditor), keyEquivalent: ""),
        ]
    }
}


// MARK: - Private Extensions

private extension NSSound {
    
    @MainActor static let glass = NSSound(named: "Glass")
}


private extension NSPanel {
    
    /// Instantiates a panel with a SwiftUI view.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view.
    ///   - title: The window title mainly for the accessibility.
    convenience init(view: some View, title: String? = nil) {
        
        let viewController = NSHostingController(rootView: view)
        viewController.safeAreaRegions = []
        
        self.init(contentViewController: viewController)
        
        self.styleMask = [.closable, .titled, .fullSizeContentView]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.hidesOnDeactivate = false
        self.setContentSize(viewController.view.intrinsicContentSize)
        
        if let title {
            self.title = title
        }
        
        self.center()
    }
}


private extension UnicodeNormalizationForm {
    
    /// Unique identifier for menu item.
    var tag: Int {
        
        Self.allCases.firstIndex(of: self)!
    }
}
