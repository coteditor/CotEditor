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
//  © 2014-2020 1024jp
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
    
    private(set) var currentScriptName: String?
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL
    private var scriptHandlersTable: [ScriptingEventType: [Script]] = [:]
    
    private lazy var menuBuildingTask = Debouncer(delay: .milliseconds(200)) { [weak self] in self?.buildScriptMenu() }
    private var applicationObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        // find Application Scripts folder
        do {
            self.scriptsDirectoryURL = try FileManager.default.url(for: .applicationScriptsDirectory,
                                                                   in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            // fallback directory creation for in case the app is not Sandboxed
            let bundleIdentifier = Bundle.main.bundleIdentifier!
            let libraryURL = try! FileManager.default.url(for: .libraryDirectory,
                                                          in: .userDomainMask, appropriateFor: nil, create: false)
            self.scriptsDirectoryURL = libraryURL.appendingPathComponent("Application Scripts").appendingPathComponent(bundleIdentifier, isDirectory: true)
            
            if !self.scriptsDirectoryURL.isReachable {
                try! FileManager.default.createDirectory(at: self.scriptsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        super.init()
        
        // observe script folder change
        NSFileCoordinator.addFilePresenter(self)
    }
    
    
    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    
    
    // MARK: File Presenter Protocol
    
    var presentedItemOperationQueue: OperationQueue = .main
    
    
    /// URL to observe
    var presentedItemURL: URL? {
        
        return self.scriptsDirectoryURL
    }
    
    
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
        self.scriptHandlersTable = [:]
        
        let menu = MainMenu.script.menu!
        
        menu.removeAllItems()
        
        self.addChildFileItem(in: self.scriptsDirectoryURL, to: menu)
        
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
                case [.option]:
                    try self.editScript(at: script.descriptor.url)
                
                case [.option, .shift]:
                    try self.revealScript(at: script.descriptor.url)
                
                default:
                    self.currentScriptName = script.descriptor.name
                    try script.run { [weak self] in
                        self?.currentScriptName = nil
                    }
            }
            
        } catch {
            NSApp.presentError(error)
        }
    }
    
    
    /// open Script menu folder in Finder
    @IBAction func openScriptFolder(_ sender: Any?) {
        
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: self.scriptsDirectoryURL.path)
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
        
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(code: "cEd1"),
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
    private func dispatch(_ event: NSAppleEventDescriptor, handlers scripts: [Script]) {
        
        for script in scripts {
            do {
                try script.run(withAppleEvent: event)
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
            
            let descriptor = ScriptDescriptor(at: url)
            
            if descriptor.name == String.separator {
                menu.addItem(.separator())
                continue
            }
            
            guard let resourceType = (try? url.resourceValues(forKeys: [.fileResourceTypeKey]))?.fileResourceType else { continue }
            
            if let script = descriptor.makeScript() {
                for eventType in descriptor.eventTypes {
                    self.scriptHandlersTable[eventType, default: []].append(script)
                }
                
                let item = NSMenuItem(title: descriptor.name, action: #selector(launchScript),
                                      keyEquivalent: descriptor.shortcut.keyEquivalent)
                item.keyEquivalentModifierMask = descriptor.shortcut.modifierMask
                item.representedObject = script
                item.target = self
                item.toolTip = "“Option + click” to open script in editor.".localized
                menu.addItem(item)
                
            } else if resourceType == .directory {
                let submenu = NSMenu(title: descriptor.name)
                let item = NSMenuItem(title: descriptor.name, action: nil, keyEquivalent: "")
                item.tag = MainMenu.MenuItemTag.scriptDirectory.rawValue
                item.submenu = submenu
                menu.addItem(item)
                
                self.addChildFileItem(in: url, to: submenu)
            }
        }
    }
    
    
    /// Open script file in an editor.
    ///
    /// - Parameter url: The URL of a script file to open.
    /// - Throws: `ScriptFileError`
    private func editScript(at url: URL) throws {
        
        guard NSWorkspace.shared.open(url) else {
            throw ScriptFileError(kind: .open, url: url)
        }
    }
    
    
    /// Reveal script file in Finder.
    ///
    /// - Parameter url: The URL of a script file to reveal.
    /// - Throws: `ScriptFileError`
    private func revealScript(at url: URL) throws {
        
        guard url.isReachable else {
            throw ScriptFileError(kind: .existance, url: url)
        }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
}
