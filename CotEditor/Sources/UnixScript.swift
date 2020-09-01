//
//  UnixScript.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-10-28.
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

import Foundation
import AppKit.NSDocument

final class UnixScript: Script {
    
    // MARK: Script Properties
    
    let descriptor: ScriptDescriptor
    
    
    // MARK: Private Properties
    
    private lazy var content: String? = try? String(contentsOf: self.descriptor.url)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(descriptor: ScriptDescriptor) throws {
        
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
    ///
    /// - Throws: `ScriptFileError` or Error by `NSUserScriptTask`
    func run(completionHandler: @escaping (() -> Void) = {}) throws {
        
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
        weak var document = NSDocumentController.shared.currentDocument as? NSDocument & Editable
        
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
        let arguments: [String] = [document?.fileURL?.path].compactMap { $0 }
        
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
                    handle.write(chunk)
                }
                handle.closeFile()
                
                // inPipe must avoid releasing before `writeabilityHandler` is invocated
                inPipe.fileHandleForWriting.writeabilityHandler = nil
            }
        }
        
        let scriptName = self.descriptor.name
        
        // read output asynchronously for safe with huge output
        weak var observer: NSObjectProtocol?
        if let outputType = outputType {
            observer = NotificationCenter.default.addObserver(forName: .NSFileHandleReadToEndOfFileCompletion, object: outPipe.fileHandleForReading, queue: .main) { [weak document] (note: Notification) in
                NotificationCenter.default.removeObserver(observer!)
                
                guard
                    let document = document,
                    let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data,
                    let output = String(data: data, encoding: .utf8)
                    else { return }
                
                do {
                    try Self.applyOutput(output, editor: document, type: outputType)
                } catch {
                    writeToConsole(message: error.localizedDescription, scriptName: scriptName)
                }
            }
            outPipe.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
        }
        
        // execute
        task.execute(withArguments: arguments) { error in
            defer {
                completionHandler()
            }
            
            // on user cancellation
            if (error as? POSIXError)?.code == .ENOTBLK {
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
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
    
    /// return document content conforming to the input type
    ///
    /// - Throws: `ScriptError`
    private func readInputString(type: InputType, editor: Editable?) throws -> String {
        
        guard let editor = editor else { throw ScriptError.noInputTarget }
        
        switch type {
            case .selection:
                return editor.selectedString
            case .allText:
                return editor.string
        }
    }
    
    
    /// apply results conforming to the output type to the frontmost document
    ///
    /// - Throws: `ScriptError`
    private static func applyOutput(_ output: String, editor: Editable?, type: OutputType) throws {
        
        assert(Thread.isMainThread)
        
        switch type {
            case .replaceSelection:
                guard let editor = editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .replaceSelection)
            
            case .replaceAllText:
                guard let editor = editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .replaceAll)
            
            case .insertAfterSelection:
                guard let editor = editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .afterSelection)
            
            case .appendToAllText:
                guard let editor = editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .afterAll)
            
            case .newDocument:
                let document = try NSDocumentController.shared.openUntitledDocumentAndDisplay(true) as! Editable
                document.insert(string: output, at: .replaceAll)
                document.selectedRange = NSRange(0..<0)
            
            case .pasteBoard:
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(output, forType: .string)
        }
    }
    
}



// MARK: - Error

private enum ScriptError: Error {
    
    case noInputTarget
    case noOutputTarget
    
    
    var localizedDescription: String {
        
        switch self {
            case .noInputTarget:
                return "No document to get input.".localized
            case .noOutputTarget:
                return "No document to put output.".localized
        }
    }
    
}



// MARK: - ScriptToken

private protocol ScriptToken {
    
    static var token: String { get }
}


private extension ScriptToken where Self: RawRepresentable, Self.RawValue == String {
    
    /// read type from script
    init?(scanning script: String) {
        
        let pattern = "%%%\\{" + Self.token + "=" + "(.+)" + "\\}%%%"
        let regex = try! NSRegularExpression(pattern: pattern)
        
        guard let result = regex.firstMatch(in: script, range: script.nsRange) else { return nil }
        
        let type = (script as NSString).substring(with: result.range(at: 1))
        
        self.init(rawValue: type)
    }
    
}
