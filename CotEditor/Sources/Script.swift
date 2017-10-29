/*
 
 Script.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-10-22.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
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
import OSAKit

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



enum ScriptingFileType {
    
    case appleScript
    case shellScript
    
    static let all: [ScriptingFileType] = [.appleScript, .shellScript]
    
    
    var extensions: [String] {
        
        switch self {
        case .appleScript: return ["applescript", "scpt", "scptd"]
        case .shellScript: return ["sh", "pl", "php", "rb", "py", "js", "swift"]
        }
    }
    
}



enum ScriptingExecutionModel: String {
    
    case unrestricted
    case persistent
    
}



struct ScriptDescriptor {
    
    // MARK: Public Properties
    
    let url: URL
    let name: String
    let type: ScriptingFileType?
    let executionModel: ScriptingExecutionModel
    let eventTypes: [ScriptingEventType]
    let shortcut: Shortcut
    let ordering: Int?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Create a descriptor that represents an user script at given URL.
    ///
    /// `Contents/Info.plist` in the script at `url` will be read if they exist.
    ///
    /// - parameter url: the location of an user script
    init(at url: URL) {
        
        // Extract from URL
        
        self.url = url
        self.type = ScriptingFileType.all.first { $0.extensions.contains(url.pathExtension) }
        var name = url.deletingPathExtension().lastPathComponent
        
        let shortcut = Shortcut(keySpecChars: url.deletingPathExtension().pathExtension)
        if shortcut.modifierMask.isEmpty {
            self.shortcut = .none
        } else {
            self.shortcut = shortcut
            
            // Remove the shortcut specification from the script name
            name = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        }
        
        if let range = name.range(of: "^[0-9]+\\)", options: .regularExpression) {
            // Remove the parenthesis at last
            let orderingString = name.substring(to: name.index(before: range.upperBound))
            self.ordering = Int(orderingString)
            
            // Remove the ordering number from the script name
            name.removeSubrange(range)
        } else {
            self.ordering = nil
        }
        
        self.name = name
        
        // Extract from Info.plist
        
        let info = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist"))
        
        if let name = info?["CotEditorExecutionModel"] as? String {
            self.executionModel = ScriptingExecutionModel(rawValue: name) ?? .unrestricted
        } else {
            self.executionModel = .unrestricted
        }
        
        if let names = info?["CotEditorHandlers"] as? [String] {
            self.eventTypes = names.flatMap { ScriptingEventType(rawValue: $0) }
        } else {
            self.eventTypes = []
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Create and return an user script instance
    ///
    /// - returns: An instance of `Script` created by the receiver.
    ///            Returns `nil` if the script type is unsupported.
    func makeScript() -> Script? {
        
        guard let type = self.type else { return nil }
        
        switch type {
        case .appleScript:
            switch self.executionModel {
            case .unrestricted: return AppleScript(with: self)
            case .persistent: return PersistentOSAScript(with: self)
            }
        case .shellScript: return ShellScript(with: self)
        }
    }
    
}



protocol Script: class {
    
    // MARK: Properties
    
    /// A script descriptor the receiver was created from.
    var descriptor: ScriptDescriptor { get }
    
    // MARK: Methods
    
    /// Execute the script with the default way.
    func run(completionHandler: (() -> Void)?) throws
    
    
    /// Execute the script by sending it the given Apple event.
    ///
    /// Events the script cannot handle must be ignored with no errors.
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: (() -> Void)?) throws
    
}



extension Script {
    
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: (() -> Void)? = nil) throws {
        // ignore every request with an event by default
    }
    
}



// MARK: -

final class AppleScript: Script {
    
    // MARK: Script Properties
    
    let descriptor: ScriptDescriptor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(with descriptor: ScriptDescriptor) {
        self.descriptor = descriptor
    }
    
    
    
    // MARK: Script Methods
    
    /// run script
    /// - throws: Error by NSUserScriptTask
    func run(completionHandler: (() -> Void)? = nil) throws {
        
        try self.run(withAppleEvent: nil, completionHandler: completionHandler)
    }
    
    
    /// Execute the AppleScript script by sending it the given Apple event.
    ///
    /// Any script errors will be written to the console panel.
    ///
    /// - parameter event: the apple event
    ///
    /// - throws: `ScriptFileError` and any errors by `NSUserScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: (() -> Void)? = nil) throws {
        
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        
        let task = try NSUserAppleScriptTask(url: self.descriptor.url)
        let scriptName = self.descriptor.name
        
        task.execute(withAppleEvent: event) { (result: NSAppleEventDescriptor?, error: Error?) in
            if let error = error {
                writeToConsole(message: error.localizedDescription, scriptName: scriptName)
            }
            completionHandler?()
        }
    }
    
    
}



// MARK: -

final class PersistentOSAScript: Script {
    
    // MARK: Script Properties
    
    let descriptor: ScriptDescriptor
    let script: OSAScript
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init?(with descriptor: ScriptDescriptor) {
        
        guard let script = OSAScript(contentsOf: descriptor.url, error: nil) else { return nil }
        
        self.descriptor = descriptor
        self.script = script
    }
    
    
    
    // MARK: Script Methods
    
    /// run script
    /// - throws: Error by NSUserScriptTask
    func run(completionHandler: (() -> Void)? = nil) throws {
        
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        
        var errorInfo: NSDictionary? = NSDictionary()
        if self.script.executeAndReturnError(&errorInfo) == nil {
            let message = (errorInfo?["NSLocalizedDescription"] as? String) ?? "Unknown error"
            writeToConsole(message: message, scriptName: self.descriptor.name)
            completionHandler?()
        }
    }
    
    
    /// Execute the AppleScript script by sending it the given Apple event.
    ///
    /// Any script errors will be written to the console panel.
    ///
    /// - parameter event: the apple event
    ///
    /// - throws: `ScriptFileError` and any errors by `NSUserScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: (() -> Void)? = nil) throws {
        
        guard let event = event else {
            try self.run(completionHandler: completionHandler)
            return
        }
        
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        
        var errorInfo: NSDictionary?
        if self.script.executeAppleEvent(event, error: &errorInfo) == nil {
            let message = (errorInfo?["NSLocalizedDescription"] as? String) ?? "Unknown error"
            writeToConsole(message: message, scriptName: self.descriptor.name)
            completionHandler?()
        }
    }
    
}



// MARK: -

final class ShellScript: Script {
    
    // MARK: Script Properties
    
    let descriptor: ScriptDescriptor
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(with descriptor: ScriptDescriptor) {
        
        self.descriptor = descriptor
    }
    
    
    
    // MARK: Private Enum
    
    private enum OutputType: String, ScriptToken {
        
        case replaceSelection = "ReplaceSelection"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case newDocument = "NewDocument"
        case pasteBoard = "Pasteboard"
        
        static var token = "CotEditorXOutput"
    }
    
    
    private enum InputType: String, ScriptToken {
        
        case selection = "Selection"
        case allText = "AllText"
        
        static var token = "CotEditorXInput"
    }
    
    
    
    // MARK: Script Methods
    
    /// run script
    /// - throws: ScriptFileError or Error by NSUserScriptTask
    func run(completionHandler: (() -> Void)? = nil) throws {
        
        // check script file
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        guard try self.descriptor.url.resourceValues(forKeys: [.isExecutableKey]).isExecutable ?? false else {
            throw ScriptFileError(kind: .permission, url: self.descriptor.url)
        }
        guard let script = self.content, !script.isEmpty else {
            throw ScriptFileError(kind: .read, url: self.descriptor.url)
        }
        
        // fetch target document
        weak var document = NSDocumentController.shared().currentDocument as? Document
        
        // read input
        let input: String?
        if let inputType = InputType(scanning: script) {
            do {
                input = try self.readInputString(type: inputType, editor: document)
            } catch {
                writeToConsole(message: error.localizedDescription, scriptName: self.descriptor.name)
                return
            }
        } else {
            input = nil
        }
        
        // get output type
        let outputType = OutputType(scanning: script)
        
        // prepare file path as argument if available
        let arguments: [String] = {
            guard let path = document?.fileURL?.path else { return [] }
            return [path]
        }()
        
        // create task
        let task = try NSUserUnixTask(url: self.descriptor.url)
        
        // set pipes
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe.fileHandleForReading
        task.standardOutput = outPipe.fileHandleForWriting
        task.standardError = errPipe.fileHandleForWriting
        
        // set input data if available
        if let data = input?.data(using: .utf8) {
            inPipe.fileHandleForWriting.writeabilityHandler = { (handle: FileHandle) in
                // write input data chunk by chunk
                // -> to avoid freeze by a huge input data, whose length is more than 65,536 (2^16).
                for chunk in data.components(length: 65_536) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        }
        
        let scriptName = self.descriptor.name
        var isCancelled = false  // user cancel state
        
        // read output asynchronously for safe with huge output
        if let outputType = outputType {
            outPipe.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
            weak var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(forName: .NSFileHandleReadToEndOfFileCompletion, object: outPipe.fileHandleForReading, queue: nil) { (note: Notification) in
                NotificationCenter.default.removeObserver(observer!)
                
                guard
                    !isCancelled,
                    let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data,
                    let output = String(data: data, encoding: .utf8)
                    else { return }
                
                do {
                    try ShellScript.applyOutput(output, editor: document, type: outputType)
                } catch {
                    writeToConsole(message: error.localizedDescription, scriptName: scriptName)
                }
            }
        }
        
        // execute
        task.execute(withArguments: arguments) { error in
            defer {
                completionHandler?()
            }
            
            // on user cancel
            if let error = error as? POSIXError, error.code == .ENOTBLK {
                isCancelled = true
                return
            }
            
            // put error message on the console
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let message = String(data: errorData, encoding: .utf8), !message.isEmpty {
                writeToConsole(message: message, scriptName: scriptName)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// read content of script file
    private lazy var content: String? = {
        
        guard let data = try? Data(contentsOf: self.descriptor.url) else { return nil }
        
        for encoding in EncodingManager.shared.defaultEncodings {
            guard let encoding = encoding else { continue }
            
            if let contentString = String(data: data, encoding: encoding) {
                return contentString
            }
        }
        
        return nil
    }()
    
    
    /// return document content conforming to the input type
    /// - throws: ScriptError
    private func readInputString(type: InputType, editor: Editable?) throws -> String {
        
        guard let editor = editor else {
            throw ScriptError.noInputTarget
        }
        
        switch type {
        case .selection:
            return editor.selectedString
            
        case .allText:
            return editor.string
        }
    }
    
    
    /// apply results conforming to the output type to the frontmost document
    /// - throws: ScriptError
    private static func applyOutput(_ output: String, editor: Editable?, type: OutputType) throws {
        
        if type == .pasteBoard {
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            guard pasteboard.setString(output, forType: NSStringPboardType) else {
                NSBeep()
                return
            }
            return
        }
        
        if type == .newDocument {
            let document = try NSDocumentController.shared().openUntitledDocumentAndDisplay(true) as! Document
            document.insert(string: output)
            document.selectedRange = NSRange(location: 0, length: 0)
            return
        }
        
        guard let editor = editor else {
            throw ScriptError.noOutputTarget
        }
        
        DispatchQueue.main.async {
            switch type {
            case .replaceSelection:
                editor.insert(string: output)
                
            case .replaceAllText:
                editor.replaceAllString(with: output)
                
            case .insertAfterSelection:
                editor.insertAfterSelection(string: output)
                
            case .appendToAllText:
                editor.append(string: output)
                
            case .newDocument, .pasteBoard:
                assertionFailure()
            }
        }
    }
    
}



// MARK: - Error

struct ScriptFileError: LocalizedError {
    
    enum ErrorKind {
        case existance
        case read
        case open
        case permission
    }
    
    let kind: ErrorKind
    let url: URL
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .existance:
            return String(format: NSLocalizedString("The script “%@” does not exist.", comment: ""), self.url.lastPathComponent)
        case .read:
            return String(format: NSLocalizedString("The script “%@” couldn’t be read.", comment: ""), self.url.lastPathComponent)
        case .open:
            return String(format: NSLocalizedString("The script file “%@” couldn’t be opened.", comment: ""), self.url.path)
        case .permission:
            return String(format: NSLocalizedString("The script “%@” can’t be executed because you don’t have the execute permission.", comment: ""), self.url.lastPathComponent)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
        case .permission:
            return NSLocalizedString("Check permission of the script file.", comment: "")
        default:
            return NSLocalizedString("Check the script file.", comment: "")
        }
    }
    
}



private enum ScriptError: Error {
    
    case noInputTarget
    case noOutputTarget
    
    
    var localizedDescription: String {
        
        switch self {
        case .noInputTarget:
            return NSLocalizedString("No document to get input.", comment: "")
        case .noOutputTarget:
            return NSLocalizedString("No document to put output.", comment: "")
        }
    }
    
}



// MARK: - ScriptToken

private protocol ScriptToken {
    
    static var token: String { get }
    
    init?(rawValue: String)
    
}

private extension ScriptToken {
    
    /// read type from script
    init?(scanning script: String) {
        
        let pattern = "%%%\\{" + Self.token + "=" + "(.+)" + "\\}%%%"
        let regex = try! NSRegularExpression(pattern: pattern)
        
        guard let result = regex.firstMatch(in: script, range: script.nsRange) else { return nil }
        
        let type = (script as NSString).substring(with: result.rangeAt(1))
        
        self.init(rawValue: type)
    }
    
}



// MARK: - Private Functions

private func writeToConsole(message: String, scriptName: String) {
    
    DispatchQueue.main.async {
        ConsolePanelController.shared.showWindow(nil)
        ConsolePanelController.shared.append(message: message, title: scriptName)
    }
}
