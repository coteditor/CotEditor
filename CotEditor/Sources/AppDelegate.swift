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

enum MainMenuIndex: Int {
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
}


enum AppWebURL: String {
    case website = "https://coteditor.com"
    case issueTracker = "https://github.com/coteditor/CotEditor/issues"
    
    var url: URL {
        return URL(string: self.rawValue)!
    }
}


struct Help {
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


// MARK:

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: Public Properties
    
    var migrationWindowController: NSWindowController?  // for extension
    
    
    // MARK: Private Properties
    
    private var didFinishLaunching = false
    private var acknowledgementsWindowController: WebDocumentWindowController?
    
    @IBOutlet private weak var encodingsMenu: NSMenu?
    @IBOutlet private weak var syntaxStylesMenu: NSMenu?
    @IBOutlet private weak var themesMenu: NSMenu?
    
    
    
    // MARK:
    // MARK: Creation
    
    override init() {
        
        // register default setting values
        UserDefaults.standard().register(DefaultSettings)
        NSUserDefaultsController.shared().initialValues = DefaultSettings
        
        // register transformers
        ValueTransformer.setValueTransformer(HexColorTransformer(), forName: "HexColorTransformer" as ValueTransformerName)
        
        super.init()
    }
    
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
    
    
    
    /// setup UI
    override func awakeFromNib() {
        
        // store key bindings in MainMenu.xib before menu is modified
        CEMenuKeyBindingManager.shared().scanDefaultMenuKeyBindings()
        
        // build menus
        self.buildEncodingMenu()
        self.buildSyntaxMenu()
        self.buildThemeMenu()
        CEScriptManager.shared().buildScriptMenu(self)
        
        // observe setting list updates
        NotificationCenter.default().addObserver(self, selector: #selector(buildEncodingMenu), name: .CEEncodingListDidUpdate, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(buildSyntaxMenu), name: .CESyntaxListDidUpdate, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(buildThemeMenu), name: .CEThemeListDidUpdate, object: nil)
    }
    
    
    
    // MARK: Application Delegate
    
    /// creates a new document on launch?
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        if self.didFinishLaunching {
            return UserDefaults.standard().bool(forKey: CEDefaultCreateNewAtStartupKey)
        }
        
        return true
    }
    
    
    /// crates a new document on "Re-Open" AppleEvent
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if UserDefaults.standard().bool(forKey: CEDefaultReopenBlankWindowKey) {
            return true
        }
        
        return flag
    }
    
    
    #if APPSTORE
    #else
    /// setup Sparkle framework
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        // setup updater
        UpdaterManager.shared.setup()
    }
    #endif
    
    
    /// just after application did launch
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // setup KeyBindingManager
        CEMenuKeyBindingManager.shared().applyKeyBindingsToMainMenu()
        
        // migrate user settings if needed
        self.migrateIfNeeded()
        
        // store latest version
        //   -> The bundle version (build number) format was changed on CotEditor 2.2.0. due to the iTunes Connect versioning rule.
        //       < 2.2.0 : The Semantic Versioning
        //      >= 2.2.0 : Single Integer
        var isLatest = true
        let thisVersion = AppInfo.bundleVersion
        if let lastVersion = UserDefaults.standard().string(forKey: CEDefaultLastVersionKey) {
            // if isDigit -> probably semver (semver must be older than 2.2.0)
            let isDigit = (lastVersion.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789").inverted) != nil)
            
            if isDigit && Int(thisVersion) < Int(lastVersion) {
                isLatest = false
            }
        }
        if isLatest {
            UserDefaults.standard().set(thisVersion, forKey: CEDefaultLastVersionKey)
        }
        
        // register Services
        NSApp.servicesProvider = ServicesProvider()
        
        // raise didFinishLaunching flag
        self.didFinishLaunching = true
    }
    
    
    /// open file
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        
        let url = URL(fileURLWithPath: filename)
        
        // perform install if the file is CotEditor theme file
        guard url.pathExtension == CEThemeExtension else { return false }
        
        // ask whether theme file should be opened as a text file
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("“%@” is a CotEditor theme file.", comment: ""), url.lastPathComponent!)
        alert.informativeText = NSLocalizedString("Do you want to install this theme?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Install", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Open as Text File", comment: ""))
        
        let returnCode = alert.runModal()
        
        guard returnCode == NSAlertFirstButtonReturn else { return false }  // = Open as Text File
        
        // import theme
        var success = true
        do {
            try CEThemeManager.shared().importSetting(withFileURL: url)
            
        } catch let error as NSError {
            // ask whether the old theme should be repleced with new one if the same name theme is already exists
            success = NSApp.presentError(error)
        }
        
        // feedback for succession
        if success {
            let themeName = CEThemeManager.shared().settingName(from: url)
            let alert = NSAlert()
            alert.messageText = String(format: NSLocalizedString("A new theme named “%@” has been successfully installed.", comment: ""), themeName)
            
            NSSound(named: "Glass")?.play()
            alert.runModal()
        }
        
        return true
    }
    
    
    
    // MARK: Action Messages
    
    /// activate self and perform "New" menu action
    @IBAction func newInDockMenu(_ sender: AnyObject?) {
        
        NSApp.activateIgnoringOtherApps(true)
        NSDocumentController.shared().newDocument(sender)
    }
    
    
    /// activate self and perform "Open..." menu action
    @IBAction func openInDockMenu(_ sender: AnyObject?) {
        
        NSApp.activateIgnoringOtherApps(true)
        NSDocumentController.shared().openDocument(sender)
    }
    
    
    /// Show console panel
    @IBAction func showPreferences(_ sender: AnyObject?) {
        
        PreferencesWindowController.shared.showWindow(sender)
    }
    
    
    /// Show console panel
    @IBAction func showConsolePanel(_ sender: AnyObject?) {
        
        ConsolePanelController.shared.showWindow(sender)
    }
    
    
    /// show color code editor panel
    @IBAction func showColorCodePanel(_ sender: AnyObject?) {
        
        CEColorCodePanelController.shared().showWindow(sender)
    }
    
    
    /// show editor opacity panel
    @IBAction func showOpacityPanel(_ sender: AnyObject?) {
        
        CEOpacityPanelController.shared().showWindow(sender)
    }
    
    
    /// show acknowlegements
    @IBAction func showAcknowledgements(_ sender: AnyObject?) {
        
        if self.acknowledgementsWindowController == nil {
            self.acknowledgementsWindowController = WebDocumentWindowController(documentName: "Acknowledgements")
        }
        
        self.acknowledgementsWindowController?.showWindow(sender)
    }
    
    
    /// open OSAScript dictionary in Script Editor
    @IBAction func openAppleScriptDictionary(_ sender: AnyObject?) {
        
        let appURL = Bundle.main().bundleURL
        let scriptEditorIdentifier = "com.apple.ScriptEditor2"
        
        NSWorkspace.shared().open([appURL], withAppBundleIdentifier: scriptEditorIdentifier,
                                  options: [], additionalEventParamDescriptor: nil, launchIdentifiers: nil)
    }
    
    
    /// open a specific page in Help contents
    @IBAction func openHelpAnchor(_ sender: AnyObject?) {
        
        guard let tag = sender?.tag where tag < Help.anchors.count else { return }
        
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
        let url = Bundle.main().urlForResource("ReportTemplate", withExtension: "md")!
        guard var template = try? String(contentsOf: url) else { return }
        
        // fill template with user environment info
        template = template.replacingOccurrences(of: "%BUNDLE_VERSION%", with: AppInfo.bundleVersion)
        template = template.replacingOccurrences(of: "%SHORT_VERSION%", with: AppInfo.shortVersion)
        template = template.replacingOccurrences(of: "%SYSTEM_VERSION%", with: ProcessInfo.processInfo().operatingSystemVersionString)
        
        // open as document
        guard let document = (try? NSDocumentController.shared().openUntitledDocumentAndDisplay(false)) as? CEDocument else { return }
        document.displayName = NSLocalizedString("Bug Report", comment: "document title")
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: template)
        document.setSyntaxStyleWithName("Markdown")
        document.makeWindowControllers()
        document.showWindows()
    }
    
    
    // MARK: Private Methods
    
    /// build encoding menu in the main menu
    func buildEncodingMenu() {
        
        guard let menu = self.encodingsMenu else { return }
        
        CEEncodingManager.shared().updateChangeEncoding(menu)
    }
    
    
    /// build syntax style menu in the main menu
    func buildSyntaxMenu() {
        
        guard let menu = self.syntaxStylesMenu else { return }
        
        menu.removeAllItems()
        
        // add None
        menu.addItem(withTitle: NSLocalizedString("None", comment: ""), action: #selector(CESyntaxHolder.changeSyntaxStyle(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        // add syntax styles
        let styleNames = CESyntaxManager.shared().styleNames
        for styleName in styleNames {
            menu.addItem(withTitle: styleName, action: #selector(CESyntaxHolder.changeSyntaxStyle(_:)), keyEquivalent: "")
        }
        menu.addItem(NSMenuItem.separator())
        
        // add item to recolor
        let recolorAction = #selector(CESyntaxHolder.recolorAll(_:))
        var modifierMask = NSEventModifierFlags()
        let keyEquivalent = CEMenuKeyBindingManager.shared().keyEquivalent(forAction: recolorAction, modifierMask: &modifierMask)
        let recoloritem = NSMenuItem(title: NSLocalizedString("Re-Color All", comment: ""), action: recolorAction, keyEquivalent: keyEquivalent)
        recoloritem.keyEquivalentModifierMask = modifierMask // = default: Cmd + Opt + R
        menu.addItem(recoloritem)
    }
    
    
    /// build theme menu in the main menu
     func buildThemeMenu() {
        
        guard let menu = self.themesMenu else { return }
        
        menu.removeAllItems()
        
        let themeNames = CEThemeManager.shared().themeNames
        for themeName in themeNames {
            menu.addItem(withTitle: themeName, action: #selector(CEThemeHolder.changeTheme(_:)), keyEquivalent: "")
        }
    }
    
}
