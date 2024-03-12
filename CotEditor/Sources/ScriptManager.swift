//
//  ScriptManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-03-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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
import Combine

// NSObject-based NSAppleEventDescriptor must be used but not sendable
// -> According to the documentation, NSAppleEventDescriptor is just a wrapper of AEDesc,
//    so seems safe to conform to Sendable. (macOS 12, Xcode 14.0)
extension NSAppleEventDescriptor: @unchecked Sendable { }
extension NSScriptObjectSpecifier: @unchecked Sendable { }


final class ScriptManager: NSObject, NSFilePresenter, @unchecked Sendable {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    @MainActor private(set) var currentScriptName: String?
    
    
    // MARK: Private Properties
    
    private var scriptsDirectoryURL: URL?
    private var currentContext: String?  { didSet { Task { await self.applyShortcuts() } } }
    @Atomic private var scriptHandlersTable: [ScriptingEventType: [any EventScript]] = [:]
    
    private var debounceTask: Task<Void, any Error>?
    private var syntaxObserver: AnyCancellable?
    
    
    
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
        
        self.syntaxObserver = (DocumentController.shared as! DocumentController).$currentSyntaxName
            .removeDuplicates()
            .sink { [unowned self] styleName in Task { @MainActor in self.currentContext = styleName } }
    }
    
    
    deinit {
        if self.presentedItemURL != nil {
            NSFileCoordinator.removeFilePresenter(self)
        }
    }
    
    
    
    // MARK: File Presenter Protocol
    
    let presentedItemOperationQueue: OperationQueue = .init()
    
    var presentedItemURL: URL?  { self.scriptsDirectoryURL }
    
    
    /// Contents of the script folder did change.
    func presentedItemDidChange() {
        
        self.debounceTask?.cancel()
        self.debounceTask = Task.detached { [weak self] in
            if await NSApp.isActive {
                try await Task.sleep(for: .seconds(0.2), tolerance: .seconds(0.1))
                await self?.buildScriptMenu()
                
            } else {
                for await _ in await NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                    try Task.checkCancellation()
                    await self?.buildScriptMenu()
                    return
                }
            }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Script menu for context menu.
    @MainActor var contextualMenu: NSMenu? {
        
        let items = self.scriptMenu!.items
            .filter { $0.action != #selector(openScriptFolder) }
        
        guard items.contains(where: { !$0.isSeparatorItem }) else { return nil }
        
        let menu = NSMenu()
        menu.items = items.map { $0.copy() as! NSMenuItem }
        
        return menu
    }
    
    
    /// Starts observing the scripts directory.
    ///
    /// This method should be called only once.
    func observeScriptsDirectory() {
        
        assert(self.scriptsDirectoryURL == nil)
        
        Task.detached {
            // -> The application scripts folder will be created automatically by the first launch.
            //    In addition, individual applications cannot create its script folder for in case
            //    when user explicitly delete the folder.
            //    cf. https://developer.apple.com/forums/thread/79384
            self.scriptsDirectoryURL = try? URL(for: .applicationScriptsDirectory, in: .userDomainMask)
            
            // observe script folder change if it exists
            if self.presentedItemURL != nil {
                NSFileCoordinator.addFilePresenter(self)
            }
            
            await self.buildScriptMenu()
        }
    }
    
    
    /// Dispatches an Apple event that notifies the given document was opened.
    ///
    /// - Parameters:
    ///   - eventType: The event trigger to perform script.
    ///   - documentSpecifier: The script object specifier of the target document.
    func dispatch(event eventType: ScriptingEventType, document documentSpecifier: NSScriptObjectSpecifier) {
        
        guard
            let scripts = self.scriptHandlersTable[eventType],
            !scripts.isEmpty
        else { return }
        
        // Create an Apple event caused by the given `Document`.
        let documentDescriptor = documentSpecifier.descriptor ?? NSAppleEventDescriptor(string: "BUG: document.objectSpecifier.descriptor was nil")
        let event = NSAppleEventDescriptor(eventClass: "cEd1",
                                           eventID: eventType.eventID,
                                           targetDescriptor: nil,
                                           returnID: AEReturnID(kAutoGenerateReturnID),
                                           transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(documentDescriptor, forKeyword: keyDirectObject)
        
        Task {
            await self.dispatch(event, handlers: scripts)
        }
    }
    
    
    
    // MARK: Action Message
    
    /// Launches a script (invoked by menu item).
    @IBAction func launchScript(_ sender: NSMenuItem) {
        
        guard let script = sender.representedObject as? any Script else { return assertionFailure() }
        
        Task {
            do {
                // change behavior if modifier key is pressed
                switch NSEvent.modifierFlags {
                    case [.option]:  // open
                        guard NSWorkspace.shared.open(script.url) else {
                            throw ScriptFileError(.open, url: script.url)
                        }
                        
                    case [.option, .shift]:  // reveal
                        guard script.url.isReachable else {
                            throw ScriptFileError(.existence, url: script.url)
                        }
                        NSWorkspace.shared.activateFileViewerSelecting([script.url])
                        
                    default:  // execute
                        self.currentScriptName = script.name
                        try await script.run()
                        if self.currentScriptName == script.name {
                            self.currentScriptName = nil
                        }
                }
                
            } catch {
                Self.presentError(error, scriptName: script.name)
            }
        }
    }
    
    
    /// Opens the Script menu folder in the Finder.
    @IBAction func openScriptFolder(_ sender: Any?) {
        
        guard let directoryURL = self.scriptsDirectoryURL else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([directoryURL])
    }
    
    
    
    // MARK: Private Methods
    
    /// The Scripts menu in the main menu.
    @MainActor private var scriptMenu: NSMenu? {
        
        NSApp.mainMenu?.item(at: MainMenu.script.rawValue)?.submenu
    }
    
    
    /// Builds the Script menu and scan script handlers.
    @MainActor private func buildScriptMenu() async {
        
        self.debounceTask?.cancel()
        self.$scriptHandlersTable.mutate { $0.removeAll() }
        
        guard let directoryURL = self.scriptsDirectoryURL else { return }
        
        let scriptMenuItems = await Task.detached { Self.scriptMenuItems(at: directoryURL) }
            .value
        
        let eventScripts = scriptMenuItems.flatMap(\.scripts)
            .compactMap { $0 as? any EventScript }
        for type in ScriptingEventType.allCases {
            self.$scriptHandlersTable.mutate {
                $0[type] = eventScripts.filter { $0.eventTypes.contains(type) }
            }
        }
        
        let menuItems = scriptMenuItems.map { $0.menuItem(action: #selector(launchScript), target: self) }
        
        let openMenuItem = NSMenuItem(title: String(localized: "Open Scripts Folder", table: "MainMenu"),
                                      action: #selector(openScriptFolder), keyEquivalent: "")
        openMenuItem.target = self
        
        self.scriptMenu?.items = menuItems + [.separator(), openMenuItem]
        self.applyShortcuts()
    }
    
    
    /// Presents the given error in the ordinary way by taking the error type in the consideration.
    ///
    /// - Parameters:
    ///   - error: The error to present.
    ///   - scriptName: The name of script.
    @MainActor private static func presentError(_ error: some Error, scriptName: String) {
        
        switch error {
            case is ScriptError:
                let log = Console.Log(message: error.localizedDescription, title: scriptName)
                ConsolePanelController.shared.append(log: log)
                ConsolePanelController.shared.showWindow(nil)
            default:
                NSApp.presentError(error)
        }
    }
    
    
    /// Causes the given Apple event to be dispatched to AppleScripts at given URLs.
    ///
    /// - Parameters:
    ///   - event: The Apple event to be dispatched.
    ///   - scripts: AppleScripts handling the given Apple event.
    private func dispatch(_ event: NSAppleEventDescriptor, handlers scripts: [any EventScript]) async {
        
        await withTaskGroup(of: Void.self) { group in
            for script in scripts {
                group.addTask {
                    do {
                        try await script.run(withAppleEvent: event)
                    } catch {
                        await Self.presentError(error, scriptName: script.name)
                    }
                }
            }
        }
    }
    
    
    /// Reads files recursively and creates menu items.
    ///
    /// - Parameters:
    ///   - directoryURL: The directory where to find files recursively.
    /// - Returns: An array of `ScriptMenuItem` that represents scripts.
    private static func scriptMenuItems(at directoryURL: URL) -> [ScriptMenuItem] {
        
        guard let urls = try? FileManager.default
            .contentsOfDirectory(at: directoryURL,
                                 includingPropertiesForKeys: [.contentTypeKey, .isDirectoryKey, .isExecutableKey],
                                 options: [.skipsHiddenFiles])
        else { return [] }
        
        return urls
            .filter { !$0.lastPathComponent.hasPrefix("_") }  // ignore files/folders of which name starts with "_"
            .sorted(\.lastPathComponent)
            .compactMap { url in
                let name = url.deletingPathExtension().lastPathComponent
                    .replacing(/^\d+\)/.asciiOnlyDigits(), with: "", maxReplacements: 1)  // remove ordering prefix
                
                if name == .separator {
                    return .separator
                    
                } else if let descriptor = ScriptDescriptor(contentsOf: url, name: name),
                          let script = try? descriptor.makeScript()
                {
                    // -> Check script possibility before folder because a script can be a directory, e.g. .scptd.
                    return .script(script.name, script)
                    
                } else if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    let items = Self.scriptMenuItems(at: url)
                    return .folder(name, items)
                }
                
                return nil
            }
    }
    
    
    /// Applies the keyboard shortcuts to the Script menu items.
    @MainActor private func applyShortcuts() {
        
        guard let menu = self.scriptMenu else { return assertionFailure() }
        
        // clear all shortcuts
        menu.items.forEach { $0.removeAllShortcuts() }
        
        // apply shortcuts for prioritized domain
        let usedShortcuts: [Shortcut]
        if let context = self.currentContext, let submenu = menu.item(withTitle: context)?.submenu {
            usedShortcuts = submenu.items.flatMap { $0.applyShortcut(recursively: true) }
        } else {
            usedShortcuts = menu.items.flatMap { $0.applyShortcut(recursively: false) }
        }
        
        // apply shortcuts for the rest
        menu.items.forEach { $0.applyShortcut(recursively: true, exclude: usedShortcuts) }
    }
}



private extension NSMenuItem {
    
    /// Removes all keyboard shortcuts recursively.
    func removeAllShortcuts() {
        
        self.shortcut = nil
        self.submenu?.items.forEach { $0.removeAllShortcuts() }
    }
    
    
    /// Applies the keyboard shortcut determined in `Script` struct stored in the receiver's `.representedObject`.
    ///
    /// - Parameters:
    ///   - recursively: When `true`, apply shortcuts also to the menu items in the `submenu` recursively.
    ///   - exclude: The list of shortcuts not to apply.
    /// - Returns: The shortcuts actually applied.
    @discardableResult
    func applyShortcut(recursively: Bool, exclude: [Shortcut] = []) -> [Shortcut] {
        
        guard self.keyEquivalent.isEmpty else { return [] }
        
        if let script = self.representedObject as? any Script {
            guard
                let shortcut = script.shortcut,
                !exclude.contains(shortcut)
            else { return [] }
            
            self.shortcut = shortcut
            
            return [shortcut]
            
        } else if recursively, let submenu = self.submenu {
            return submenu.items.flatMap { $0.applyShortcut(recursively: true, exclude: exclude) }
            
        } else {
            return []
        }
    }
}


private enum ScriptMenuItem: Sendable {
    
    case script(_ name: String, _ script: any Script)
    case folder(_ name: String, _ items: [ScriptMenuItem])
    case separator
    
    
    /// Creates NSMenuItem instance from ScriptMenuItem.
    ///
    /// - Parameters:
    ///   - action: The action selector to launch the script.
    ///   - target: The action target to launch the script.
    /// - Returns: An NSMenuItem.
    func menuItem(action: Selector, target: AnyObject?) -> NSMenuItem {
        
        switch self {
            case .script(let name, let script):
                let item = NSMenuItem(title: name, action: action, keyEquivalent: "")
                // -> Shortcut will be applied later in `applyShortcuts()`.
                item.representedObject = script
                item.target = target
                item.toolTip = String(localized: "Option-click to open script in editor.", table: "MainMenu",
                                      comment: "tooltip for script menu item")
                return item
                
            case .folder(let name, let items):
                let menu = NSMenu(title: name)
                menu.items = items.map { $0.menuItem(action: action, target: target) }
                let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
                item.submenu = menu
                return item
                
            case .separator:
                return .separator()
        }
    }
    
    
    /// All scripts including the scripts in the child folders.
    var scripts: [any Script] {
        
        switch self {
            case .script(_, let script):
                [script]
                
            case .folder(_, let items):
                items.flatMap(\.scripts)
                
            case .separator:
                []
        }
    }
}
