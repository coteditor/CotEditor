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
//  © 2014-2026 1024jp
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
import Shortcut
import StringUtils
import URLUtils

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
        guard let script = try? String(contentsOf: self.url, encoding: .utf8), !script.isEmpty else {
            throw ScriptFileError(.read, url: self.url)
        }
        
        weak let document = await (DocumentController.shared as! DocumentController).currentPlainTextDocument
        
        let input: String? = if let inputType = InputType(scanning: script) {
            try await Self.readInput(type: inputType, editor: document?.textView)
        } else {
            nil
        }
        
        let outputType = OutputType(scanning: script)
        let arguments: [String] = [document?.fileURL?.path(percentEncoded: false)].compactMap(\.self)
        let task = try UserUnixTask(url: self.url)
        
        if let input {
            await task.pipe(input: input)
        }
        
        try await task.execute(arguments: arguments, capturesOutput: outputType != nil)
        
        if let outputType, let output = await task.output {
            try await Self.applyOutput(output, type: outputType, editor: document?.textView)
        }
        
        if let error = await task.error {
            throw ScriptError.standardError(error)
        }
    }
}


// MARK: Private Methods

@MainActor private extension UnixScript {
    
    enum InputType: String, ScriptToken {
        
        case selection = "Selection"
        case currentLine = "CurrentLine"
        case allText = "AllText"
        
        static let token = "CotEditorXInput"
    }
    
    
    enum OutputType: String, ScriptToken {
        
        case replaceSelection = "ReplaceSelection"
        case replaceCurrentLine = "ReplaceCurrentLine"
        case replaceAllText = "ReplaceAllText"
        case insertAfterSelection = "InsertAfterSelection"
        case appendToAllText = "AppendToAllText"
        case newDocument = "NewDocument"
        case pasteboard = "Pasteboard"
        
        static let token = "CotEditorXOutput"
    }
    
    
    /// Reads the document content.
    ///
    /// - Parameters:
    ///   - type: The type of input target.
    ///   - editor: The editor to read the input.
    /// - Returns: The read string.
    /// - Throws: `ScriptError`. 
    private static func readInput(type: InputType, editor: NSTextView?) throws(ScriptError) -> String {
        
        guard let editor else { throw .noInputTarget }
        
        switch type {
            case .selection:
                return editor.selectedString
            case .currentLine:
                let string = editor.string as NSString
                return string.substring(with: string.lineRange(for: editor.selectedRange))
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
    /// - Throws: `ScriptError`.
    private static func applyOutput(_ output: String, type: OutputType, editor: NSTextView?) throws(ScriptError) {
        
        switch type {
            case .replaceSelection,
                 .replaceCurrentLine,
                 .replaceAllText,
                 .insertAfterSelection,
                 .appendToAllText:
                guard let editor else { throw .noOutputTarget }
                guard editor.isEditable else { throw .notEditable }
                
                let string = editor.string as NSString
                let replacementRange = type.range(in: string, selectedRange: editor.selectedRange)
                let selectedRange = NSRange(location: replacementRange.location, length: output.length)
                
                editor.replace(with: output, range: replacementRange, selectedRange: selectedRange)
                
            case .newDocument:
                guard !output.isEmpty else { return }  // create document only when output is available
                do {
                    try (DocumentController.shared as! DocumentController).openUntitledDocument(content: output, display: true)
                } catch {
                    throw .standardError(error.localizedDescription)
                }
                
            case .pasteboard:
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)
        }
    }
}


private extension UnixScript.OutputType {
    
    /// Returns the range to replace when applying this output type.
    ///
    /// - Parameters:
    ///   - string: The current editor content.
    ///   - selectedRange: The current selection in `string`.
    /// - Returns: The range in `string` to replace with the script output.
    func range(in string: NSString, selectedRange: NSRange) -> NSRange {
        
        switch self {
            case .replaceSelection:
                selectedRange
            case .replaceCurrentLine:
                string.lineRange(for: selectedRange)
            case .replaceAllText:
                string.range
            case .insertAfterSelection:
                NSRange(location: selectedRange.location, length: 0)
            case .appendToAllText:
                NSRange(location: string.length, length: 0)
            case .newDocument, .pasteboard:
                preconditionFailure()
        }
    }
}


// MARK: - ScriptToken

private protocol ScriptToken {
    
    static var token: String { get }
}


private extension ScriptToken where Self: RawRepresentable, Self.RawValue == String {
    
    /// Reads the type from script.
    ///
    /// - Parameter script: The script source.
    init?(scanning script: String) {
        
        let regex = try! Regex("%%%\\{\(Self.token)=(?<value>\\w+)\\}%%%", as: (Substring, value: Substring).self)
        
        guard let result = script.firstMatch(of: regex) else { return nil }
        
        self.init(rawValue: String(result.value))
    }
}
