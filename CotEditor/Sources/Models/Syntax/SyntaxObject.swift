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
//  © 2023-2026 1024jp
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
import Syntax
import StringUtils

@Observable final class SyntaxObject {
    
    struct Item<Value: Sendable & Equatable>: Identifiable {
        
        let id = UUID()
        var value: Value
    }
    
    
    typealias Highlight = Item<Syntax.Highlight>
    typealias Outline = Item<Syntax.Outline>
    typealias KeyString = Item<String>
    typealias InlineComment = Item<Syntax.Comment.Inline>
    typealias BlockComment = Item<Pair<String>>
    typealias BlockIndent = Item<Pair<String>>
    typealias CompletionWord = Item<Syntax.CompletionWord>
    typealias Metadata = Syntax.Metadata
    
    
    @Observable final class Highlights {
        
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
        
        
        func values(for type: SyntaxType) -> [Syntax.Highlight] {
            
            switch type {
                case .keywords: self.keywords.map(\.value)
                case .commands: self.commands.map(\.value)
                case .types: self.types.map(\.value)
                case .attributes: self.attributes.map(\.value)
                case .variables: self.variables.map(\.value)
                case .values: self.values.map(\.value)
                case .numbers: self.numbers.map(\.value)
                case .strings: self.strings.map(\.value)
                case .characters: self.characters.map(\.value)
                case .comments: self.comments.map(\.value)
            }
        }
    }
    
    
    var kind: Syntax.Kind = .general
    
    var highlights: Highlights = Highlights()
    
    var inlineComments: [InlineComment] = []
    var blockComments: [BlockComment] = []
    var indentations: [BlockIndent] = []
    var lexicalRules: Syntax.LexicalRules = .default
    
    var outlines: [Outline] = []
    var completions: [CompletionWord] = []
    
    var filenames: [KeyString] = []
    var extensions: [KeyString] = []
    var interpreters: [KeyString] = []
    
    var metadata: Metadata = Metadata()
}


// MARK: Definition Conversion

extension SyntaxObject {
    
    typealias Value = Syntax
    
    
    convenience init(value: Value?) {
        
        self.init()
        
        if let value {
            self.update(with: value)
        }
    }
    
    
    /// The value struct.
    var value: Value {
        
        Value(kind: self.kind,
              
              fileMap: .init(
                extensions: self.extensions.map(\.value),
                filenames: self.filenames.map(\.value),
                interpreters: self.interpreters.map(\.value)
              ),
              
              highlights: SyntaxType.allCases.reduce(into: [:]) { value, type in
                  value[type] = self.highlights.values(for: type)
              },
              
              outlines: self.outlines.map(\.value),
              
              commentDelimiters: Syntax.Comment(
                inlines: self.inlineComments.map(\.value),
                blocks: self.blockComments.map(\.value)
              ),
              indentation: .init(blockDelimiters: self.indentations.map(\.value)),
              lexicalRules: self.lexicalRules,
              
              completions: self.completions.map(\.value),
              
              metadata: self.metadata)
    }
    
    
    /// Updates the content with the given value.
    ///
    /// - Parameter value: The new value.
    private func update(with value: Value) {
        
        self.kind = value.kind
        
        self.highlights.update(with: value.highlights)
        
        self.outlines = value.outlines.map { .init(value: $0) }
        
        self.inlineComments = value.commentDelimiters.inlines.map { .init(value: $0) }
        self.blockComments = value.commentDelimiters.blocks.map { .init(value: $0) }
        self.indentations = value.indentation.blockDelimiters.map { .init(value: $0) }
        self.lexicalRules = value.lexicalRules
        
        self.completions = value.completions.map { .init(value: $0) }
        
        self.extensions = value.fileMap.extensions?.map { .init(value: $0) } ?? []
        self.filenames = value.fileMap.filenames?.map { .init(value: $0) } ?? []
        self.interpreters = value.fileMap.interpreters?.map { .init(value: $0) } ?? []
        
        self.metadata = value.metadata
    }
}


private extension SyntaxObject.Highlights {
    
    typealias Value = [SyntaxType: [Syntax.Highlight]]
    
    
    /// Updates the content with the given value.
    ///
    /// - Parameter value: The new value.
    func update(with value: Value) {
        
        self.keywords = value[.keywords]?.map { .init(value: $0) } ?? []
        self.commands = value[.commands]?.map { .init(value: $0) } ?? []
        self.types = value[.types]?.map { .init(value: $0) } ?? []
        self.attributes = value[.attributes]?.map { .init(value: $0) } ?? []
        self.variables = value[.variables]?.map { .init(value: $0) } ?? []
        self.values = value[.values]?.map { .init(value: $0) } ?? []
        self.numbers = value[.numbers]?.map { .init(value: $0) } ?? []
        self.strings = value[.strings]?.map { .init(value: $0) } ?? []
        self.characters = value[.characters]?.map { .init(value: $0) } ?? []
        self.comments = value[.comments]?.map { .init(value: $0) } ?? []
    }
}


extension SyntaxObject.Item<Syntax.Highlight> {
    
    init() {
        
        self.value = .init()
    }
}


extension SyntaxObject.Item<Syntax.Outline> {
    
    init() {
        
        self.value = .init()
    }
}


extension SyntaxObject.Item<String> {
    
    init() {
        
        self.value = .init()
    }
}


extension SyntaxObject.InlineComment {
    
    init() {
        
        self.value = .init()
    }
}


extension SyntaxObject.BlockComment {
    
    init() {
        
        self.value = .init("", "")
    }
}


extension SyntaxObject.CompletionWord {
    
    init() {
        
        self.value = .init()
    }
}
