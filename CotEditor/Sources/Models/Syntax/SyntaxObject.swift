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
//  © 2023-2025 1024jp
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

@Observable final class SyntaxObject {
    
    struct Item<Value: Sendable & Equatable>: Identifiable {
        
        let id = UUID()
        var value: Value
    }
    
    
    typealias Highlight = Item<Syntax.Highlight>
    typealias Outline = Item<Syntax.Outline>
    typealias KeyString = Item<String>
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
    
    
    static func highlightKeyPath(for type: SyntaxType) -> KeyPath<SyntaxObject, [Highlight]> {
        
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


// MARK: Definition Conversion

extension SyntaxObject {
    
    typealias Value = Syntax
    
    
    convenience init(value: Value? = nil) {
        
        self.init()
        
        if let value {
            self.update(with: value)
        }
    }
    
    
    /// Updates the content with the given value.
    ///
    /// - Parameter value: The new value.
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
    
    
    /// The value struct.
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
