/*
 
 AppDelegate.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-13.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2013-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Enums
    
    private enum AppWebURL: String {
        case website = "https://coteditor.com"
        case issueTracker = "https://github.com/coteditor/CotEditor/issues"
        
        var url: URL {
            return URL(string: self.rawValue)!
        }
    }
    
    
    // MARK: Public Properties
    
    dynamic let supportsWindowTabbing: Bool  // binded also in Window pref pane
    
    
    // MARK: Private Properties
    
    private var didFinishLaunching = false
    private lazy var acknowledgmentsWindowController = WebDocumentWindowController(documentName: "Acknowledgments")!
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxStylesMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        // add tab window
        if #available(macOS 10.12, *) {
            self.supportsWindowTabbing = true
        } else {
            self.supportsWindowTabbing = false
        }
        
        // register default setting values
        let defaults: [String: Any] = DefaultSettings.reduce([:]) { (dict, item) in
            var dict = dict
            dict[item.key.rawValue] = item.value
            return dict
        }
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared().initialValues = defaults
        
        // instantiate DocumentController
        _ = DocumentController.shared()
        
        // wake text finder up
        _ = TextFinder.shared
        
        // register transformers
        ValueTransformer.setValueTransformer(HexColorTransformer(), forName: HexColorTransformer.name)
        
        super.init()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func awakeFromNib() {
        
        // store key bindings in MainMenu.xib before menu is modified
        MenuKeyBindingManager.shared.scanDefaultMenuKeyBindings()
        
        // build menus
        self.buildEncodingMenu()
        self.buildSyntaxMenu()
        self.buildThemeMenu()
        ScriptManager.shared.buildScriptMenu()
        
        // observe setting list updates
        NotificationCenter.default.addObserver(self, selector: #selector(buildEncodingMenu), name: .EncodingListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildSyntaxMenu), name: .SyntaxListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildThemeMenu), name: .ThemeListDidUpdate, object: nil)
    }
    
    
    
    // MARK: Application Delegate
    
    #if APPSTORE
    #else
    /// setup Sparkle framework
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        UpdaterManager.shared.setup()
    }
    #endif
    
    
    /// just after application did launch
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // setup KeyBindingManager
        MenuKeyBindingManager.shared.applyKeyBindingsToMainMenu()
        
        // register Services
        NSApp.servicesProvider = ServicesProvider()
        
        // setup touchbar
        if #available(macOS 10.12.2, *) {
            NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
        
        // raise didFinishLaunching flag
        self.didFinishLaunching = true
    }
    
    
    /// store last version before termination
    func applicationWillTerminate(_ notification: Notification) {
        
        // store latest version
        //   -> The bundle version (build number) format was changed on CotEditor 2.2.0. due to the iTunes Connect versioning rule.
        //       < 2.2.0 : The Semantic Versioning
        //      >= 2.2.0 : Single Integer
        let thisVersion = AppInfo.bundleVersion
        let isLatest: Bool = {
            guard let lastVersion = UserDefaults.standard[.lastVersion] else { return true }
            
            // if isDigit -> probably semver (semver must be older than 2.2.0)
            let isDigit = (lastVersion.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789").inverted) == nil)
            
            return !isDigit || Int(thisVersion)! >= Int(lastVersion)!
        }()
        if isLatest {
            UserDefaults.standard[.lastVersion] = thisVersion
        }
    }
    
    
    /// creates a new blank document
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        if self.didFinishLaunching {
            return UserDefaults.standard[.reopenBlankWindow]
        } else {
            return UserDefaults.standard[.createNewAtStartup]
        }
    }
    
    
    /// drop multiple files
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        
        let isAutomaticTabbing: Bool = {
            if #available(macOS 10.12, *) {
                return (AlphaWindow.userTabbingPreference == .inFullScreen) && (filenames.count > 1)
            }
            return false
        }()
        
        var remainingDocumentCount = filenames.count
        var firstWindowOpened = false
        
        for filename in filenames {
            guard !self.application(sender, openFile: filename) else {
                remainingDocumentCount -= 1
                continue
            }
            
            let url = URL(fileURLWithPath: filename)
            
            DocumentController.shared().openDocument(withContentsOf: url, display: true) { (document, documentWasAlreadyOpen, error) in
                defer {
                    remainingDocumentCount -= 1
                }
                
                if let error = error {
                    NSApp.presentError(error)
                    
                    let cancelled = (error as? CocoaError)?.errorCode == CocoaError.userCancelled.rawValue
                    NSApp.reply(toOpenOrPrint: cancelled ? .cancel : .failure)
                }
                
                // on first window opened
                // -> The first document needs to open a new window.
                if #available(macOS 10.12, *), isAutomaticTabbing, !documentWasAlreadyOpen, document != nil, !firstWindowOpened {
                    AlphaWindow.tabbingPreference = .always
                    firstWindowOpened = true
                }
            }
        }
        
        // reset tabbing setting
        if #available(macOS 10.12, *), isAutomaticTabbing {
            // wait until finish
            while remainingDocumentCount > 0 {
                RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
            }
            
            AlphaWindow.tabbingPreference = nil
        }
    }
    
    
    /// open file
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        
        let url = URL(fileURLWithPath: filename)
        
        // perform install if the file is CotEditor theme file
        guard url.pathExtension == ThemeExtension else { return false }
        
        // ask whether theme file should be opened as a text file
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("“%@” is a CotEditor theme file.", comment: ""), url.lastPathComponent)
        alert.informativeText = NSLocalizedString("Do you want to install this theme?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Install", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Open as Text File", comment: ""))
        
        let returnCode = alert.runModal()
        
        guard returnCode == NSAlertFirstButtonReturn else { return false }  // = Open as Text File
        
        // import theme
        do {
            try ThemeManager.shared.importSetting(fileURL: url)
            
        } catch {
            // ask whether the old theme should be repleced with new one if the same name theme is already exists
            let success = NSApp.presentError(error)
            
            guard success else { return true }  // cancelled
        }
        
        // feedback for succession
        let themeName = ThemeManager.shared.settingName(from: url)
        let feedbackAlert = NSAlert()
        feedbackAlert.messageText = String(format: NSLocalizedString("A new theme named “%@” has been successfully installed.", comment: ""), themeName)
        
        NSSound(named: "Glass")?.play()
        feedbackAlert.runModal()
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// activate self and perform "New" menu action
    @IBAction func newDocumentActivatingApplication(_ sender: Any?) {
        
        NSApp.activate(ignoringOtherApps: true)
        NSDocumentController.shared().newDocument(sender)
    }
    
    
    /// activate self and perform "Open..." menu action
    @IBAction func openDocumentActivatingApplication(_ sender: Any?) {
        
        NSApp.activate(ignoringOtherApps: true)
        NSDocumentController.shared().openDocument(sender)
    }
    
    
    /// show preferences window
    @IBAction func showPreferences(_ sender: Any?) {
        
        PreferencesWindowController.shared.showWindow(sender)
    }
    
    
    /// show console panel
    @IBAction func showConsolePanel(_ sender: Any?) {
        
        ConsolePanelController.shared.showWindow(sender)
    }
    
    
    /// show color code editor panel
    @IBAction func showColorCodePanel(_ sender: Any?) {
        
        ColorCodePanelController.shared.showWindow(sender)
    }
    
    
    /// show editor opacity panel
    @IBAction func showOpacityPanel(_ sender: Any?) {
        
        OpacityPanelController.shared.showWindow(sender)
    }
    
    
    /// show acknowlegements
    @IBAction func showAcknowledgments(_ sender: Any?) {
        
        self.acknowledgmentsWindowController.showWindow(sender)
    }
    
    
    /// open OSAScript dictionary in Script Editor
    @IBAction func openAppleScriptDictionary(_ sender: Any?) {
        
        let appURL = Bundle.main.bundleURL
        
        NSWorkspace.shared().open([appURL], withAppBundleIdentifier: BundleIdentifier.ScriptEditor,
                                  additionalEventParamDescriptor: nil, launchIdentifiers: nil)
    }
    
    
    /// open a specific page in Help contents
    @IBAction func openHelpAnchor(_ sender: AnyObject?) {
        
        guard let tag = sender?.tag, tag < Help.anchors.count else { return }
        
        NSHelpManager.shared().openHelpAnchor(Help.anchors[tag], inBook: AppInfo.helpBookName)
    }
    
    
    /// open web site (coteditor.com) in default web browser
    @IBAction func openWebSite(_ sender: Any?) {
        
        NSWorkspace.shared().open(AppWebURL.website.url)
    }
    
    
    /// open bug report page in default web browser
    @IBAction func reportBug(_ sender: Any?) {
        
        NSWorkspace.shared().open(AppWebURL.issueTracker.url)
    }
    
    
    /// open new bug report window
    @IBAction func createBugReport(_ sender: Any?) {
        
        // load template file
        let url = Bundle.main.url(forResource: "ReportTemplate", withExtension: "md")!
        guard let template = try? String(contentsOf: url) else { return }
        
        // fill template with user environment info
        let report = template
            .replacingOccurrences(of: "%BUNDLE_VERSION%", with: AppInfo.bundleVersion)
            .replacingOccurrences(of: "%SHORT_VERSION%", with: AppInfo.shortVersion)
            .replacingOccurrences(of: "%SYSTEM_VERSION%", with: ProcessInfo.processInfo.operatingSystemVersionString)
        
        // open as document
        guard let document = (try? NSDocumentController.shared().openUntitledDocumentAndDisplay(false)) as? Document else { return }
        document.displayName = NSLocalizedString("Bug Report", comment: "document title")
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: report)
        document.setSyntaxStyle(name: "Markdown")
        document.makeWindowControllers()
        document.showWindows()
    }
    
    
    
    // MARK: Private Methods
    
    /// build encoding menu in the main menu
    @objc private func buildEncodingMenu() {
        
        let menu = self.encodingsMenu!
        
        EncodingManager.shared.updateChangeEncodingMenu(menu)
    }
    
    
    /// build syntax style menu in the main menu
    @objc private func buildSyntaxMenu() {
        
        let menu = self.syntaxStylesMenu!
        
        menu.removeAllItems()
        
        // add None
        menu.addItem(withTitle: BundledStyleName.none, action: #selector(SyntaxHolder.changeSyntaxStyle), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        // add syntax styles
        let styleNames = SyntaxManager.shared.styleNames
        for styleName in styleNames {
            menu.addItem(withTitle: styleName, action: #selector(SyntaxHolder.changeSyntaxStyle), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())
        
        // add item to recolor
        let recolorAction = #selector(SyntaxHolder.recolorAll)
        let shortcut = MenuKeyBindingManager.shared.shortcut(for: recolorAction)
        let recoloritem = NSMenuItem(title: NSLocalizedString("Re-Color All", comment: ""), action: recolorAction, keyEquivalent: shortcut.keyEquivalent)
        recoloritem.keyEquivalentModifierMask = shortcut.modifierMask  // = default: Cmd + Opt + R
        menu.addItem(recoloritem)
    }
    
    
    /// build theme menu in the main menu
     @objc private func buildThemeMenu() {
        
        let menu = self.themesMenu!
        
        menu.removeAllItems()
        
        let themeNames = ThemeManager.shared.themeNames
        for themeName in themeNames {
            menu.addItem(withTitle: themeName, action: #selector(ThemeHolder.changeTheme), keyEquivalent: "")
        }
    }
    
}
