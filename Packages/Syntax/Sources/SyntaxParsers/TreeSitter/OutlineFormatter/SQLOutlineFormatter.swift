//
//  SQLOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import SyntaxFormat
import SwiftTreeSitter

enum SQLOutlineFormatter: TreeSitterOutlineFormatting {
    
    static func title(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        switch capture.kind {
            case .function:
                return (title: Self.functionTitle(for: match, title: source.substring(with: capture.range), source: source),
                        range: match.range ?? capture.range)
            default:
                return Self.defaultTitle(capture: capture, source: source)
        }
    }
}


private extension SQLOutlineFormatter {
    
    private static let sqlTypeNodeTypes: Set<String> = [
        "array_size_definition",
        "bigint",
        "binary",
        "bit",
        "char",
        "datetimeoffset",
        "decimal",
        "double",
        "enum",
        "float",
        "int",
        "mediumint",
        "nchar",
        "numeric",
        "nvarchar",
        "object_reference",
        "smallint",
        "time",
        "timestamp",
        "tinyint",
        "varbinary",
        "varchar",
        "keyword_bigserial",
        "keyword_boolean",
        "keyword_box2d",
        "keyword_box3d",
        "keyword_bytea",
        "keyword_date",
        "keyword_datetime",
        "keyword_datetime2",
        "keyword_geography",
        "keyword_geometry",
        "keyword_image",
        "keyword_inet",
        "keyword_interval",
        "keyword_json",
        "keyword_jsonb",
        "keyword_money",
        "keyword_name",
        "keyword_oid",
        "keyword_regclass",
        "keyword_regnamespace",
        "keyword_regproc",
        "keyword_regtype",
        "keyword_serial",
        "keyword_smalldatetime",
        "keyword_smallmoney",
        "keyword_smallserial",
        "keyword_string",
        "keyword_text",
        "keyword_timestamptz",
        "keyword_uuid",
        "keyword_xml",
    ]
    
    
    /// Builds the displayed SQL function title from a query match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - title: The raw title capture text.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed SQL function title.
    static func functionTitle(for match: QueryMatch, title: String, source: NSString) -> String {
        
        guard let arguments = match.captures(named: "outline.signature.parameters").first?.node else {
            return title
        }
        
        let argumentTypes = Self.argumentTypes(in: arguments, source: source)
        
        return "\(title)(\(argumentTypes.joined(separator: ", ")))"
    }
    
    
    /// Returns the displayed argument types for a SQL function argument list.
    ///
    /// - Parameters:
    ///   - arguments: The SQL function arguments node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed argument type list in source order.
    private static func argumentTypes(in arguments: Node, source: NSString) -> [String] {
        
        (0..<arguments.namedChildCount)
            .compactMap(arguments.namedChild(at:))
            .compactMap { Self.argumentType(for: $0, source: source) }
    }
    
    
    /// Returns the displayed type for a SQL function argument node.
    ///
    /// - Parameters:
    ///   - argument: The SQL function argument node.
    ///   - source: The source text as `NSString`.
    /// - Returns: The displayed argument type, or `nil` if it cannot be resolved.
    private static func argumentType(for argument: Node, source: NSString) -> String? {
        
        if let customType = argument.child(byFieldName: "custom_type") {
            let typeNodes = (0..<argument.namedChildCount)
                .compactMap(argument.namedChild(at:))
                .filter { $0 == customType || $0.nodeType == "array_size_definition" }
            
            return Self.typeText(for: typeNodes, source: source)
        }
        
        var typeNodes = (0..<argument.namedChildCount)
            .compactMap(argument.namedChild(at:))
            .filter { Self.sqlTypeNodeTypes.contains($0.nodeType ?? "") }
        
        // drop the leading modifier keyword node (e.g. IN, OUT, INOUT, VARIADIC)
        if typeNodes.count > 1, typeNodes[1].nodeType != "array_size_definition" {
            typeNodes.removeFirst()
        }
        
        return Self.typeText(for: typeNodes, source: source)
    }
    
    
    /// Returns the normalized type text for a list of SQL type nodes.
    ///
    /// - Parameters:
    ///   - typeNodes: The SQL type-related nodes in source order.
    ///   - source: The source text as `NSString`.
    /// - Returns: The normalized type text, or `nil` if it is empty.
    private static func typeText(for typeNodes: [Node], source: NSString) -> String? {
        
        guard let firstTypeNode = typeNodes.first else { return nil }
        
        let range = typeNodes.dropFirst()
            .reduce(firstTypeNode.range) { $0.union($1.range) }
        let type = source.substring(with: range)
            .replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return type.isEmpty ? nil : type
    }
}
