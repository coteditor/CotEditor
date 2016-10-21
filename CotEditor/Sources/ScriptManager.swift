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

final class ScriptManager: NSObject, NSFilePresenter {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL
    private var didChangeFolder = false
    
    
    
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
        
        self.addChildFileItem(to: menu, fromDirctory: self.scriptsDirectoryURL)
        
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
    
    /// read files and create/add menu items
    private func addChildFileItem(to menu: NSMenu, fromDirctory directoryURL: URL) {
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: directoryURL,
                                                                          includingPropertiesForKeys: [.fileResourceTypeKey],
                                                                          options: [.skipsPackageDescendants, .skipsHiddenFiles])
            else { return }
        
        for fileURL in fileURLs {
            // ignore files/folders of which name starts with "_"
            if fileURL.lastPathComponent.hasPrefix("_") { continue }
        
            let title = self.scriptName(from: fileURL)
            
            if title == String.separator {
                menu.addItem(NSMenuItem.separator())
                continue
            }
            
            guard let resourceType = (try? fileURL.resourceValues(forKeys: [.fileResourceTypeKey]))?.fileResourceType else { continue }
            
            switch resourceType {
            case URLFileResourceType.directory:
                let submenu = NSMenu(title: title)
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.tag = MainMenu.MenuItemTag.scriptDirectory.rawValue
                menu.addItem(item)
                item.submenu = submenu
                self.addChildFileItem(to: submenu, fromDirctory: fileURL)
                
            case URLFileResourceType.regular:
                guard (AppleScript.extensions + ShellScript.extensions).contains(fileURL.pathExtension) else { continue }
                
                let shortcut = self.shortcut(from: fileURL)
                let item = NSMenuItem(title: title, action: #selector(launchScript), keyEquivalent: shortcut.keyEquivalent)
                item.keyEquivalentModifierMask = shortcut.modifierMask
                item.representedObject = fileURL
                item.target = self
                item.toolTip = NSLocalizedString("“Option + click” to open script in editor.", comment: "")
                menu.addItem(item)
                
            default: break
            }
        }
    }
    
    
    /// build menu item title from file/folder name
    private func scriptName(from url: URL) -> String {
        
        let filename = url.deletingPathExtension().lastPathComponent
        
        // remove the number prefix ordering
        var scriptName = filename.replacingOccurrences(of: "^[0-9]+\\)", with: "", options: .regularExpression)
        
        // remove keyboard shortcut definition
        let specChars = ModifierKey.all.map { $0.keySpecChar }
        if let firstExtensionChar = scriptName.components(separatedBy: ".").last?.characters.first,
            specChars.contains(String(firstExtensionChar))
        {
            scriptName = scriptName.components(separatedBy: ".").first!
        }
        
        return scriptName
    }
    
    
    /// get keyboard shortcut from file name
    private func shortcut(from fileURL: URL) -> Shortcut {
        
        let keySpecChars = fileURL.deletingPathExtension().pathExtension
        let shortcut = Shortcut(keySpecChars: keySpecChars)
        
        guard !shortcut.modifierMask.isEmpty else { return .none }
        
        return shortcut
    }

}
