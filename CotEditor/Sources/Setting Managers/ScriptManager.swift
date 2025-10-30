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
import Combine
import Shortcut
import URLUtils

// NSObject-based NSAppleEventDescriptor must be used but not sendable
// -> According to the documentation, NSAppleEventDescriptor is just a wrapper of AEDesc,
//    so seems safe to conform to Sendable. (macOS 12, Xcode 14.0, FB12571431)
extension NSAppleEventDescriptor: @retroactive @unchecked Sendable { }


@MainActor final class ScriptManager: NSObject, NSFilePresenter {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    var menu: NSMenu?  { didSet { Task { await self.updateMenu() } } }
    private(set) var currentScriptName: String?
    
    
    // MARK: Private Properties
    
    private nonisolated static let separator = "-"
    
    private let scriptsDirectoryURL: URL?
    private var scope: String?
    private var scriptHandlersTable: [ScriptingEventType: [any EventScript]] = [:]
    
    private var menuUpdateTask: Task<Void, any Error>?
    
    
    // MARK: Lifecycle
    
    private override init() {
        
        // -> The application scripts folder will be created automatically by the first launch.
        //    In addition, individual applications cannot create its script folder for in case
        //    when user explicitly delete the folder.
        //    cf. https://developer.apple.com/forums/thread/79384
        self.scriptsDirectoryURL = try? URL(for: .applicationScriptsDirectory, in: .userDomainMask)
        
        super.init()
        
        guard self.presentedItemURL != nil else { return }
        
        NSFileCoordinator.addFilePresenter(self)
        
        Task {
            let scopes = (DocumentController.shared as! DocumentController).$currentSyntaxName.values
            for await scope in scopes where scope != self.scope {
                self.scope = scope
                self.applyShortcuts()
            }
        }
    }
    
    
    // MARK: File Presenter Protocol
    
    nonisolated let presentedItemOperationQueue: OperationQueue = .init()
    
    nonisolated var presentedItemURL: URL?  { self.scriptsDirectoryURL }
    
    
    /// Contents of the script folder did change.
    nonisolated func presentedItemDidChange() {
        
        Task { @MainActor in
            self.menuUpdateTask?.cancel()
            self.menuUpdateTask = Task {
                if NSApp.isActive {
                    try await Task.sleep(for: .seconds(0.2), tolerance: .seconds(0.1))
                } else {
                    for await _ in NotificationCenter.default.notifications(named: NSApplication.didBecomeActiveNotification) {
                        return
                    }
                }
                await self.updateMenu()
            }
        }
    }
    
    
    // MARK: Public Methods
    
    /// Dispatches an Apple event that notifies the given document was opened.
    ///
    /// - Parameters:
    ///   - eventType: The event trigger to perform script.
    ///   - documentSpecifier: The script object specifier of the target document.
    func dispatch(event eventType: ScriptingEventType, document documentSpecifier: NSScriptObjectSpecifier) async {
        
        guard let scripts = self.scriptHandlersTable[eventType], !scripts.isEmpty else { return }
        
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(code: "cEd1"),
                                           eventID: eventType.eventID,
                                           targetDescriptor: .currentProcess(),
                                           returnID: AEReturnID(kAutoGenerateReturnID),
                                           transactionID: AETransactionID(kAnyTransactionID))
        
        let documentDescriptor = documentSpecifier.descriptor ?? NSAppleEventDescriptor(string: "BUG: document.objectSpecifier.descriptor was nil")
        event.setParam(documentDescriptor, forKeyword: AEKeyword(keyDirectObject))
        
        await self.dispatch(event, handlers: scripts)
    }
    
    
    // MARK: Action Messages
    
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
    
    /// Builds the Script menu and scan script handlers.
    private func updateMenu() async {
        
        self.menuUpdateTask?.cancel()
        self.menuUpdateTask = nil
        self.scriptHandlersTable.removeAll()
        
        guard let directoryURL = self.scriptsDirectoryURL else { return }
        
        let scriptMenuItems = await Task.detached { Self.scriptMenuItems(at: directoryURL) }.value
        
        let eventScripts = scriptMenuItems.flatMap(\.scripts)
            .compactMap { $0 as? any EventScript }
        for type in ScriptingEventType.allCases {
            self.scriptHandlersTable[type] = eventScripts.filter { $0.eventTypes.contains(type) }
        }
        
        let menuItems = scriptMenuItems.map { $0.menuItem(action: #selector(launchScript), target: self) }
        
        let openMenuItem = NSMenuItem(title: String(localized: "Open Scripts Folder", table: "MainMenu"),
                                      systemImage: "folder",
                                      action: #selector(openScriptFolder))
        openMenuItem.target = self
        
        self.menu?.items = menuItems + [.separator(), openMenuItem]
        self.applyShortcuts()
    }
    
    
    /// Presents the given error in the ordinary way by taking the error type in the consideration.
    ///
    /// - Parameters:
    ///   - error: The error to present.
    ///   - scriptName: The name of script.
    private static func presentError(_ error: some Error, scriptName: String) {
        
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
        
        await withTaskGroup { group in
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
    private nonisolated static func scriptMenuItems(at directoryURL: URL) -> [ScriptMenuItem] {
        
        guard let urls = try? FileManager.default
            .contentsOfDirectory(at: directoryURL,
                                 includingPropertiesForKeys: [.contentTypeKey, .isExecutableKey],
                                 options: [.skipsHiddenFiles])
        else { return [] }
        
        return urls
            .filter { !$0.lastPathComponent.hasPrefix("_") }  // ignore files/folders of which name starts with "_"
            .sorted(using: KeyPathComparator(\.lastPathComponent))
            .compactMap { url in
                let name = url.deletingPathExtension().lastPathComponent
                    .replacing(/^\d+\)/.asciiOnlyDigits(), with: "", maxReplacements: 1)  // remove ordering prefix
                
                return if name == Self.separator {
                    .separator
                } else if let script = try? ScriptDescriptor(contentsOf: url, name: name)?.makeScript() {
                    // -> Check script possibility before folder because a script can be a directory, e.g. .scptd.
                    .script(script.name, script)
                } else if url.hasDirectoryPath {
                    .folder(name, Self.scriptMenuItems(at: url))
                } else {
                    nil
                }
            }
    }
    
    
    /// Applies the keyboard shortcuts to the Script menu items.
    private func applyShortcuts() {
        
        guard let menu else { return assertionFailure() }
        
        // clear all shortcuts
        menu.items.forEach { $0.removeAllShortcuts() }
        
        // apply shortcuts for prioritized domain
        let usedShortcuts = if let scope = self.scope, let submenu = menu.item(withTitle: scope)?.submenu {
            submenu.items.flatMap { $0.applyShortcut(recursively: true) }
        } else {
            menu.items.flatMap { $0.applyShortcut(recursively: false) }
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
    case folder(_ name: String, _ items: [Self])
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
