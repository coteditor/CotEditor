//
//  DefaultKey.swift
//  Defaults
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

public class DefaultKeys: RawRepresentable {
    
    public final let rawValue: String
    
    
    public required init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    
    public init(_ key: String) {
        
        self.rawValue = key
    }
}


extension DefaultKeys: Hashable {
    
    public final func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.rawValue)
    }
}


extension DefaultKeys: CustomStringConvertible {
    
    public final var description: String {
        
        self.rawValue
    }
}


public enum DefaultKeyError: Error, Sendable {
        
        case invalidValue
}


public class DefaultKey<Value>: DefaultKeys, @unchecked Sendable {
    
    public func newValue(from value: Any?) throws(DefaultKeyError) -> Value {
        
        // -> The second Optional cast is important for in case if `Value` is already an optional type.
        guard let newValue = value as? Value ?? Optional<Any>.none as? Value else {
            throw .invalidValue
        }
        
        return newValue
    }
}


// Specialize RawRepresentable types to use them for UserDefaults observation using UserDefaults.Publisher.
// Otherwise, the type inference for RawRepresentable doesn't work unfortunately.
public final class RawRepresentableDefaultKey<Value>: DefaultKey<Value>, @unchecked Sendable where Value: RawRepresentable {
    
    public override func newValue(from value: Any?) throws(DefaultKeyError) -> Value {
        
        guard let newValue = (value as? Value.RawValue).flatMap(Value.init) else {
            throw .invalidValue
        }
        
        return newValue
    }
}
