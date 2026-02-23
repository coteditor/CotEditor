//
//  OutlinePolicy.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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

struct OutlinePolicy: Sendable {
    
    typealias TitleFormatter = @Sendable (Syntax.Outline.Kind, String) -> String?
    
    
    struct Normalization: Sendable {
        
        var sectionMarkerKinds: Set<Syntax.Outline.Kind> = [.separator]
        var adjustSectionMarkerDepth: Bool = false
        var flattenLevels: Bool = false
        
        static let standard = Self()
        
        
        /// Returns whether the given outline kind should be treated as a section marker.
        ///
        /// - Parameters:
        ///   - kind: The outline kind to evaluate.
        /// - Returns: `true` if `kind` is configured as a section marker.
        func isSectionMarker(kind: Syntax.Outline.Kind?) -> Bool {
            
            kind.map(self.sectionMarkerKinds.contains) ?? false
        }
    }
    
    
    var titleFormatter: TitleFormatter = { _, title in title }
    var normalization: Normalization = .standard
    var ignoredDepthNodeTypes: Set<String> = []
    
    
    /// Computes the raw outline depth for a capture.
    ///
    /// - Parameters:
    ///   - components: The capture name components.
    ///   - nodeTypes: The capture node and ancestor node types from leaf to root.
    /// - Returns: The raw depth before normalization.
    func depth(captureNameComponents components: [String], ancestorNodeTypes nodeTypes: [String]) -> Int {
        
        if components.count > 2, components[1] == "heading" {
            return Self.headingLevel(from: components[2])
        }
        
        return nodeTypes
            .reduce(into: 0) { depth, nodeType in
                guard !self.ignoredDepthNodeTypes.contains(nodeType) else { return }
                depth += 1
            }
    }
    
    
    /// Normalizes outline item indentation levels according to this policy.
    ///
    /// - Parameters:
    ///   - items: The extracted outline items.
    /// - Returns: Outline items with normalized indentation levels.
    func normalize(_ items: [OutlineItem]) -> [OutlineItem] {
        
        items.normalizedLevels(policy: self.normalization)
    }
    
    
    /// Returns the semantic heading depth for a heading capture component.
    ///
    /// - Parameters:
    ///   - component: The heading component suffix such as `h1` or `title`.
    /// - Returns: The 1-based heading depth.
    private static func headingLevel(from component: String) -> Int {
        
        switch component {
            case "h1": 1
            case "h2": 2
            case "h3": 3
            case "h4": 4
            case "h5": 5
            case "h6": 6
            case "title": 1
            default: 1
        }
    }
}


extension [OutlineItem] {
    
    /// Normalizes outline levels to a stepwise hierarchy without skipped levels.
    ///
    /// - Complexity: O(n), where n is the number of outline items.
    ///
    /// - Parameter policy: The normalization policy to apply.
    func normalizedLevels(policy: OutlinePolicy.Normalization = .standard) -> [OutlineItem] {
        
        if policy.flattenLevels {
            return self.map { item in
                guard item.indent.level != nil else { return item }
                
                var normalizedItem = item
                normalizedItem.indent = .level(0)
                return normalizedItem
            }
        }
        
        var nextNonSectionDepths = [Int?](repeating: nil, count: self.count)
        if policy.adjustSectionMarkerDepth {
            var nearestDepth: Int?
            for (index, item) in self.enumerated().reversed() {
                nextNonSectionDepths[index] = nearestDepth
                if !policy.isSectionMarker(kind: item.kind) {
                    nearestDepth = item.indent.level
                }
            }
        }
        
        var depthStack: [Int] = []
        var normalizedItems: [OutlineItem] = []
        normalizedItems.reserveCapacity(self.count)
        
        for (item, nextNonSectionDepth) in zip(self, nextNonSectionDepths) {
            guard let depth = item.indent.level else {
                normalizedItems.append(item)
                continue
            }
            
            let isSectionMarker = policy.isSectionMarker(kind: item.kind)
            
            let effectiveDepth = if isSectionMarker, policy.adjustSectionMarkerDepth {
                Swift.max(depthStack.last ?? depth, depth, nextNonSectionDepth ?? depth)
            } else {
                depth
            }
            
            var normalizedItem = item
            if isSectionMarker {
                // -> Section markers should not change the active nesting context.
                var temporaryDepthStack = depthStack
                normalizedItem.indent = .level(Self.normalizeDepth(effectiveDepth, with: &temporaryDepthStack))
            } else {
                normalizedItem.indent = .level(Self.normalizeDepth(effectiveDepth, with: &depthStack))
            }
            normalizedItems.append(normalizedItem)
        }
        
        return normalizedItems
    }
    
    
    /// Normalizes a raw indentation depth into a compact 0-based level using the current depth stack.
    ///
    /// - Parameters:
    ///   - depth: The raw depth to normalize.
    ///   - depthStack: The mutable stack that tracks active raw depths.
    /// - Returns: The normalized 0-based indentation level.
    private static func normalizeDepth(_ depth: Int, with depthStack: inout [Int]) -> Int {
        
        if depthStack.isEmpty {
            depthStack.append(depth)
        } else if let lastDepth = depthStack.last {
            if depth > lastDepth {
                depthStack.append(depth)
            } else if depth < lastDepth {
                while let last = depthStack.last, last > depth {
                    depthStack.removeLast()
                }
                if depthStack.isEmpty {
                    depthStack.append(depth)
                } else {
                    depthStack[depthStack.endIndex - 1] = depth
                }
            }
        }
        
        return depthStack.count - 1
    }
}
