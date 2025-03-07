//
//  SyntaxObject.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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
import Observation
import Syntax

@Observable final class SyntaxObject {
    
    typealias Highlight = SyntaxObjectHighlight
    typealias Outline = SyntaxObjectOutline
    typealias KeyString = SyntaxObjectKeyString
    typealias Comment = Syntax.Comment
    typealias Metadata = Syntax.Metadata
    
    
    var kind: Syntax.Kind = .general
    
    var keywords: [Highlight] = []
    var commands: [Highlight] = []
    var types: [Highlight] = []
    var attributes: [Highlight] = []
    var variables: [Highlight] = []
    var values: [Highlight] = []
    var numbers: [Highlight] = []
    var strings: [Highlight] = []
    var characters: [Highlight] = []
    var comments: [Highlight] = []
    
    var commentDelimiters: Comment = Comment()
    var outlines: [Outline] = []
    var completions: [KeyString] = []
    
    var filenames: [KeyString] = []
    var extensions: [KeyString] = []
    var interpreters: [KeyString] = []
    
    var metadata: Metadata = Metadata()
    
    
    static func highlightKeyPath(for type: SyntaxType) -> WritableKeyPath<SyntaxObject, [Highlight]> {
        
        switch type {
            case .keywords: \.keywords
            case .commands: \.commands
            case .types: \.types
            case .attributes: \.attributes
            case .variables: \.variables
            case .values: \.values
            case .numbers: \.numbers
            case .strings: \.strings
            case .characters: \.characters
            case .comments: \.comments
        }
    }
}


struct SyntaxObjectHighlight: Identifiable {
    
    let id = UUID()
    
    var begin: String = ""
    var end: String?
    var isRegularExpression: Bool = false
    var ignoreCase: Bool = false
    var description: String?
}


struct SyntaxObjectOutline: Identifiable {
    
    let id = UUID()
    
    var pattern: String = ""
    var template: String = ""
    var ignoreCase: Bool = false
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var description: String?
}


struct SyntaxObjectKeyString: Identifiable {
    
    let id = UUID()
    
    var string: String = ""
}


// MARK: Definition Conversion

extension SyntaxObject {
    
    typealias Value = Syntax
    
    convenience init(value: Value? = nil) {
        
        self.init()
        
        if let value {
            self.update(with: value)
        }
    }
    
    
    func update(with value: Value) {
        
        self.kind = value.kind
        
        self.keywords = value.keywords.map { .init(value: $0) }
        self.commands = value.commands.map { .init(value: $0) }
        self.types = value.types.map { .init(value: $0) }
        self.attributes = value.attributes.map { .init(value: $0) }
        self.variables = value.variables.map { .init(value: $0) }
        self.values = value.values.map { .init(value: $0) }
        self.numbers = value.numbers.map { .init(value: $0) }
        self.strings = value.strings.map { .init(value: $0) }
        self.characters = value.characters.map { .init(value: $0) }
        self.comments = value.comments.map { .init(value: $0) }
        
        self.commentDelimiters = value.commentDelimiters
        self.outlines = value.outlines.map { .init(value: $0) }
        self.completions = value.completions.map { .init(value: $0) }
        
        self.filenames = value.filenames.map { .init(value: $0) }
        self.extensions = value.extensions.map { .init(value: $0) }
        self.interpreters = value.interpreters.map { .init(value: $0) }
        
        self.metadata = value.metadata
    }
    
    
    var value: Value {
        
        Value(kind: self.kind,
              keywords: self.keywords.map(\.value),
              commands: self.commands.map(\.value),
              types: self.types.map(\.value),
              attributes: self.attributes.map(\.value),
              variables: self.variables.map(\.value),
              values: self.values.map(\.value),
              numbers: self.numbers.map(\.value),
              strings: self.strings.map(\.value),
              characters: self.characters.map(\.value),
              comments: self.comments.map(\.value),
              
              commentDelimiters: self.commentDelimiters,
              outlines: self.outlines.map(\.value),
              completions: self.completions.map(\.value),
              
              filenames: self.filenames.map(\.value),
              extensions: self.extensions.map(\.value),
              interpreters: self.interpreters.map(\.value),
              
              metadata: self.metadata)
    }
}


extension SyntaxObjectHighlight {
    
    typealias Value = Syntax.Highlight
    
    init(value: Value) {
        
        self.begin = value.begin
        self.end = value.end
        self.isRegularExpression = value.isRegularExpression
        self.ignoreCase = value.ignoreCase
        self.description = value.description
    }
    
    
    var value: Value {
        
        Value(begin: self.begin,
              end: self.end,
              isRegularExpression: self.isRegularExpression,
              ignoreCase: self.ignoreCase,
              description: self.description)
    }
}


extension SyntaxObjectOutline {
    
    typealias Value = Syntax.Outline
    
    init(value: Value) {
        
        self.pattern = value.pattern
        self.template = value.template
        self.ignoreCase = value.ignoreCase
        self.bold = value.bold
        self.italic = value.italic
        self.underline = value.underline
        self.description = value.description
    }
    
    
    var value: Value {
        
        Value(pattern: self.pattern,
              template: self.template,
              ignoreCase: self.ignoreCase,
              bold: self.bold,
              italic: self.italic,
              underline: self.underline,
              description: self.description)
    }
}


extension SyntaxObjectKeyString {
    
    typealias Value = String
    
    init(value: Value) {
        
        self.string = value
    }
    
    
    var value: Value {
        
        self.string
    }
}


extension SyntaxObjectHighlight: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        lhs.begin == rhs.begin &&
        lhs.end == rhs.end &&
        lhs.isRegularExpression == rhs.isRegularExpression &&
        lhs.ignoreCase == rhs.ignoreCase
    }
}
