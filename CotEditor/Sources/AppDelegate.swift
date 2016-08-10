/*
 
 AppDelegate.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-13.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2013-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

enum MainMenu: Int {
    
    case application
    case file
    case edit
    case view
    case format
    case text
    case find
    case window
    case script
    case help
    
    
    enum MenuItemTag: Int {
        case services = 999  // not to list up in "Menu Key Bindings" setting
        case sharingService = 1999
        case scriptDirectory = 8999  // not to list up in "Menu Key Bindings" setting
    }
    
    
    var menu: NSMenu? {
        
        return NSApp.mainMenu?.item(at: self.rawValue)?.submenu
    }
}


private struct Help {
    
    static let anchors = [
        "releasenotes",
        "pref_general",
        "pref_window",
        "pref_appearance",
        "pref_edit",
        "pref_format",  // 5
        "pref_filedrop",
        "pref_keybindings",
        "pref_print",
        "whats_new",
        "specification_changes",  // 10
        "howto_customize_scriptmenu",
        "about_applescript",
        "about_unixscript",
        "pref_integration",
        "about_file_mapping",  // 15
        "about_cot",
        "about_syntaxstyle",
        "about_comment_settings",
        "about_outlinemenu_settings",
        "about_complist_settings",  // 20
        "about_file_mapping",
        "about_styleinfo_settings",
    ]
}


// constants
private let ScriptEditorIdentifier = "com.apple.ScriptEditor2"


// MARK:

@NSApplicationMain
final class AppDelegate: NSResponder, NSApplicationDelegate {
    
    // MARK: Enums
    
    private enum AppWebURL: String {
        case website = "https://coteditor.com"
        case issueTracker = "https://github.com/coteditor/CotEditor/issues"
        
        var url: URL {
            return URL(string: self.rawValue)!
        }
    }
    
    
    // MARK: Public Properties
    
    var migrationWindowController: NSWindowController?  // for extension
    
    
    // MARK: Private Properties
    
    private var didFinishLaunching = false
    private lazy var acknowledgementsWindowController = WebDocumentWindowController(documentName: "Acknowledgements")!
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxStylesMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        // register default setting values
        var defaults: [String: AnyObject] = [:]
        for (key, value) in DefaultSettings {
            defaults[key.rawValue] = value
        }
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared().initialValues = defaults
        
        // wake text finder up
        _ = TextFinder.shared
        
        // register transformers
        ValueTransformer.setValueTransformer(HexColorTransformer(), forName: "HexColorTransformer" as NSValueTransformerName)
        
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
        ScriptManager.shared.buildScriptMenu(self)
        
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
        
        // migrate user settings if needed
        self.migrateIfNeeded()
        
        // store latest version
        //   -> The bundle version (build number) format was changed on CotEditor 2.2.0. due to the iTunes Connect versioning rule.
        //       < 2.2.0 : The Semantic Versioning
        //      >= 2.2.0 : Single Integer
        let thisVersion = AppInfo.bundleVersion
        let isLatest: Bool = {
            guard let lastVersion = Defaults[.lastVersion] else { return true }
            
            // if isDigit -> probably semver (semver must be older than 2.2.0)
            let isDigit = (lastVersion.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789").inverted) != nil)
            
            return !isDigit || Int(thisVersion) >= Int(lastVersion)
        }()
        if isLatest {
            Defaults[.lastVersion] = thisVersion
        }
        
        // register Services
        NSApp.servicesProvider = ServicesProvider()
        
        // raise didFinishLaunching flag
        self.didFinishLaunching = true
    }
    
    
    /// creates a new blank document
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        if self.didFinishLaunching {
            return Defaults[.reopenBlankWindow]
        } else {
            return Defaults[.createNewAtStartup]
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
            
        } catch let error {
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
    @IBAction func newDocumentActivatingApplication(_ sender: AnyObject?) {
        
        NSApp.activateIgnoringOtherApps(true)
        NSDocumentController.shared().newDocument(sender)
    }
    
    
    /// activate self and perform "Open..." menu action
    @IBAction func openDocumentActivatingApplication(_ sender: AnyObject?) {
        
        NSApp.activateIgnoringOtherApps(true)
        NSDocumentController.shared().openDocument(sender)
    }
    
    
    /// Show preferences window
    @IBAction func showPreferences(_ sender: AnyObject?) {
        
        PreferencesWindowController.shared.showWindow(sender)
    }
    
    
    /// Show console panel
    @IBAction func showConsolePanel(_ sender: AnyObject?) {
        
        ConsolePanelController.shared.showWindow(sender)
    }
    
    
    /// show color code editor panel
    @IBAction func showColorCodePanel(_ sender: AnyObject?) {
        
        ColorCodePanelController.shared.showWindow(sender)
    }
    
    
    /// show editor opacity panel
    @IBAction func showOpacityPanel(_ sender: AnyObject?) {
        
        OpacityPanelController.shared.showWindow(sender)
    }
    
    
    /// show acknowlegements
    @IBAction func showAcknowledgements(_ sender: AnyObject?) {
        
        self.acknowledgementsWindowController.showWindow(sender)
    }
    
    
    /// open OSAScript dictionary in Script Editor
    @IBAction func openAppleScriptDictionary(_ sender: AnyObject?) {
        
        let appURL = Bundle.main.bundleURL
        
        NSWorkspace.shared().open([appURL], withAppBundleIdentifier: ScriptEditorIdentifier,
                                  additionalEventParamDescriptor: nil, launchIdentifiers: nil)
    }
    
    
    /// open a specific page in Help contents
    @IBAction func openHelpAnchor(_ sender: AnyObject?) {
        
        guard let tag = sender?.tag, tag < Help.anchors.count else { return }
        
        NSHelpManager.shared().openHelpAnchor(Help.anchors[tag], inBook: AppInfo.helpBookName)
    }
    
    
    /// open web site (coteditor.com) in default web browser
    @IBAction func openWebSite(_ sender: AnyObject?) {
        
        NSWorkspace.shared().open(AppWebURL.website.url)
    }
    
    
    /// open bug report page in default web browser
    @IBAction func reportBug(_ sender: AnyObject?) {
        
        NSWorkspace.shared().open(AppWebURL.issueTracker.url)
    }
    
    
    /// open new bug report window
    @IBAction func createBugReport(_ sender: AnyObject?) {
        
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
    func buildEncodingMenu() {
        
        let menu = self.encodingsMenu!
        
        EncodingManager.shared.updateChangeEncodingMenu(menu)
    }
    
    
    /// build syntax style menu in the main menu
    func buildSyntaxMenu() {
        
        let menu = self.syntaxStylesMenu!
        
        menu.removeAllItems()
        
        // add None
        menu.addItem(withTitle: BundledStyleName.none, action: #selector(SyntaxHolder.changeSyntaxStyle(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        // add syntax styles
        let styleNames = SyntaxManager.shared.styleNames
        for styleName in styleNames {
            menu.addItem(withTitle: styleName, action: #selector(SyntaxHolder.changeSyntaxStyle(_:)), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())
        
        // add item to recolor
        let recolorAction = #selector(SyntaxHolder.recolorAll(_:))
        let shortcut = MenuKeyBindingManager.shared.shortcut(for: recolorAction)
        let recoloritem = NSMenuItem(title: NSLocalizedString("Re-Color All", comment: ""), action: recolorAction, keyEquivalent: shortcut.keyEquivalent)
        recoloritem.keyEquivalentModifierMask = shortcut.modifierMask // = default: Cmd + Opt + R
        menu.addItem(recoloritem)
    }
    
    
    /// build theme menu in the main menu
     func buildThemeMenu() {
        
        let menu = self.themesMenu!
        
        menu.removeAllItems()
        
        let themeNames = ThemeManager.shared.themeNames
        for themeName in themeNames {
            menu.addItem(withTitle: themeName, action: #selector(ThemeHolder.changeTheme(_:)), keyEquivalent: "")
        }
    }
    
}
