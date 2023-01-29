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
//  © 2023 1024jp
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

struct Node<Value> {
    
    enum Item {
        
        case value(Value)
        case children([Node])
    }
    
    var name: String
    var item: Item
}


extension Node {
    
    var children: [Node]? {
        
        switch self.item {
            case .value:
                return nil
            case .children(let children):
                return children
        }
    }
    
    
    var value: Value? {
        
        switch self.item {
            case .value(let value):
                return value
            case .children:
                return nil
        }
    }
    
    
    /// All values including ones in the descendants.
    var flatValues: [Value] {
        
        switch self.item {
            case .value(let value):
                return [value]
            case .children(let nodes):
                return nodes.flatMap(\.flatValues)
        }
    }
}
