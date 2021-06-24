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
//  © 2014-2021 1024jp
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

final class ScriptManager: NSObject, NSFilePresenter {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    @Atomic private(set) var currentScriptName: String?
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL?
    private var scriptHandlersTable: [ScriptingEventType: [EventScript]] = [:]
    
    private lazy var menuBuildingTask = Debouncer(delay: .milliseconds(200)) { [weak self] in self?.buildScriptMenu() }
    private var applicationObserver: AnyCancellable?
    private var terminationObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        do {
            self.scriptsDirectoryURL = try FileManager.default.url(for: .applicationScriptsDirectory,
                                                                   in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            assertionFailure("cannot create the scripts folder: \(error.localizedDescription)")
            self.scriptsDirectoryURL = nil
        }
        
        self.presentedItemURL = self.scriptsDirectoryURL
        
        super.init()
        
        // observe script folder change
        NSFileCoordinator.addFilePresenter(self)
        self.terminationObserver = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [unowned self] _ in NSFileCoordinator.removeFilePresenter(self) }
    }
    
    
    
    // MARK: File Presenter Protocol
    
    let presentedItemOperationQueue: OperationQueue = .main
    
    let presentedItemURL: URL?
    
    
    /// script folder did change
    func presentedSubitemDidChange(at url: URL) {
        
        if NSApp.isActive {
            self.menuBuildingTask.schedule()
            
        } else {
            self.applicationObserver = NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification, object: NSApp)
                .receive(on: DispatchQueue.main)
                .first()
                .sink { [weak self] _ in self?.menuBuildingTask.perform() }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Menu for context menu.
    var contexualMenu: NSMenu? {
        
        let items = MainMenu.script.menu!.items
            .filter { $0.action != #selector(openScriptFolder) }
            .map { $0.copy() as! NSMenuItem }
        
        guard !items.isEmpty else { return nil }
        
        let menu = NSMenu()
        menu.items = items
        
        return menu
    }
    
    
    /// Build the Script menu.
    func buildScriptMenu() {
        
        assert(Thread.isMainThread)
        
        self.menuBuildingTask.cancel()
        self.scriptHandlersTable.removeAll()
        
        guard let directoryURL = self.scriptsDirectoryURL else { return assertionFailure() }
        
        let menu = MainMenu.script.menu!
        
        menu.removeAllItems()
        
        self.addChildFileItem(in: directoryURL, to: menu)
        
        if !menu.items.isEmpty {
            menu.addItem(.separator())
        }
        
        let openMenuItem = NSMenuItem(title: "Open Scripts Folder".localized,
                                      action: #selector(openScriptFolder), keyEquivalent: "")
        openMenuItem.target = self
        menu.addItem(openMenuItem)
    }
    
    
    /// Dispatch an Apple Event that notifies the given document was opened.
    ///
    /// - Parameter document: The document that was opened.
    func dispatchEvent(documentOpened document: Document) {
        
        let eventType = ScriptingEventType.documentOpened
        
        guard let scripts = self.scriptHandlersTable[eventType], !scripts.isEmpty else { return }
        
        let event = self.createEvent(by: document, eventID: eventType.eventID)
        
        self.dispatch(event, handlers: scripts)
    }
    
    
    /// Dispatch an Apple Event that notifies the given document was opened.
    ///
    /// - Parameter document: The document that was opened.
    func dispatchEvent(documentSaved document: Document) {
        
        let eventType = ScriptingEventType.documentSaved
        
        guard let scripts = self.scriptHandlersTable[eventType], !scripts.isEmpty else { return }
        
        let event = self.createEvent(by: document, eventID: eventType.eventID)
        
        self.dispatch(event, handlers: scripts)
    }
    
    
    
    // MARK: Action Message
    
    /// launch script (invoked by menu item)
    @IBAction func launchScript(_ sender: NSMenuItem) {
        
        guard let script = sender.representedObject as? Script else { return assertionFailure() }
        
        do {
            // change behavior if modifier key is pressed
            switch NSEvent.modifierFlags {
                case [.option]:  // open
                    guard NSWorkspace.shared.open(script.url) else {
                        throw ScriptFileError(kind: .open, url: script.url)
                    }
                
                case [.option, .shift]:  // reveal
                    guard script.url.isReachable else {
                        throw ScriptFileError(kind: .existance, url: script.url)
                    }
                    NSWorkspace.shared.activateFileViewerSelecting([script.url])
                
                default:  // execute
                    self.currentScriptName = script.name
                    try script.run { [weak self] (error) in
                        if let error = error {
                            Console.shared.show(message: error.localizedDescription, title: script.name)
                        }
                        if self?.currentScriptName == script.name {
                            self?.currentScriptName = nil
                        }
                    }
            }
            
        } catch {
            NSApp.presentError(error)
        }
    }
    
    
    /// open Script menu folder in Finder
    @IBAction func openScriptFolder(_ sender: Any?) {
        
        guard let dicrectoryURL = self.scriptsDirectoryURL else { return }
        
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dicrectoryURL.path)
    }
    
    
    
    // MARK: Private Methods
    
    /// Create an Apple Event caused by the given `Document`.
    ///
    /// - Bug:
    ///   NSScriptObjectSpecifier.descriptor can be nil.
    ///   If `nil`, the error is propagated by passing a string in place of `Document`.
    ///   [#649](https://github.com/coteditor/CotEditor/pull/649)
    ///
    /// - Parameters:
    ///   - document: The document to dispatch an Apple Event.
    ///   - eventID: The event ID to be set in the returned event.
    /// - Returns: A descriptor for an Apple Event by the `Document`.
    private func createEvent(by document: NSDocument, eventID: AEEventID) -> NSAppleEventDescriptor {
        
        let event = NSAppleEventDescriptor(eventClass: "cEd1",
                                           eventID: eventID,
                                           targetDescriptor: nil,
                                           returnID: AEReturnID(kAutoGenerateReturnID),
                                           transactionID: AETransactionID(kAnyTransactionID))
        let documentDescriptor = document.objectSpecifier.descriptor ?? NSAppleEventDescriptor(string: "BUG: document.objectSpecifier.descriptor was nil")
        
        event.setParam(documentDescriptor, forKeyword: keyDirectObject)
        
        return event
    }
    
    
    /// Cause the given Apple Event to be dispatched to AppleScripts at given URLs.
    ///
    /// - Parameters:
    ///   - event: The Apple Event to be dispatched.
    ///   - scripts: AppleScripts handling the given Apple Event.
    private func dispatch(_ event: NSAppleEventDescriptor, handlers scripts: [EventScript]) {
        
        for script in scripts {
            do {
                try script.run(withAppleEvent: event) { (error) in
                    if let error = error {
                        Console.shared.show(message: error.localizedDescription, title: script.name)
                    }
                }
            } catch {
                NSApp.presentError(error)
            }
        }
    }
    
    
    /// Read files recursively and add to the given menu as menu items.
    ///
    /// - Parameters:
    ///   - directoryURL: The directory where to find files recursively.
    ///   - menu: The menu to add read files.
    private func addChildFileItem(in directoryURL: URL, to menu: NSMenu) {
        
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL,
                                                                      includingPropertiesForKeys: [.fileResourceTypeKey],
                                                                      options: [.skipsHiddenFiles])
            .sorted(\.lastPathComponent)
            else { return }
        
        for url in urls {
            // ignore files/folders of which name starts with "_"
            if url.lastPathComponent.hasPrefix("_") { continue }
            
            var name = url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "^[0-9]+\\)", with: "", options: .regularExpression)  // remove ordering prefix
            
            var shortcut = Shortcut(keySpecChars: url.deletingPathExtension().pathExtension)
            shortcut = shortcut.isValid ? shortcut : .none
            if shortcut != .none {
                name = name.replacingOccurrences(of: "\\..+$", with: "", options: .regularExpression)
            }
            
            if name == .separator {  // separator
                menu.addItem(.separator())
                
            } else if let descriptor = ScriptDescriptor(at: url, name: name), let script = try? descriptor.makeScript() {  // scripts
                // -> Test script possibility before folder because a script can be a directory, e.g. .scptd.
                for eventType in descriptor.eventTypes {
                    guard let script = script as? EventScript else { continue }
                    self.scriptHandlersTable[eventType, default: []].append(script)
                }
                
                let item = NSMenuItem(title: name, action: #selector(launchScript),
                                      keyEquivalent: shortcut.keyEquivalent)
                item.keyEquivalentModifierMask = shortcut.modifierMask
                item.representedObject = script
                item.target = self
                item.toolTip = "“Option + click” to open script in editor.".localized
                menu.addItem(item)
                
            } else if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {  // folder
                let submenu = NSMenu(title: name)
                self.addChildFileItem(in: url, to: submenu)
                
                let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
                item.tag = MainMenu.MenuItemTag.scriptDirectory.rawValue
                item.submenu = submenu
                menu.addItem(item)
            }
        }
    }
    
}
