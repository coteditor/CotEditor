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
//  © 2014-2022 1024jp
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
    /// - Throws: `ScriptError` by the script,`ScriptFileError`, or any errors on script loading.
    func run() async throws {
        
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
        weak var document = await NSDocumentController.shared.currentDocument as? Document
        
        // read input
        let input: String?
        if let inputType = InputType(scanning: script) {
            input = try await self.readInput(type: inputType, editor: document?.textView)
        } else {
            input = nil
        }
        
        // get output type
        let outputType = OutputType(scanning: script)
        
        // prepare file path as argument if available
        let arguments: [String] = [document?.fileURL?.path].compactMap { $0 }
        
        // create task
        let task = try UserUnixTask(url: self.url)
        
        if let input = input {
            await task.pipe(input: input)
        }
        
        // execute
        try await task.execute(arguments: arguments)
        
        // apply output
        if let outputType = outputType, let output = await task.output {
            do {
                try await self.applyOutput(output, type: outputType, editor: document?.textView)
            } catch {
                await Console.shared.show(message: error.localizedDescription, title: self.name)
            }
        }
        
        // obtain standard error
        if let error = await task.error {
            throw ScriptError.standardError(error)
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
    @MainActor private func readInput(type: InputType, editor: NSTextView?) throws -> String {
        
        guard let editor = editor else { throw ScriptError.noInputTarget }
        
        switch type {
            case .selection:
                return (editor.string as NSString).substring(with: editor.selectedRange)
            case .allText:
                return editor.string
        }
    }
    
    
    /// Apply script output to the desired target.
    ///
    /// - Parameters:
    ///   - output: The output string.
    ///   - type: The type of output target.
    ///   - editor: The textView to write the output.
    /// - Throws: `ScriptError`
    @MainActor private func applyOutput(_ output: String, type: OutputType, editor: NSTextView?) throws {
        
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
                try (DocumentController.shared as! DocumentController).openUntitledDocument(contents: output, display: true)
            
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
