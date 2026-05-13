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
//  © 2025-2026 1024jp
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
    
    
    /// Creates a property list value from a raw property list object.
    ///
    /// - Parameter any: The raw property list object.
    init(_ any: Any) {
        
        guard let value = Self(propertyList: any) else {
            fatalError()
        }
        
        self = value
    }
    
    
    /// Creates a property list value from a raw object if it is supported.
    ///
    /// - Parameter any: The raw object.
    init?(propertyList any: Any) {
        
        switch any {
            case let value as String:
                self = .string(value)
                
            case let value as NSNumber:
                self = if CFGetTypeID(value) == CFBooleanGetTypeID() {
                    .bool(value.boolValue)
                } else if CFNumberIsFloatType(value) {
                    .double(value.doubleValue)
                } else {
                    .int(value.intValue)
                }
                
            case let value as Data:
                self = .data(value)
                
            case let value as Date:
                self = .date(value)
                
            case let value as [Any]:
                var array: [Self] = []
                for element in value {
                    guard let value = Self(propertyList: element) else { return nil }
                    array.append(value)
                }
                self = .array(array)
                
            case let value as [String: Any]:
                var dictionary: [String: Self] = [:]
                for (key, element) in value {
                    guard let value = Self(propertyList: element) else { return nil }
                    dictionary[key] = value
                }
                self = .dictionary(dictionary)
                
            default:
                return nil
        }
    }
    
    
    /// The raw property list representation.
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
