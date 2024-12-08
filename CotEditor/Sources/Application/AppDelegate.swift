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
//  © 2013-2024 1024jp
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
import UniformTypeIdentifiers
import OSLog
import ControlUI
import Defaults
import FileEncoding
import LineEnding
import StringUtils

extension Logger {
    
    static let app = Logger(subsystem: "com.coteditor.CotEditor", category: "application")
}


private extension NSSound {
    
    @MainActor static let glass = NSSound(named: "Glass")
}


private enum BundleIdentifier {
    
    static let scriptEditor = "com.apple.ScriptEditor2"
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



@main
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Enums
    
    private enum AppWebURL: String {
        
        case website = "https://coteditor.com"
        case issueTracker = "https://github.com/coteditor/CotEditor/issues"
        
        var url: URL  { URL(string: self.rawValue)! }
    }
    
    
    // MARK: Public Properties
    
    var needsRelaunch = false
    
    
    // MARK: Private Properties
    
    private var menuUpdateObservers: Set<AnyCancellable> = []
    
    private lazy var aboutPanel = NSPanel(view: AboutView())
    private lazy var whatsNewPanel = NSPanel(view: WhatsNewView())
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxesMenu: NSMenu?
    @IBOutlet private weak var lineEndingsMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    @IBOutlet private weak var normalizationMenu: NSMenu?
    @IBOutlet private weak var snippetMenu: NSMenu?
    @IBOutlet private weak var multipleReplaceMenu: NSMenu?
    
    
    #if DEBUG
    private let textKitObserver = NotificationCenter.default
        .addObserver(forName: NSTextView.didSwitchToNSLayoutManagerNotification, object: nil, queue: .main) { notification in
            let textView = notification.object as! NSTextView
            Logger.app.debug("\(textView.className) did switch to NSLayoutManager.")
        }
    #endif
    
    
    
    // MARK: Lifecycle
    
    override init() {
        
        // register default setting values
        let defaults = DefaultSettings.defaults
            .compactMapValues(\.self)
            .mapKeys(\.rawValue)
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared.initialValues = defaults
        
        // migrate settings on CotEditor 4.6.0 (2023-08)
        if let lastVersion = UserDefaults.standard[.lastVersion].flatMap(Int.init), lastVersion <= 586 {
            UserDefaults.standard.migrateFontSetting()
        }
    }
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        MainActor.assumeIsolated {
            self.menuUpdateObservers.removeAll()
            
            // sync menus with setting list updates
            withContinuousObservationTracking(initial: true) {
                _ = EncodingManager.shared.fileEncodings
            } onChange: {
                Task { @MainActor in
                    self.encodingsMenu?.items = EncodingManager.shared.fileEncodings.map(\.menuItem)
                }
            }
            
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
                .map {
                    $0.map {
                        let item = NSMenuItem(title: $0, action: #selector((any SyntaxChanging).changeSyntax), keyEquivalent: "")
                        item.representedObject = $0
                        return item
                    }
                }
                .receive(on: RunLoop.main)
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
                .receive(on: RunLoop.main)
                .assign(to: \.items, on: self.themesMenu!)
                .store(in: &self.menuUpdateObservers)
            
            SnippetManager.shared.menu = self.snippetMenu!
            
            ScriptManager.shared.observeScriptsDirectory()
            
            // build Unicode normalization menu items
            self.normalizationMenu?.items = (UnicodeNormalizationForm.standardForms + [nil] +
                                             UnicodeNormalizationForm.modifiedForms)
            .map { form in
                guard let form else { return .separator() }
                
                let item = NSMenuItem()
                item.title = form.localizedName
                item.action = #selector(EditorTextView.normalizeUnicode(_:))
                item.representedObject = form.rawValue
                item.tag = form.tag  // for the shortcut customization
                item.toolTip = form.localizedDescription
                return item
            }
            
            // build multiple replacement menu items
            ReplacementManager.shared.$settingNames
                .receive(on: RunLoop.main)
                .sink {
                    guard let menu = self.multipleReplaceMenu else { return }
                    
                    let manageItem = menu.items.last
                    menu.items = $0.map {
                        let item = NSMenuItem()
                        item.title = $0
                        item.action = #selector(NSTextView.performTextFinderAction)
                        item.tag = TextFinder.Action.multipleReplace.rawValue
                        item.representedObject = $0
                        return item
                    } + [
                        .separator(),
                        manageItem!,
                    ]
                }
                .store(in: &self.menuUpdateObservers)
        }
    }
    
    
    
    // MARK: Application Delegate
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        // programmatically setting `automaticTerminationSupportEnabled` seems not working (macOS 15.1 2024-11, FB15979536)
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = true
        if Document.autosavesInPlace {
            ProcessInfo.processInfo.enableSuddenTermination()
        }
        
        _ = DocumentController.shared
        
        #if SPARKLE
        UpdaterManager.shared.setup()
        #endif
    }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        KeyBindingManager.shared.applyShortcutsToMainMenu()
        
        NSApp.servicesProvider = ServicesProvider()
        NSTouchBar.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        let lastVersion = UserDefaults.standard[.lastVersion].flatMap(Int.init)
        
        // show What's New panel for CotEditor 5.0.0
        if let lastVersion, lastVersion <= 666 {
            self.showWhatsNew(nil)
        }
        
        // store the latest version
        // -> migration processes should be finished until here.
        let thisVersion = Bundle.main.bundleVersion
        if lastVersion == nil || Int(thisVersion)! > lastVersion! {
            UserDefaults.standard[.lastVersion] = thisVersion
        }
    }
    
    
    func applicationWillTerminate(_ notification: Notification) {
        
        ScriptManager.shared.cancelScriptsDirectoryObservation()
        
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
        
        let documentURLs = filenames.map(URL.init(fileURLWithPath:))
            .filter {
                // ask installation if the file is CotEditor theme file
                $0.conforms(to: .cotTheme) ? !self.askThemeInstallation(at: $0) : true
            }
        
        guard !documentURLs.isEmpty else { return NSApp.reply(toOpenOrPrint: .success) }
        
        let isAutomaticTabbing = (DocumentWindow.userTabbingPreference == .inFullScreen) && (documentURLs.count > 1)
        let dispatchGroup = DispatchGroup()
        var firstWindowOpened = false
        var reply: NSApplication.DelegateReply = .success
        
        for url in documentURLs {
            dispatchGroup.enter()
            DocumentController.shared.openDocument(withContentsOf: url, display: true) { (document, documentWasAlreadyOpen, error) in
                defer {
                    dispatchGroup.leave()
                }
                
                if let error {
                    let cancelled = (error as? CocoaError)?.code == .userCancelled
                    reply = cancelled ? .cancel : .failure
                    
                    // ask user for opening file
                    if !cancelled {
                        DispatchQueue.main.async {
                            NSApp.presentError(error)
                        }
                    }
                }
                
                // on first window opened
                // -> The first document needs to open a new window.
                if isAutomaticTabbing, !documentWasAlreadyOpen, document != nil, !firstWindowOpened {
                    DocumentWindow.tabbingPreference = .always
                    firstWindowOpened = true
                }
            }
        }
        
        // wait until finish
        dispatchGroup.notify(queue: .main) {
            // reset tabbing setting
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
        
        self.aboutPanel.makeKeyAndOrderFront(sender)
    }
    
    
    /// Shows the What's New panel.
    @IBAction func showWhatsNew(_ sender: Any?) {
        
        self.whatsNewPanel.makeKeyAndOrderFront(sender)
    }
    
    
    /// Shows the Settings window.
    @IBAction func showSettingsWindow(_ sender: Any?) {
        
        SettingsWindowController.shared.showWindow(sender)
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
        
        SettingsWindowController.shared.openPane(.snippets)
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
    
    /// Asks user whether install the file as a CotEditor theme, or process as a text file.
    ///
    /// - Parameter fileURL: The file URL to a theme file.
    /// - Returns: Whether the given file was handled as a theme file.
    private func askThemeInstallation(at fileURL: URL) -> Bool {
        
        assert(fileURL.conforms(to: .cotTheme))
        
        // ask whether theme file should be opened as a text file
        let alert = NSAlert()
        alert.messageText = String(localized: "ThemeImportAlert.message", defaultValue: "“\(fileURL.lastPathComponent)” is a CotEditor theme file.")
        alert.informativeText = String(localized: "ThemeImportAlert.informativeText", defaultValue: "Do you want to install this theme?")
        alert.addButton(withTitle: String(localized: "ThemeImportAlert.button.install", defaultValue: "Install", comment: "button label"))
        alert.addButton(withTitle: String(localized: "ThemeImportAlert.button.openAsText", defaultValue: "Open as Text File", comment: "button label"))
        
        let returnCode = alert.runModal()
        
        guard returnCode == .alertFirstButtonReturn else { return false }  // = Open as Text File
        
        // import theme
        do {
            try ThemeManager.shared.importSetting(at: fileURL)
            
        } catch {
            // ask whether the old theme should be replaced with new one if the same name theme is already exists
            let success = NSApp.presentError(error)
            
            guard success else { return true }  // cancelled
        }
        
        // feedback for success
        let themeName = ThemeManager.settingName(from: fileURL)
        let feedbackAlert = NSAlert()
        feedbackAlert.messageText = String(localized: "ThemeImportAlert.success",
                                           defaultValue: "A new theme named “\(themeName)” has been successfully installed.")
        
        NSSound.glass?.play()
        feedbackAlert.runModal()
        
        return true
    }
}


private extension NSPanel {
    
    /// Instantiates a panel with a SwiftUI view.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view.
    convenience init(view: any View) {
        
        let viewController = NSHostingController(rootView: AnyView(view))
        viewController.safeAreaRegions = []
        
        self.init(contentViewController: viewController)
        
        self.styleMask = [.closable, .titled, .fullSizeContentView]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.setContentSize(viewController.view.intrinsicContentSize)
        
        self.center()
    }
}


private extension Optional<FileEncoding> {
    
    /// Creates menu item with action `changeEncoding(_:)`.
    var menuItem: NSMenuItem {
        
        switch self {
            case .some(let fileEncoding):
                let item = NSMenuItem(title: fileEncoding.localizedName, action: #selector((any EncodingChanging).changeEncoding), keyEquivalent: "")
                item.representedObject = fileEncoding
                return item
            case .none:
                return .separator()
        }
    }
}


private extension UnicodeNormalizationForm {
    
    /// Unique identifier for menu item.
    var tag: Int {
        
        Self.allCases.firstIndex(of: self)!
    }
}


private extension UserDefaults {
    
    /// Migrates the user font setting to new format introduced on CotEditor 4.6.0 (2023-09).
    @available(macOS, deprecated: 16, message: "The font setting migration is outdated.")
    func migrateFontSetting() {
        
        guard
            self.data(forKey: DefaultKey<Data>.font.rawValue) == nil,
            self.data(forKey: DefaultKey<Data>.monospacedFont.rawValue) == nil,
            let name = self.string(forKey: "fontName"),
            let font = NSFont(name: name, size: self.double(forKey: "fontSize")),
            self[.font] == nil,
            self[.monospacedFont] == nil,
            let data = try? font.archivedData
        else { return }
        
        self[font.isFixedPitch ? .monospacedFont : .font] = data
    }
}
