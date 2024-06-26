//
//  OutlineItem.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-12.
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

import Foundation

public struct OutlineItem: Equatable, Sendable, Identifiable {
    
    public struct Style: OptionSet, Sendable {
        
        public let rawValue: Int
        
        public static let bold      = Self(rawValue: 1 << 0)
        public static let italic    = Self(rawValue: 1 << 1)
        public static let underline = Self(rawValue: 1 << 2)
        
        
        public init(rawValue: Int) {
            
            self.rawValue = rawValue
        }
    }
    
    
    public let id = UUID()
    
    public var title: String
    public var range: NSRange
    public var style: Style
    
    public var isSeparator: Bool  { self.title == .separator }
    
    
    public init(title: String, range: NSRange, style: Style = []) {
        
        self.title = title
        self.range = range
        self.style = style
    }
    
    
    public static func separator(range: NSRange) -> Self {
        
        self.init(title: .separator, range: range)
    }
}


extension BidirectionalCollection<OutlineItem> {
    
    /// Returns the element for the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The corresponding outline item, or `nil` if not exist.
    public func item(at location: Int) -> Element? {
        
        self.last { $0.range.location <= location && !$0.isSeparator }
    }
    
    
    /// Returns the previous non-separator element from the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The previous outline item, or `nil` if not exist.
    public func previousItem(for range: NSRange) -> OutlineItem? {
        
        guard let currentIndex = self.indexOfItem(at: range.lowerBound) else { return nil }
        
        return self[..<currentIndex].last { !$0.isSeparator }
    }
    
    
    /// Returns the next non-separator element from the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The next outline item, or `nil` if not exist.
    public func nextItem(for range: NSRange) -> OutlineItem? {
        
        if let first = self.first(where: { !$0.isSeparator }), range.upperBound < first.range.location {
            return first
        }
        
        guard
            let currentIndex = self.indexOfItem(at: range.upperBound),
            currentIndex <= self.endIndex
        else { return nil }
        
        return self[self.index(after: currentIndex)...].first { !$0.isSeparator }
    }
    
    
    /// Returns the index of element for the given range.
    ///
    /// - Parameter range: The character range to refer.
    /// - Returns: The index of the corresponding outline item, or `nil` if not exist.
    private func indexOfItem(at location: Int) -> Index? {
        
        self.lastIndex { $0.range.location <= location && !$0.isSeparator }
    }
}
