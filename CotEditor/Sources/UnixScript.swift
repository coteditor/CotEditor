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
    
    let url: URL
    let name: String
    
    
    // MARK: Private Properties
    
    private lazy var content: String? = try? String(contentsOf: self.url)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(url: URL, name: String) throws {
        
        self.url = url
        self.name = name
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
    
    /// Execute the script.
    ///
    /// - Parameters:
    ///   - completionHandler: The completion handler block that returns a script error if any.
    ///   - error: The `ScriptError` by the script.
    /// - Throws: `ScriptFileError`
    func run(completionHandler: @escaping ((_ error: ScriptError?) -> Void)) throws {
        
        // check script file
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.url)
        }
        guard try self.url.resourceValues(forKeys: [.isExecutableKey]).isExecutable ?? false else {
            throw ScriptFileError(kind: .permission, url: self.url)
        }
        guard let script = self.content, !script.isEmpty else {
            throw ScriptFileError(kind: .read, url: self.url)
        }
        
        // fetch target document
        weak var document = NSDocumentController.shared.currentDocument as? NSDocument & Editable
        
        // read input
        let input: String?
        if let inputType = InputType(scanning: script) {
            do {
                input = try Self.readInput(type: inputType, editor: document)
            } catch let error as ScriptError {
                return completionHandler(error)
            } catch {
                preconditionFailure()
            }
        } else {
            input = nil
        }
        
        // get output type
        let outputType = OutputType(scanning: script)
        
        // prepare file path as argument if available
        let arguments: [String] = [document?.fileURL?.path].compactMap { $0 }
        
        // create task
        let task = try NSUserUnixTask(url: self.url)
        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe.fileHandleForReading
        task.standardOutput = outPipe.fileHandleForWriting
        task.standardError = errPipe.fileHandleForWriting
        
        // set input data if available
        if let data = input?.data(using: .utf8) {
            inPipe.fileHandleForWriting.writeabilityHandler = { (handle) in
                // write input data chunk by chunk
                // -> to avoid freeze by a huge input data, whose length is more than 65,536 (2^16).
                for chunk in data.components(length: 65_536) {
                    handle.write(chunk)
                }
                
                // inPipe must avoid releasing before `writeabilityHandler` is invocated
                inPipe.fileHandleForWriting.writeabilityHandler = nil
            }
        }
        
        // read output asynchronously for safe with huge output
        var outputData = Data()
        if outputType != nil {
            outPipe.fileHandleForReading.readabilityHandler = { (handle) in
                outputData.append(handle.availableData)
            }
        }
        
        // execute
        task.execute(withArguments: arguments) { [weak document, name = self.name] (error) in
            outPipe.fileHandleForReading.readabilityHandler = nil
            
            // on user cancellation
            if (error as? POSIXError)?.code == .ENOTBLK {
                return completionHandler(nil)
            }
            
            // apply output
            if let outputType = outputType, let output = String(data: outputData, encoding: .utf8) {
                DispatchQueue.main.async {
                    do {
                        try Self.applyOutput(output, editor: document, type: outputType)
                    } catch {
                        Console.shared.show(message: error.localizedDescription, title: name)
                    }
                }
            }
            
            // obtain standard error
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8)
            let scriptError = errorString.flatMap { $0.isEmpty ? nil : ScriptError.standardError($0) }
            
            completionHandler(scriptError)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Read the document content.
    ///
    /// - Parameters:
    ///   - type: The type of input target.
    ///   - editor: The editor to read the input.
    /// - Returns: The read string.
    /// - Throws: `ScriptError`
    private static func readInput(type: InputType, editor: Editable?) throws -> String {
        
        guard let editor = editor else { throw ScriptError.noInputTarget }
        
        switch type {
            case .selection:
                return editor.selectedString
            case .allText:
                return editor.string
        }
    }
    
    
    /// Apply script output to the desired target.
    ///
    /// - Parameters:
    ///   - output: The output string.
    ///   - editor: The editor to write the output.
    ///   - type: The type of output target.
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
                let document = try NSDocumentController.shared.openUntitledDocumentAndDisplay(true) as! any Editable
                document.insert(string: output, at: .replaceAll)
                document.selectedRange = NSRange(0..<0)
            
            case .pasteBoard:
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)
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
