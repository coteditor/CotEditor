//
//  DefaultKey.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

class DefaultKeys: RawRepresentable, Hashable, CustomStringConvertible {
    
    let rawValue: String
    
    
    required init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    
    init(_ key: String) {
        
        self.rawValue = key
    }
    
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.rawValue)
    }
    
    
    var description: String {
        
        self.rawValue
    }
    
}



class DefaultKey<Value>: DefaultKeys {
    
    enum Error: Swift.Error {
        
        case invalidValue
    }
    
    
    func newValue(from value: Any?) throws -> Value {
        
        // -> The second Optional cast is important for in case if `Value` is already an optional type.
        guard let newValue = value as? Value ?? Optional<Any>.none as? Value else {
            throw Error.invalidValue
        }
        
        return newValue
    }
}


// specialize RawRepresentable types to use them for UserDefaults observation using UserDefaults.Publisher.
// Otherwise, the type inference for RawRepresentable doesn't work unfortunately.
final class RawRepresentableDefaultKey<Value>: DefaultKey<Value> where Value: RawRepresentable {
    
    override func newValue(from value: Any?) throws -> Value {
        
        guard let newValue = (value as? Value.RawValue).flatMap(Value.init) else {
            throw Error.invalidValue
        }
        
        return newValue
    }
}
