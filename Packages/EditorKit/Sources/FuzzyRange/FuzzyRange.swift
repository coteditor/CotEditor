//
//  FuzzyRange.swift
//  FuzzyRange
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2024 1024jp
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

/// A range representation that allows negative values.
///
/// When a negative value is set, it generally counts the elements from the end of the sequence.
public struct FuzzyRange: Equatable, Sendable {
    
    public var location: Int
    public var length: Int = 0
    
    
    public init(location: Int, length: Int) {
        
        self.location = location
        self.length = length
    }
}
