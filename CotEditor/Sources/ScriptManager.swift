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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class ScriptManager: NSObject {
    
    // MARK: Public Properties
    
    static let shared = ScriptManager()
    
    
    
    // MARK: Private Properties
    
    private let scriptsDirectoryURL: URL
    
    /// file extensions for UNIX scripts
    private var scriptExtensions: [String] = ["sh", "pl", "php", "rb", "py", "js"]
    
    /// file extensions for AppleScript
    private var AppleScriptExtensions = ["applescript", "scpt"]
    
    
    
    // MARK: Private Enum
    
    private enum OutputType: String {
        
        case replaceSelection = "ReplaceSelection"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case pasteBoard = "Pasteboard"
    }
    
    
    private enum InputType: String {
        
        case selection = "Selection"
        case allText = "AllText"
    }
    
    
    private enum MenuItemTag: Int {
        case scriptsDefault = 8001  // not to list up in context menu
    }
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        // find Application Scripts folder
        do {
            self.scriptsDirectoryURL = try FileManager.default.urlForDirectory(.applicationScriptsDirectory,
                                                                                  in: .userDomainMask, appropriateFor: nil, create: true)
        } catch _ {
            // fallback directory creation for in case the app is not Sandboxed
            let bundleIdentifier = Bundle.main.bundleIdentifier!
            let libraryURL = try! FileManager.default.urlForDirectory(.libraryDirectory,
                                                                                in: .userDomainMask, appropriateFor: nil, create: false)
            self.scriptsDirectoryURL = try! libraryURL.appendingPathComponent("Application Scripts").appendingPathComponent(bundleIdentifier, isDirectory: true)
            
            if !self.scriptsDirectoryURL.isReachable {
                try! FileManager.default.createDirectory(at: self.scriptsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        super.init()
        
        self.buildScriptMenu(self)
        
        // run dummy AppleScript once for quick script launch
        DispatchQueue.main.async {
            let script = NSAppleScript(source: "tell application \"CotEditor\" to name")
            script?.executeAndReturnError(nil)
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
    
    
    
    // MARK: Action Message
    
    /// launch script (invoked by menu item)
    @IBAction func launchScript(_ sender: AnyObject?) {
        
        guard let fileURL = sender?.representedObject as? URL else { return }
        
        // display alert and endup if file not exists
        guard fileURL.isReachable else {
            let message = String(format: NSLocalizedString("The script “%@” does not exist.\n\nCheck it and select “Update Script Menu”.", comment: ""), fileURL)
            self.showAlert(message: message)
            return
        }
        
        let pathExtension = fileURL.pathExtension!
        
        // change behavior if modifier key is pressed
        let modifierFlags = NSEvent.modifierFlags()
        if modifierFlags == .option {  // open script file in editor if the Option key is pressed
            let identifier = self.AppleScriptExtensions.contains(pathExtension) ? "com.apple.ScriptEditor2" : Bundle.main.bundleIdentifier!
            guard NSWorkspace.shared().open([fileURL], withAppBundleIdentifier: identifier, options: [], additionalEventParamDescriptor: nil, launchIdentifiers: nil) else {
                // display alert if cannot open/select the script file
                let message = String(format: NSLocalizedString("The script file “%@” couldn’t be opened.", comment: ""), fileURL)
                self.showAlert(message: message)
                return
            }
            return
            
        } else if modifierFlags == [.option, .shift] {  // reveal on Finder if the Option+Shift keys are pressed
            NSWorkspace.shared().activateFileViewerSelecting([fileURL])
            return
        }
        
        // run AppleScript
        if self.AppleScriptExtensions.contains(pathExtension) {
            self.runAppleScript(url: fileURL)
            
        // run Shell Script
        } else if self.scriptExtensions.contains(pathExtension) {
            // display alert if script file doesn't have execution permission
            guard fileURL.isExecutable ?? false else {
                let message = String(format: NSLocalizedString("The script “%@” can’t be executed because you don’t have the execute permission.\n\nCheck permission of the script file.", comment: ""), fileURL)
                self.showAlert(message: message)
                return
            }
            
            self.runShellScript(url: fileURL)
        }
    }
    
    
    /// build Script menu
    @IBAction func buildScriptMenu(_ sender: AnyObject?) {
        
        let menu = MainMenu.script.menu!
        
        menu.removeAllItems()
        
        self.addChildFileItem(to: menu, fromDirctory: self.scriptsDirectoryURL)
        
        let separatorItem = NSMenuItem.separator()
        separatorItem.tag = MenuItemTag.scriptsDefault.rawValue
        menu.addItem(separatorItem)
        
        let openMenuItem = NSMenuItem(title: NSLocalizedString("Open Scripts Folder", comment: ""),
                                      action: #selector(openScriptFolder(_:)),keyEquivalent: "")
        openMenuItem.target = self
        openMenuItem.tag = MenuItemTag.scriptsDefault.rawValue
        menu.addItem(openMenuItem)
        
        let updateMenuItem = NSMenuItem(title: NSLocalizedString("Update Script Menu", comment: ""),
                                        action: #selector(buildScriptMenu(_:)),keyEquivalent: "")
        updateMenuItem.target = self
        updateMenuItem.tag = MenuItemTag.scriptsDefault.rawValue
        menu.addItem(updateMenuItem)
    }
    
    
    /// open Script Menu folder in Finder
    @IBAction func openScriptFolder(_ sender: AnyObject?) {
        
        NSWorkspace.shared().activateFileViewerSelecting([self.scriptsDirectoryURL])
    }
    
    
    // MARK: Private Methods
    
    /// read input type from script
    private func scanInputType(_ string: String) -> InputType? {
        
        var scannedString: NSString?
        let scanner = Scanner(string: string)
        scanner.caseSensitive = true
        
        while scanner.isAtEnd {
            scanner.scanUpTo("%%%{CotEditorXInput=", into: nil)
            if scanner.scanString("%%%{CotEditorXInput=", into: nil) {
                if scanner.scanUpTo("}%%%", into: &scannedString) {
                    break
                }
            }
        }
        
        if let scannedString = scannedString {
            return InputType(rawValue: scannedString as String)
        } else {
            return nil
        }
    }
    
    
    /// read output type from script
    private func scanOutputType(_ string: String) -> OutputType? {
        
        var scannedString: NSString?
        let scanner = Scanner(string: string)
        scanner.caseSensitive = true
        
        while scanner.isAtEnd {
            scanner.scanUpTo("%%%{CotEditorXOutput=", into: nil)
            if scanner.scanString("%%%{CotEditorXOutput=", into: nil) {
                if scanner.scanUpTo("}%%%", into: &scannedString) {
                    break
                }
            }
        }
        
        if let scannedString = scannedString {
            return OutputType(rawValue: scannedString as String)
        } else {
            return nil
        }
    }
    
    
    /// return document content conforming to the input type
    private func inputString(type: InputType, document: CEDocument?) throws -> String {
    
        guard let editor = document?.editor else {
            // on no document found
            throw NSError(domain: CotEditorError.domain, code: CotEditorError.scriptNoTargetDocument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No document to get input.", comment: "")])
        }
        
        switch type {
        case .selection:
            return editor.substringWithSelection()
            
        case .allText:
            return editor.string()
        }
    }
    
    
    /// apply results conforming to the output type to the frontmost document
    private func applyOutput(_ output: String, document: CEDocument?, type: OutputType) throws {
        
        let editor = document?.editor
        
        guard editor != nil || type == .pasteBoard else {
            throw NSError(domain: CotEditorError.domain, code: CotEditorError.scriptNoTargetDocument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No document to put output.", comment: "")])
        }
        
        switch type {
        case .replaceSelection:
            editor!.insertTextViewString(output)
            
        case .replaceAllText:
            editor!.replaceTextViewAllString(with: output)
            
        case .insertAfterSelection:
            editor!.insertTextViewString(afterSelection: output)
            
        case .appendToAllText:
            editor!.appendTextViewString(output)
            
        case .pasteBoard:
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            guard pasteboard.setString(output, forType: NSStringPboardType) else {
                NSBeep()
                return
            }
        }
    }
    
    
    /// read files and create/add menu items
    private func addChildFileItem(to menu: NSMenu, fromDirctory directoryURL: URL) {
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [URLResourceKey.fileResourceTypeKey.rawValue], options: [.skipsPackageDescendants, .skipsHiddenFiles]) else { return }
        
        for fileURL in fileURLs {
            // ignore files/folders of which name starts with "_"
            if (fileURL.lastPathComponent?.hasPrefix("_")) ?? false { continue }
            
            let title = self.scriptName(fromURL: fileURL)
            
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
                guard let pathExtension = fileURL.pathExtension
                    where self.AppleScriptExtensions.contains(pathExtension) ||
                          self.scriptExtensions.contains(pathExtension) else { continue }
                
                let (keyEquivalent, modifierMask) = self.keyEquivalentAndModifierMask(from: fileURL)
                let item = NSMenuItem(title: title, action: #selector(launchScript(_:)), keyEquivalent: keyEquivalent)
                item.keyEquivalentModifierMask = modifierMask
                item.representedObject = fileURL
                item.target = self
                item.toolTip = NSLocalizedString("“Option + click” to open script in editor.", comment: "")
                menu.addItem(item)
                
            default: break
            }
        }
    }
    
    
    /// build menu item title from file/folder name
    private func scriptName(fromURL url: URL) -> String {
        
        var scriptName = (try! url.deletingPathExtension()).lastPathComponent!
        
        // remove the number prefix ordering
        let regex = try! RegularExpression(pattern: "^[0-9]+\\)", options: [])
        scriptName = regex.stringByReplacingMatches(in: scriptName, options: [], range: scriptName.nsRange, withTemplate: "")
        
        // remove keyboard shortcut definition
        let specChars = ModifierKey.all.map { $0.keySpecChar }
        if let firstExtensionChar = scriptName.components(separatedBy: ".").last?.characters.first
            where specChars.contains(String(firstExtensionChar))
        {
            scriptName = scriptName.components(separatedBy: ".").first!
        }
        
        return scriptName
    }
    
    
    /// get keyboard shortcut from file name
    private func keyEquivalentAndModifierMask(from fileURL: URL) -> (String, NSEventModifierFlags) {
        
        guard let keySpecChars = (try? fileURL.deletingPathExtension())?.pathExtension else { return ("", []) }
        
        return KeyBindingUtils.keyEquivalentAndModifierMask(keySpecChars: keySpecChars, requiresCommandKey: true)
    }
    
    
    /// display alert message
    private func showAlert(message: String) {
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Script Error", comment: "")
        alert.informativeText = message
        alert.alertStyle = NSCriticalAlertStyle
        
        DispatchQueue.main.async {
            alert.runModal()
        }
    }
    
    
    /// read content of script file
    private func contentStringOfScript(url: URL) -> String? {
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        for encoding in EncodingManager.shared.defaultEncodings {
            guard let encoding = encoding else { continue }
            
            if let contentString = String(data: data, encoding: encoding) {
                return contentString
            }
        }
        
        return nil
    }
    
    
    /// run AppleScript
    private func runAppleScript(url: URL) {
        
        let task: NSUserAppleScriptTask
        do {
            task = try NSUserAppleScriptTask(url: url)
        } catch let error as NSError {
            self.showAlert(message: error.localizedDescription)
            return
        }
        
        task.execute(withAppleEvent: nil, completionHandler: { [weak self] (result: NSAppleEventDescriptor?, error: NSError?) in
            if let error = error {
                self?.showAlert(message: error.localizedDescription)
            }
            })
    }
    
    
    /// run UNIX script
    private func runShellScript(url: URL) {
        
        // show an alert and endup if script file cannot read
        guard let script = self.contentStringOfScript(url: url) where !script.isEmpty else {
            self.showAlert(message: String(format: NSLocalizedString("The script “%@” couldn’t be read.", comment: ""), url))
            return
        }
        let scriptName = self.scriptName(fromURL: url)
        
        // hold target document
        weak var document = NSDocumentController.shared().currentDocument as? CEDocument
        
        // read input
        var input: String?
        if let inputType = self.scanInputType(script) {
            do {
                input = try self.inputString(type: inputType, document: document)
            } catch let error as NSError {
                self.writeToConsole(message: error.localizedDescription, scriptName: scriptName)
                return
            }
        }
        
        // get output type
        let outputType = self.scanOutputType(script)
        
        // prepare file path as argument if available
        var arguments = [String]()
        if let path = document?.fileURL?.path {
            arguments.append(path)
        }
        
        // create task
        let task: NSUserUnixTask
        do {
            task = try NSUserUnixTask(url: url)
        } catch let error as NSError {
            self.showAlert(message: error.localizedDescription)
            return
        }
        
        // set pipes
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe.fileHandleForReading
        task.standardOutput = outPipe.fileHandleForWriting
        task.standardError = errPipe.fileHandleForWriting
        
        // set input data asynchronously if available
        if let input = input where !input.isEmpty {
            inPipe.fileHandleForWriting.writeabilityHandler = { (handle: FileHandle) in
                let data = input.data(using: .utf8)!
                handle.write(data)
                handle.closeFile()
            }
        }
        
        var isCancelled = false  // user cancel state
        
        // read output asynchronously for safe with huge output
        outPipe.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(forName: .NSFileHandleReadToEndOfFileCompletion, object: outPipe.fileHandleForReading, queue: nil) { [weak self] (note: Notification) in
            NotificationCenter.default.removeObserver(observer!)
            
            guard !isCancelled else { return }
            guard let outputType = outputType else { return }
            
            guard let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data else { return }
            if let output = String(data: data, encoding: .utf8) {
                do {
                    try self?.applyOutput(output, document: document, type: outputType)
                } catch let error as NSError {
                    self?.writeToConsole(message: error.localizedDescription, scriptName: scriptName)
                }
            }
        }
        
        // execute
        task.execute(withArguments: arguments) { [weak self] (error) in
            // on user cancel
            if error?.domain == NSPOSIXErrorDomain && error?.code == Int(ENOTBLK) {
                isCancelled = true
                return
            }
            
            //set error message to the sconsole
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let message = String(data: errorData, encoding: .utf8) where !message.isEmpty {
                DispatchQueue.main.async {
                    self?.writeToConsole(message: message, scriptName: scriptName)
                }
            }
        }
    }
    
    
    /// append message to console panel and show it
    private func writeToConsole(message: String, scriptName: String) {
        
        ConsolePanelController.shared.showWindow(self)
        ConsolePanelController.shared.append(message: message, title: scriptName)
    }

}
