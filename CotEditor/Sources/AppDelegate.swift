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
//  © 2013-2023 1024jp
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

import Combine
import Cocoa
import UniformTypeIdentifiers

private extension NSSound {
    
    static let glass = NSSound(named: "Glass")
}


private enum BundleIdentifier {
    
    static let scriptEditor = "com.apple.ScriptEditor2"
}



@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    
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
    
    private lazy var settingsWindowController = SettingsWindowController()
    private lazy var acknowledgmentsWindowController = WebDocumentWindowController(fileURL: Bundle.main.url(forResource: "Acknowledgments", withExtension: "html")!)
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxStylesMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    @IBOutlet private weak var normalizationMenu: NSMenu?
    @IBOutlet private weak var snippetMenu: NSMenu?
    
    
    #if DEBUG
    private let textKitObserver = NotificationCenter.default.publisher(for: NSTextView.didSwitchToNSLayoutManagerNotification)
        .compactMap { $0.object as? NSTextView }
        .sink { print("⚠️ \($0.className) did switch to NSLayoutManager.") }
    #endif
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        // register default setting values
        let defaults = DefaultSettings.defaults.mapKeys(\.rawValue)
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared.initialValues = defaults
        
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = true
        
        // instantiate shared instances
        _ = DocumentController.shared
    }
    
    
    @MainActor override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // sync menus with setting list updates
        EncodingManager.shared.$encodings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let menu = self?.encodingsMenu else { return }
                EncodingManager.shared.updateChangeEncodingMenu(menu)
            }
            .store(in: &self.menuUpdateObservers)
        
        SyntaxManager.shared.$settingNames
            .map { $0.map { NSMenuItem(title: $0, action: #selector((any SyntaxHolder).changeSyntaxStyle), keyEquivalent: "") } }
            .receive(on: RunLoop.main)
            .sink { [weak self] (items) in
                guard let menu = self?.syntaxStylesMenu else { return }
                
                let recolorItem = menu.items.first { $0.action == #selector((any SyntaxHolder).recolorAll) }
                
                menu.removeAllItems()
                menu.addItem(withTitle: BundledStyleName.none, action: #selector((any SyntaxHolder).changeSyntaxStyle), keyEquivalent: "")
                menu.addItem(.separator())
                menu.items += items
                menu.addItem(.separator())
                menu.addItem(recolorItem!)
            }
            .store(in: &self.menuUpdateObservers)
        
        ThemeManager.shared.$settingNames
            .map { $0.map { NSMenuItem(title: $0, action: #selector((any ThemeHolder).changeTheme), keyEquivalent: "") } }
            .receive(on: RunLoop.main)
            .assign(to: \.items, on: self.themesMenu!)
            .store(in: &self.menuUpdateObservers)
        
        SnippetManager.shared.menu = self.snippetMenu!
        
        ScriptManager.shared.observeScriptsDirectory()
        
        // build Unicode normalization menu items
        self.normalizationMenu?.items = (UnicodeNormalizationForm.standardForms + [nil] +
                                         UnicodeNormalizationForm.modifiedForms)
            .map { (form) in
                guard let form else { return .separator() }
                
                let action: Selector
                switch form {
                    case .nfd:
                        action = #selector(EditorTextView.normalizeUnicodeWithNFD)
                    case .nfc:
                        action = #selector(EditorTextView.normalizeUnicodeWithNFC)
                    case .nfkd:
                        action = #selector(EditorTextView.normalizeUnicodeWithNFKD)
                    case .nfkc:
                        action = #selector(EditorTextView.normalizeUnicodeWithNFKC)
                    case .nfkcCasefold:
                        action = #selector(EditorTextView.normalizeUnicodeWithNFKCCF)
                    case .modifiedNFD:
                        action = #selector(EditorTextView.normalizeUnicodeWithModifiedNFD)
                    case .modifiedNFC:
                        action = #selector(EditorTextView.normalizeUnicodeWithModifiedNFC)
                }
                
                let item = NSMenuItem(title: form.localizedName, action: action, keyEquivalent: "")
                item.toolTip = form.localizedDescription
                return item
            }
    }
    
    
    
    // MARK: Application Delegate
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        
        true
    }
    
    
    #if SPARKLE
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        UpdaterManager.shared.setup()
    }
    #endif
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        KeyBindingManager.shared.applyShortcutsToMainMenu()
        
        NSApp.servicesProvider = ServicesProvider()
        NSHelpManager.shared.registerBooks(in: .main)
        NSTouchBar.isAutomaticCustomizeTouchBarMenuItemEnabled = true
    }
    
    
    func applicationWillTerminate(_ notification: Notification) {
        
        // store the latest version before termination
        // -> The bundle version (build number) must be Int.
        let thisVersion = Bundle.main.bundleVersion
        let lastVersion = UserDefaults.standard[.lastVersion].flatMap(Int.init)
        if lastVersion == nil || Int(thisVersion)! > lastVersion! {
            UserDefaults.standard[.lastVersion] = thisVersion
        }
        
        if self.needsRelaunch {
            NSApp.relaunch()
        }
    }
    
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        switch UserDefaults.standard[.noDocumentOnLaunchBehavior] {
            case .untitledDocument:
                return true
            case .openPanel:
                NSDocumentController.shared.openDocument(nil)
                return false
            case .none:
                return false
        }
    }
    
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        
        assert(Thread.isMainThread)
        
        let documentURLs = filenames.map(URL.init(fileURLWithPath:))
            .filter {
                // ask installation if the file is CotEditor theme file
                $0.conforms(to: .cotTheme) ? !self.askThemeInstallation(fileURL: $0) : true
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
    
    /// Activate self and perform New menu action (from Dock menu).
    @IBAction func newDocumentActivatingApplication(_ sender: Any?) {
        
        NSApp.activate(ignoringOtherApps: true)
        NSDocumentController.shared.newDocument(sender)
    }
    
    
    /// Activate self and perform the Open menu command (from Dock menu).
    @IBAction func openDocumentActivatingApplication(_ sender: Any?) {
        
        NSApp.activate(ignoringOtherApps: true)
        NSDocumentController.shared.openDocument(sender)
    }
    
    
    /// Show the standard about panel.
    @IBAction func showAboutPanel(_ sender: Any?) {
        
        let creditsURL = Bundle.main.url(forResource: "Credits", withExtension: "html")!
        var html = try! String(contentsOf: creditsURL)
        
        #if !SPARKLE  // Remove Sparkle from 3rd party code list
        if let range = html.range(of: "Sparkle") {
            html.removeSubrange(html.lineRange(for: range))
        }
        #endif
        
        let attrString = NSAttributedString(html: html.data(using: .utf8)!, baseURL: creditsURL, documentAttributes: nil)!
        NSApp.orderFrontStandardAboutPanel(options: [.credits: attrString])
    }
    
    
    /// Show the Settings window.
    @IBAction func showPreferences(_ sender: Any?) {
        
        self.settingsWindowController.showWindow(sender)
    }
    
    
    /// Show Snippet pane in the Settings window.
    @IBAction func showSnippetEditor(_ sender: Any?) {
        
        self.settingsWindowController.openPane(.snippets)
    }
    
    
    /// Show console panel.
    @IBAction func showConsolePanel(_ sender: Any?) {
        
        Console.shared.panelController.showWindow(sender)
    }
    
    
    /// Show acknowlegements window.
    @IBAction func showAcknowledgments(_ sender: Any?) {
        
        self.acknowledgmentsWindowController.showWindow(sender)
    }
    
    
    /// Open OSAScript dictionary in Script Editor.
    @IBAction func openAppleScriptDictionary(_ sender: Any?) {
        
        guard let scriptEditorURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: BundleIdentifier.scriptEditor) else { return }
        
        let appURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        
        NSWorkspace.shared.open([appURL], withApplicationAt: scriptEditorURL, configuration: configuration)
    }
    
    
    /// Open a specific page in the system Help viewer.
    @IBAction func openHelpAnchor(_ sender: AnyObject) {
        
        guard let identifier = (sender as? any NSUserInterfaceItemIdentification)?.identifier else { return assertionFailure() }
        
        NSHelpManager.shared.openHelpAnchor(identifier.rawValue, inBook: Bundle.main.helpBookName)
    }
    
    
    /// Open the application web site (coteditor.com) in the default web browser.
    @IBAction func openWebSite(_ sender: Any?) {
        
        NSWorkspace.shared.open(AppWebURL.website.url)
    }
    
    
    /// Open the bug report page in the default web browser.
    @IBAction func reportBug(_ sender: Any?) {
        
        NSWorkspace.shared.open(AppWebURL.issueTracker.url)
    }
    
    
    /// Open a new bug report window.
    @IBAction func createBugReport(_ sender: Any?) {
        
        // load template file
        guard
            let url = Bundle.main.url(forResource: "ReportTemplate", withExtension: "md"),
            let template = try? String(contentsOf: url)
        else { return assertionFailure() }
        
        // fill template with user environment info
        let title = String(localized: "Issue Report", comment: "document title")
        let report = template
            .replacingOccurrences(of: "%BUNDLE_VERSION%", with: Bundle.main.bundleVersion)
            .replacingOccurrences(of: "%SHORT_VERSION%", with: Bundle.main.shortVersion)
            .replacingOccurrences(of: "%SYSTEM_VERSION%", with: ProcessInfo.processInfo.operatingSystemVersionString)
        
        // open as document
        do {
            let document = try (NSDocumentController.shared as! DocumentController).openUntitledDocument(content: report, title: title, display: true)
            document.setSyntaxStyle(name: BundledStyleName.markdown)
        } catch {
            NSApp.presentError(error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Ask user whether install the file as a CotEditor theme, or process as a text file.
    ///
    /// - Parameter url: The file URL to a theme file.
    /// - Returns: Whether the given file was handled as a theme file.
    private func askThemeInstallation(fileURL url: URL) -> Bool {
        
        assert(url.conforms(to: .cotTheme))
        
        // ask whether theme file should be opened as a text file
        let alert = NSAlert()
        alert.messageText = String(localized: "“\(url.lastPathComponent)” is a CotEditor theme file.")
        alert.informativeText = "Do you want to install this theme?".localized
        alert.addButton(withTitle: "Install".localized)
        alert.addButton(withTitle: "Open as Text File".localized)
        
        let returnCode = alert.runModal()
        
        guard returnCode == .alertFirstButtonReturn else { return false }  // = Open as Text File
        
        // import theme
        do {
            try ThemeManager.shared.importSetting(fileURL: url)
            
        } catch {
            // ask whether the old theme should be repleced with new one if the same name theme is already exists
            let success = NSApp.presentError(error)
            
            guard success else { return true }  // cancelled
        }
        
        // feedback for success
        let themeName = ThemeManager.shared.settingName(from: url)
        let feedbackAlert = NSAlert()
        feedbackAlert.messageText = String(localized: "A new theme named “\(themeName)” has been successfully installed.")
        
        NSSound.glass?.play()
        feedbackAlert.runModal()
        
        return true
    }
}
