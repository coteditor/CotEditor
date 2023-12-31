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
//  © 2014-2023 1024jp
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

struct UnixScript: Script {
    
    // MARK: Script Properties
    
    let url: URL
    let name: String
    let shortcut: Shortcut?
    
    
    
    // MARK: Lifecycle
    
    init(url: URL, name: String, shortcut: Shortcut?) throws {
        
        self.url = url
        self.name = name
        self.shortcut = shortcut
    }
    
    
    
    // MARK: Private Enum
    
    private enum OutputType: String, ScriptToken {
        
        case replaceSelection = "ReplaceSelection"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case newDocument = "NewDocument"
        case pasteboard = "Pasteboard"
        
        static var token = "CotEditorXOutput"
    }
    
    
    private enum InputType: String, ScriptToken {
        
        case selection = "Selection"
        case allText = "AllText"
        
        static var token = "CotEditorXInput"
    }
    
    
    
    // MARK: Script Methods
    
    /// Executes the script.
    ///
    /// - Throws: `ScriptError` by the script,`ScriptFileError`, or any errors on script loading.
    func run() async throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(.existence, url: self.url)
        }
        guard try self.url.resourceValues(forKeys: [.isExecutableKey]).isExecutable ?? false else {
            throw ScriptFileError(.permission, url: self.url)
        }
        guard let script = try? String(contentsOf: self.url), !script.isEmpty else {
            throw ScriptFileError(.read, url: self.url)
        }
        
        weak var document = await NSDocumentController.shared.currentDocument as? Document
        
        let input: String?
        if let inputType = InputType(scanning: script) {
            input = try await self.readInput(type: inputType, editor: document?.textView)
        } else {
            input = nil
        }
        
        let outputType = OutputType(scanning: script)
        let arguments: [String] = [document?.fileURL?.path].compactMap { $0 }
        let task = try UserUnixTask(url: self.url)
        
        if let input {
            await task.pipe(input: input)
        }
        
        try await task.execute(arguments: arguments)
        
        if let outputType, let output = await task.output {
            try await self.applyOutput(output, type: outputType, editor: document?.textView)
        }
        
        if let error = await task.error {
            throw ScriptError.standardError(error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Reads the document content.
    ///
    /// - Parameters:
    ///   - type: The type of input target.
    ///   - editor: The editor to read the input.
    /// - Returns: The read string.
    /// - Throws: `ScriptError`
    @MainActor private func readInput(type: InputType, editor: NSTextView?) throws -> String {
        
        guard let editor else { throw ScriptError.noInputTarget }
        
        switch type {
            case .selection:
                return editor.selectedString
            case .allText:
                return editor.string
        }
    }
    
    
    /// Applies script output to the desired target.
    ///
    /// - Parameters:
    ///   - output: The output string.
    ///   - type: The type of output target.
    ///   - editor: The textView to write the output.
    /// - Throws: `ScriptError`
    @MainActor private func applyOutput(_ output: String, type: OutputType, editor: NSTextView?) throws {
        
        switch type {
            case .replaceSelection:
                guard let editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .replaceSelection)
                
            case .replaceAllText:
                guard let editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .replaceAll)
                
            case .insertAfterSelection:
                guard let editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .afterSelection)
                
            case .appendToAllText:
                guard let editor else { throw ScriptError.noOutputTarget }
                editor.insert(string: output, at: .afterAll)
                
            case .newDocument:
                try (DocumentController.shared as! DocumentController).openUntitledDocument(content: output, display: true)
                
            case .pasteboard:
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
    
    /// Reads type from script
    init?(scanning script: String) {
        
        let pattern = "%%%\\{" + Self.token + "=" + "(.+)" + "\\}%%%"
        let regex = try! NSRegularExpression(pattern: pattern)
        
        guard let result = regex.firstMatch(in: script, range: script.nsRange) else { return nil }
        
        let type = (script as NSString).substring(with: result.range(at: 1))
        
        self.init(rawValue: type)
    }
}
