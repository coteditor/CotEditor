/*
 
 Comparable.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-13.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

/// compare optional arrays
func ==<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    
    switch (lhs, rhs) {
    case let (.some(l), .some(r)):
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}


/// compare optional dictionaries
func ==<K, V: Equatable>(lhs: [K: V]?, rhs: [K: V]?) -> Bool {
    
    switch (lhs, rhs) {
    case let (.some(l), .some(r)):
        return l == r
    case (.none, .none):
        return true
    default:
        return false
    }
}


/// compare dictionaries of which value is an array
func ==<K, T: Equatable>(lhs: [K: [T]], rhs: [K: [T]]) -> Bool {
    
    guard lhs.count == rhs.count else { return false }
    
    for (key, rarray) in rhs {
        guard let larray = lhs[key], rarray == larray else { return false }
    }
    
    return true
}
