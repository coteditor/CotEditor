//
//  PropertyListValue.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

/// A type-safe enum that represents all valid property list value types.
///
/// This is used to safely encode and decode property lists while conforming to `Sendable`.
enum PropertyListValue: Equatable, Sendable {
    
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case data(Data)
    case date(Date)
    case array([PropertyListValue])
    case dictionary([String: PropertyListValue])
    
    
    init(_ any: Any) {
        
        self = switch any {
            case let value as String: .string(value)
            case let value as Bool: .bool(value)
            case let value as Int: .int(value)
            case let value as Double: .double(value)
            case let value as Data: .data(value)
            case let value as Date: .date(value)
            case let value as [Any]: .array(value.map(PropertyListValue.init))
            case let value as [String: Any]: .dictionary(value.mapValues(PropertyListValue.init))
            default: fatalError()
        }
    }
    
    
    var any: any Sendable {
        
        switch self {
            case .string(let value): value
            case .bool(let value): value
            case .int(let value): value
            case .double(let value): value
            case .data(let value): value
            case .date(let value): value
            case .array(let value): value.map(\.any)
            case .dictionary(let value): value.mapValues(\.any)
        }
    }
}
