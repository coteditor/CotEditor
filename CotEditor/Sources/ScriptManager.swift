/*
 
 ScriptManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-03-12.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

enum ScriptingEventType: String {
    
    case documentOpened = "document opened"
    case documentSaved = "document saved"
    
    
    var eventID: AEEventID {
        
        switch self {
        case .documentOpened: return AEEventID(code: "edod")
        case .documentSaved: return AEEventID(code: "edsd")
        }
    }
    
}



final class ScriptManager: NSObject, NSFilePresenter {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL
    private var didChangeFolder = false
    private var scriptHandlersTable: [ScriptingEventType: [URL]] = [:]
    
    
    
    // MARK: Private Enum
    
    private enum MenuItemTag: Int {
        case scriptsDefault = 8001  // not to list up in context menu
    }
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    private override init() {
        
        // find Application Scripts folder
        do {
            self.scriptsDirectoryURL = try FileManager.default.url(for: .applicationScriptsDirectory,
                                                                   in: .userDomainMask, appropriateFor: nil, create: true)
        } catch _ {
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
        
        self.buildScriptMenu()
        
        // observe for script folder change
        NSFileCoordinator.addFilePresenter(self)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .NSApplicationDidBecomeActive, object: NSApp)
        
        // run dummy AppleScript once for quick script launch
        DispatchQueue.main.async {
            NSAppleScript(source: "tell application \"CotEditor\" to name")?.executeAndReturnError(nil)
        }
    }
    
    
    deinit {
        NSFileCoordinator.removeFilePresenter(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: File Presenter Protocol
    
    var presentedItemOperationQueue = OperationQueue.main
    
    
    /// URL to observe
    var presentedItemURL: URL? {
        
        return self.scriptsDirectoryURL
    }
    
    
    /// script folder did change
    func presentedSubitemDidChange(at url: URL) {
        
        self.didChangeFolder = true
        
        if NSApp.isActive {
            self.buildScriptMenu()
        }
    }
    
    
    /// update script menu if needed
    func applicationDidBecomeActive(_ notification: Notification) {
        
        if self.didChangeFolder {
            self.buildScriptMenu()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return menu for context menu
    var contexualMenu: NSMenu? {
        
        let menu = NSMenu()
        
        for item in MainMenu.script.menu!.items {
            guard item.tag != MenuItemTag.scriptsDefault.rawValue else { continue }
            
            menu.addItem(item.copy() as! NSMenuItem)
        }
        
        return (menu.numberOfItems > 0) ? menu : nil
    }
    
    
    /// build Script menu
    func buildScriptMenu() {
        
        let menu = MainMenu.script.menu!
        
        menu.removeAllItems()
        
        self.scriptHandlersTable = [:]
        
        self.addChildFileItem(to: menu, in: self.scriptsDirectoryURL)
        
        if !menu.items.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }
        
        let openMenuItem = NSMenuItem(title: NSLocalizedString("Open Scripts Folder", comment: ""),
                                      action: #selector(openScriptFolder), keyEquivalent: "")
        openMenuItem.target = self
        openMenuItem.tag = MenuItemTag.scriptsDefault.rawValue
        menu.addItem(openMenuItem)
        
        self.didChangeFolder = false
    }
    
    
    /// Dispatch an Apple event that notifies the given document was opened
    ///
    /// - parameter document: the document that was opened
    func dispatchEvent(documentOpened document: Document) {
        
        let eventType = ScriptingEventType.documentOpened
        let event = createEvent(by: document, eventID: eventType.eventID)
        
        guard let urls = self.scriptHandlersTable[eventType] else { return }
        
        self.dispatch(event, toHandlersAt: urls)
    }
    
    
    /// Dispatch an Apple event that notifies the given document was opened
    ///
    /// - parameter document: the document that was opened
    func dispatchEvent(documentSaved document: Document) {
        
        let eventType = ScriptingEventType.documentSaved
        let event = createEvent(by: document, eventID: eventType.eventID)
        
        guard let urls = self.scriptHandlersTable[eventType] else { return }
        
        self.dispatch(event, toHandlersAt: urls)
    }
    
    
    
    // MARK: Action Message
    
    /// launch script (invoked by menu item)
    @IBAction func launchScript(_ sender: AnyObject?) {
        
        guard let url = sender?.representedObject as? URL else { return }
        
        let scriptName = self.scriptName(from: url)
        
        let script: Script
        if AppleScript.extensions.contains(url.pathExtension) {
            script = AppleScript(url: url, name: scriptName)
        } else if ShellScript.extensions.contains(url.pathExtension) {
            script = ShellScript(url: url, name: scriptName)
        } else {
            return
        }
        
        do {
            // change behavior if modifier key is pressed
            switch NSEvent.modifierFlags() {
            case [.option]:
                try script.edit()
                
            case [.option, .shift]:
                try script.reveal()
                
            default:
                try script.run()
            }
            
        } catch let error {
            NSApp.presentError(error)
        }
    }
    
    
    /// open Script Menu folder in Finder
    @IBAction func openScriptFolder(_ sender: Any?) {
        
        NSWorkspace.shared().activateFileViewerSelecting([self.scriptsDirectoryURL])
    }
    
    
    
    // MARK: Private Methods
    
    /// Create an Apple event caused by the given `Document`
    ///
    /// - bug:
    ///   NSScriptObjectSpecifier.descriptor can be nil.
    ///   If `nil`, the error is propagated by passing a string in place of `Document`.
    ///   [#649](https://github.com/coteditor/CotEditor/pull/649)
    ///
    /// - parameters:
    ///   - document: the document to dispatch an Apple event
    ///   - eventID: the event ID to be set in the returned event
    ///
    /// - returns: a descriptor for an Apple event by the `Document`
    private func createEvent(by document: Document, eventID: AEEventID) -> NSAppleEventDescriptor {
        
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(code: "cEd1"), eventID: eventID, targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
        
        let documentDescriptor = document.objectSpecifier.descriptor ?? NSAppleEventDescriptor(string: "BUG: document.objectSpecifier.descriptor was nil")
        event.setParam(documentDescriptor, forKeyword: keyDirectObject)
        
        return event
    }
    
    
    /// Cause the given Apple event to be dispatched to AppleScripts at given URLs.
    ///
    /// - parameters:
    ///   - event: the Apple event to be dispatched
    ///   - urls: the locations of AppleScript handling the given Apple event
    private func dispatch(_ event: NSAppleEventDescriptor, toHandlersAt urls: [URL]) {
        
        for url in urls {
            let script = AppleScript(url: url, name: self.scriptName(from: url))
            do {
                try script.run(withAppleEvent: event)
            } catch let error {
                NSApp.presentError(error)
            }
        }
    }
    
    
    /// read files and create/add menu items
    private func addChildFileItem(to menu: NSMenu, in directoryURL: URL) {
        
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL,
                                                                      includingPropertiesForKeys: [.fileResourceTypeKey],
                                                                      options: [.skipsPackageDescendants, .skipsHiddenFiles])
            else { return }
        
        for url in urls {
            // ignore files/folders of which name starts with "_"
            if url.lastPathComponent.hasPrefix("_") { continue }
        
            let title = self.scriptName(from: url)
            
            if title == String.separator {
                menu.addItem(NSMenuItem.separator())
                continue
            }
            
            guard let resourceType = (try? url.resourceValues(forKeys: [.fileResourceTypeKey]))?.fileResourceType else { continue }
            
            if (AppleScript.extensions + ShellScript.extensions).contains(url.pathExtension) {
                if (url.pathExtension == "scptd") {
                    self.loadScriptInfo(at: url)
                }
                
                let shortcut = self.shortcut(from: url)
                let item = NSMenuItem(title: title, action: #selector(launchScript), keyEquivalent: shortcut.keyEquivalent)
                item.keyEquivalentModifierMask = shortcut.modifierMask
                item.representedObject = url
                item.target = self
                item.toolTip = NSLocalizedString("“Option + click” to open script in editor.", comment: "")
                menu.addItem(item)
                
            } else if resourceType == URLFileResourceType.directory {
                let submenu = NSMenu(title: title)
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.tag = MainMenu.MenuItemTag.scriptDirectory.rawValue
                menu.addItem(item)
                item.submenu = submenu
                self.addChildFileItem(to: submenu, in: url)
            }
        }
    }
    
    
    /// load script info in Apple Script bundle
    private func loadScriptInfo(at url: URL) {
        
        let infoUrl = url.appendingPathComponent("Contents/Info.plist")
        
        guard
            let info = NSDictionary(contentsOf: infoUrl),
            let names = info["CotEditorHandlers"] as? [String]
            else { return }
        
        for name in names {
            guard let eventType = ScriptingEventType(rawValue: name) else { return }
            
            var handlers = self.scriptHandlersTable[eventType] ?? []
            handlers.append(url)
            self.scriptHandlersTable[eventType] = handlers
        }
    }
    
    
    /// build menu item title from file/folder name
    private func scriptName(from url: URL) -> String {
        
        let filename = url.deletingPathExtension().lastPathComponent
        
        // remove the number prefix ordering
        var scriptName = filename.replacingOccurrences(of: "^[0-9]+\\)", with: "", options: .regularExpression)
        
        // remove keyboard shortcut definition
        if let keySpecChars = scriptName.components(separatedBy: ".").last,
            ModifierKey.all.contains(where: { keySpecChars.hasPrefix($0.keySpecChar) })
        {
            scriptName = scriptName.components(separatedBy: ".").first ?? scriptName
        }
        
        return scriptName
    }
    
    
    /// get keyboard shortcut from file name
    private func shortcut(from url: URL) -> Shortcut {
        
        let keySpecChars = url.deletingPathExtension().pathExtension
        let shortcut = Shortcut(keySpecChars: keySpecChars)
        
        guard !shortcut.modifierMask.isEmpty else { return .none }
        
        return shortcut
    }

}
