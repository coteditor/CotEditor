/*
 
 Script.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-10-22.
 
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

class Script {
    
    let url: URL
    let name: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(url: URL, name: String) {
        
        self.url = url
        self.name = name
    }
    
    
    
    // MARK: Abstracts Methods
    
    fileprivate var editorIdentifier: String { preconditionFailure() }
    func run() throws { preconditionFailure() }
    
    
    
    // MARK: Public Methods
    
    /// open script file in an editor
    /// - throws: ScriptFileError
    func edit() throws {
        
        guard NSWorkspace.shared().open([self.url], withAppBundleIdentifier: self.editorIdentifier, additionalEventParamDescriptor: nil, launchIdentifiers: nil) else {
            // display alert if cannot open/select the script file
            throw ScriptFileError(kind: .open, url: self.url)
        }
    }
    
    
    /// reveal script file in Finder
    /// - throws: ScriptFileError
    func reveal() throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.url)
        }
        
        NSWorkspace.shared().activateFileViewerSelecting([self.url])
    }
    
    
    
    // MARK: Private Methods
    
    /// append message to console panel and show it
    fileprivate func writeToConsole(message: String) {
        
        let scriptName = self.name
        
        DispatchQueue.main.async {
            ConsolePanelController.shared.showWindow(nil)
            ConsolePanelController.shared.append(message: message, title: scriptName)
        }
    }
    
}



// MARK: -

final class AppleScript: Script {
    
    static let extensions = ["applescript", "scpt"]
    
    
    // MARK: Script Methods
    
    /// bundle identifier of appliation to edit script
    override var editorIdentifier: String {
        
        return BundleIdentifier.ScriptEditor
    }
    
    
    /// run script
    /// - throws: Error by NSUserScriptTask
    override func run() throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.url)
        }
        
        let task = try NSUserAppleScriptTask(url: self.url)
        
        task.execute(withAppleEvent: nil, completionHandler: { [weak self] (result: NSAppleEventDescriptor?, error: Error?) in
            if let error = error {
                self?.writeToConsole(message: error.localizedDescription)
            }
            })
    }
    
}



final class ShellScript: Script {
    
    static let extensions = ["sh", "pl", "php", "rb", "py", "js"]
    
    
    // MARK: Private Enum
    
    private enum OutputType: String, ScriptToken {
        
        case replaceSelection = "ReplaceSelection"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case pasteBoard = "Pasteboard"
        
        static var token = "CotEditorXOutput"
    }
    
    
    private enum InputType: String, ScriptToken {
        
        case selection = "Selection"
        case allText = "AllText"
        
        static var token = "CotEditorXInput"
    }
    
    
    
    // MARK: Script Methods
    
    /// bundle identifier of appliation to edit script
    override var editorIdentifier: String {
        
        return Bundle.main.bundleIdentifier!
    }
    
    
    /// run script
    /// - throws: ScriptFileError or Error by NSUserScriptTask
    override func run() throws {
        
        // check script file
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.url)
        }
        guard self.url.isExecutable ?? false else {
            throw ScriptFileError(kind: .permission, url: self.url)
        }
        guard let script = self.content, !script.isEmpty else {
            throw ScriptFileError(kind: .read, url: url)
        }
        
        // fetch target document
        weak var document = NSDocumentController.shared().currentDocument as? Document
        
        // read input
        let input: String?
        if let inputType = InputType(scanning: script) {
            do {
                input = try self.readInputString(type: inputType, editor: document)
            } catch let error {
                self.writeToConsole(message: error.localizedDescription)
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
        let task = try NSUserUnixTask(url: url)
        
        // set pipes
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe.fileHandleForReading
        task.standardOutput = outPipe.fileHandleForWriting
        task.standardError = errPipe.fileHandleForWriting
        
        // set input data asynchronously if available
        if let input = input, !input.isEmpty {
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
            
            guard
                let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data,
                let output = String(data: data, encoding: .utf8) else { return }
            
            do {
                try self?.applyOutput(output, editor: document, type: outputType)
            } catch let error {
                self?.writeToConsole(message: error.localizedDescription)
            }
        }
        
        // execute
        task.execute(withArguments: arguments) { [weak self] error in
            // on user cancel
            if let error = error as? POSIXError, error.code == .ENOTBLK {
                isCancelled = true
                return
            }
            
            //set error message to the sconsole
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            if let message = String(data: errorData, encoding: .utf8), !message.isEmpty {
                self?.writeToConsole(message: message)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// read content of script file
    private lazy var content: String? = {
        
        guard let data = try? Data(contentsOf: self.url) else { return nil }
        
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
    private func applyOutput(_ output: String, editor: Editable?, type: OutputType) throws {
        
        guard editor != nil || type == .pasteBoard else {
            throw ScriptError.noOutputTarget
        }
        
        switch type {
        case .replaceSelection:
            editor!.insert(string: output)
            
        case .replaceAllText:
            editor!.replaceAllString(with: output)
            
        case .insertAfterSelection:
            editor!.insertAfterSelection(string: output)
            
        case .appendToAllText:
            editor!.append(string: output)
            
        case .pasteBoard:
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            guard pasteboard.setString(output, forType: NSStringPboardType) else {
                NSBeep()
                return
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
