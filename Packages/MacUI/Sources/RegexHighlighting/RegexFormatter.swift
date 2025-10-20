//
//  RegexFormatter.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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

public import Foundation
import AppKit
import Invisible

public final class RegexFormatter<Color: Sendable>: Formatter {
    
    // MARK: Public Properties
    
    public let theme: RegexTheme<Color>
    public var mode: RegexParseMode = .search
    public var parsesRegularExpression: Bool = true
    
    
    // MARK: Private Properties
    
    private let invisibles: [Invisible] = [.newLine, .tab, .fullwidthSpace]
    
    
    // MARK: Lifecycle
    
    /// Instantiates the RegexFormatter.
    ///
    /// - Parameters:
    ///   - theme: The coloring theme.
    public init(theme: RegexTheme<Color>) {
        
        self.theme = theme
        
        super.init()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Formatter Function
    
    /// Converts to plain string.
    public override func string(for obj: Any?) -> String? {
        
        obj as? String
    }
    
    
    /// Creates attributed string from object.
    public override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        guard let string = self.string(for: obj) else { return nil }
        
        let attributedString = NSMutableAttributedString(string: string, attributes: attrs)
        
        guard !string.isEmpty else { return attributedString }
        
        if self.parsesRegularExpression {
            // validate regex pattern
            switch self.mode {
                case .search:
                    do {
                        _ = try NSRegularExpression(pattern: string)
                    } catch {
                        return attributedString
                    }
                case .replacement: break
            }
            
            // syntax highlight
            for type in RegexSyntaxType.allCases.reversed() {
                let color = self.theme.color(for: type)
                for range in type.ranges(in: string, mode: self.mode) {
                    attributedString.addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }
        
        // replace invisible characters with visible symbols
        if !self.invisibles.isEmpty {
            let attributes = (attrs ?? [:]).merging([.foregroundColor: self.theme.invisible]) { $1 }
            
            for (index, codeUnit) in string.utf16.enumerated() {
                guard
                    let invisible = Invisible(codeUnit: codeUnit),
                    self.invisibles.contains(invisible)
                else { continue }
                
                let attributedInvisible = NSAttributedString(string: String(invisible.symbol), attributes: attributes)
                attributedString.replaceCharacters(in: NSRange(location: index, length: 1), with: attributedInvisible)
            }
        }
        
        return attributedString
    }
    
    
    /// Formats backwards.
    public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        obj?.pointee = string as AnyObject
        
        return true
    }
}
