//
//  Node.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-30.
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

struct Node<Value>: Identifiable {
    
    enum Item {
        
        case value(Value)
        case children([Node])
    }
    
    let id = UUID()
    
    var name: String
    var item: Item
}


extension Node.Item: Equatable where Value: Equatable { }
extension Node: Equatable where Value: Equatable { }


extension Node {
    
    var children: [Node]? {
        
        get {
            switch self.item {
                case .value:
                    nil
                case .children(let children):
                    children
            }
        }
        
        set {
            guard let newValue else { return assertionFailure() }
            
            self.item = .children(newValue)
        }
    }
    
    
    var value: Value? {
        
        get {
            switch self.item {
                case .value(let value):
                    value
                case .children:
                    nil
            }
        }
        
        set {
            guard let newValue else { return assertionFailure() }
            
            self.item = .value(newValue)
        }
    }
    
    
    /// All values including ones in the descendants.
    var flatValues: [Value] {
        
        switch self.item {
            case .value(let value):
                [value]
            case .children(let nodes):
                nodes.flatMap(\.flatValues)
        }
    }
}
