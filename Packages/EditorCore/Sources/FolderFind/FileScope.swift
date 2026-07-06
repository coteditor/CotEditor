//
//  FileScope.swift
//  FolderFind
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-06-08.
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

public import Foundation

public struct FileScope: Equatable, Codable, Sendable {
    
    public var rules: [Rule]
    
    public var isEmpty: Bool { self.rules.isEmpty }
    
    
    /// Initializes a file scope.
    ///
    /// - Parameter rules: The rules to evaluate.
    public init(rules: [Rule] = []) {
        
        self.rules = rules
    }
    
    
    /// Validates rules in the file scope.
    ///
    /// - Parameter maximumFileSize: The maximum file size in bytes the search can handle,
    ///   or `nil` to skip checking whether file size rules can actually match.
    /// - Throws: `FileScope.Error` if any rule is invalid.
    public func validate(maximumFileSize: Int? = nil) throws(Error) {
        
        _ = try Matcher(self)
        
        guard let maximumFileSize else { return }
        
        for rule in self.rules {
            try rule.validate(maximumFileSize: maximumFileSize)
        }
    }
}


public extension FileScope {
    
    enum Error: Swift.Error, Equatable, Sendable {
        
        case emptyValue
        case invalidRegularExpression(pattern: String)
        case invalidSizeValue
        case unreachableSizeValue(maximumFileSize: Int)
    }
    
    
    enum Rule: Equatable, Codable, Sendable {
        
        case text(TextRule)
        case fileSize(FileSizeRule)
        
        public var isValid: Bool  { (try? self.validate()) != nil }
        
        
        /// Validates the rule.
        ///
        /// - Parameter maximumFileSize: The maximum file size in bytes the search can handle,
        ///   or `nil` to skip checking whether file size rules can actually match.
        /// - Throws: `FileScope.Error` if the rule is invalid.
        public func validate(maximumFileSize: Int? = nil) throws(FileScope.Error) {
            
            switch self {
                case .text(let rule): try rule.validate()
                case .fileSize(let rule): try rule.validate(maximumFileSize: maximumFileSize)
            }
        }
    }
    
    
    struct TextRule: Equatable, Codable, Sendable {
        
        public var target: Target
        public var comparison: Comparison
        public var value: String
        
        
        /// Initializes a text-based file scope rule.
        ///
        /// - Parameters:
        ///   - target: The file attribute to evaluate.
        ///   - comparison: The comparison to apply.
        ///   - value: The value to compare.
        public init(target: Target, comparison: Comparison, value: String) {
            
            self.target = target
            self.comparison = comparison
            self.value = value
        }
        
        
        /// Validates the rule.
        ///
        /// - Throws: `Error.emptyValue` if the rule value is empty, or `Error.invalidRegularExpression` if the regular expression pattern is invalid.
        public func validate() throws(FileScope.Error) {
            
            guard !self.value.isEmpty else {
                throw .emptyValue
            }
            
            guard self.comparison == .matchesRegularExpression else { return }
            
            do {
                _ = try NSRegularExpression(pattern: self.value)
            } catch {
                throw .invalidRegularExpression(pattern: self.value)
            }
        }
    }
    
    
    struct FileSizeRule: Equatable, Codable, Sendable {
        
        public var comparison: Comparison
        public var value: Double
        public var unit: Unit
        
        /// The size threshold in bytes.
        public var byteCount: Int  { Int((self.value * Double(self.unit.byteFactor)).rounded()) }
        
        
        /// Initializes a file size-based file scope rule.
        ///
        /// - Parameters:
        ///   - comparison: The comparison to apply.
        ///   - value: The size value in the given unit.
        ///   - unit: The unit of the size value.
        public init(comparison: Comparison, value: Double, unit: Unit) {
            
            self.comparison = comparison
            self.value = value
            self.unit = unit
        }
        
        
        /// Validates the rule.
        ///
        /// - Parameter maximumFileSize: The maximum file size in bytes the search can handle,
        ///   or `nil` to skip checking whether the rule can actually match.
        /// - Throws: `Error.invalidSizeValue` if the size value is negative, not finite, or zero with the `isLessThan` comparison,
        ///   or `Error.unreachableSizeValue` if no file within `maximumFileSize` can match the rule.
        public func validate(maximumFileSize: Int? = nil) throws(FileScope.Error) {
            
            guard self.value >= 0, self.value.isFinite else {
                throw .invalidSizeValue
            }
            
            // a “less than zero” rule can never match
            guard self.comparison != .isLessThan || self.value > 0 else {
                throw .invalidSizeValue
            }
            
            // files beyond the maximum are not searched anyway
            if let maximumFileSize {
                let isUnreachable = switch self.comparison {
                    case .isEqualTo: self.byteCount > maximumFileSize
                    case .isLessThan: false
                    case .isGreaterThan: self.byteCount >= maximumFileSize
                }
                if isUnreachable {
                    throw .unreachableSizeValue(maximumFileSize: maximumFileSize)
                }
            }
        }
    }
}


public extension FileScope.Rule {
    
    /// Initializes a text-based file scope rule.
    ///
    /// - Parameters:
    ///   - target: The file attribute to evaluate.
    ///   - comparison: The comparison to apply.
    ///   - value: The value to compare.
    init(target: FileScope.TextRule.Target, comparison: FileScope.TextRule.Comparison, value: String) {
        
        self = .text(FileScope.TextRule(target: target, comparison: comparison, value: value))
    }
}


public extension FileScope.TextRule {
    
    enum Target: String, Codable, CaseIterable, Sendable {
        
        case filename
        case filePath
        case fileExtension
    }
    
    
    /// A comparison that a text-based file scope rule applies.
    ///
    /// String comparisons other than regular expressions are case-insensitive.
    /// Regular expressions must match the whole target value,
    /// and are case-sensitive unless the pattern specifies otherwise, for example with `(?i)`.
    enum Comparison: String, Codable, CaseIterable, Sendable {
        
        case contains
        case isEqualTo
        case isNotEqualTo
        case startsWith
        case endsWith
        case matchesRegularExpression
    }
}


public extension FileScope.FileSizeRule {
    
    enum Comparison: String, Codable, CaseIterable, Sendable {
        
        case isEqualTo
        case isLessThan
        case isGreaterThan
    }
    
    
    enum Unit: String, Codable, CaseIterable, Sendable {
        
        case bytes
        case kilobytes
        case megabytes
        
        
        /// The number of bytes the unit represents.
        var byteFactor: Int {
            
            switch self {
                case .bytes: 1
                case .kilobytes: 1_000
                case .megabytes: 1_000_000
            }
        }
    }
}


extension FileScope {
    
    struct Matcher {
        
        private var rules: [CompiledRule]
        
        
        /// Initializes a file scope matcher.
        ///
        /// - Parameter fileScope: The file scope to match.
        /// - Throws: `FileScope.Error` if any rule is invalid.
        init(_ fileScope: FileScope) throws(FileScope.Error) {
            
            self.rules = try fileScope.rules.map(CompiledRule.init)
        }
        
        
        /// Returns whether the candidate is included in the file scope.
        ///
        /// - Parameters:
        ///   - candidate: The file candidate to evaluate.
        ///   - rootURL: The root folder URL for file path rules.
        /// - Returns: `true` if the candidate is included.
        func contains(_ candidate: FolderFind.Candidate, relativeTo rootURL: URL) -> Bool {
            
            guard !self.rules.isEmpty else { return true }
            
            let values = Values(candidate: candidate, rootURL: rootURL)
            
            return self.rules.contains { $0.matches(values: values) }
        }
    }
}


private extension FileScope.Matcher {
    
    enum CompiledRule {
        
        case text(FileScope.TextRule, regularExpression: NSRegularExpression? = nil)
        case fileSize(FileScope.FileSizeRule)
        
        
        /// Initializes a compiled file scope rule.
        ///
        /// - Parameter rule: The file scope rule to compile.
        /// - Throws: `FileScope.Error` if the rule is invalid.
        init(_ rule: FileScope.Rule) throws(FileScope.Error) {
            
            try rule.validate()
            
            switch rule {
                case .text(let rule) where rule.comparison == .matchesRegularExpression:
                    let regularExpression: NSRegularExpression?
                    do {
                        // wrap in anchors to require matching the whole target value
                        regularExpression = try NSRegularExpression(pattern: #"\A(?:"# + rule.value + #")\z"#)
                    } catch {
                        throw .invalidRegularExpression(pattern: rule.value)
                    }
                    self = .text(rule, regularExpression: regularExpression)
                    
                case .text(let rule):
                    self = .text(rule)
                    
                case .fileSize(let rule):
                    self = .fileSize(rule)
            }
        }
        
        
        /// Returns whether the rule matches the given values.
        ///
        /// - Parameter values: The file values to evaluate.
        /// - Returns: `true` if the rule matches.
        func matches(values: FileScope.Values) -> Bool {
            
            switch self {
                case .text(let rule, let regularExpression):
                    let targetValue = values.value(for: rule.target)
                    return switch rule.comparison {
                        case .contains:
                            targetValue.range(of: rule.value, options: .caseInsensitive) != nil
                        case .isEqualTo:
                            targetValue.compare(rule.value, options: .caseInsensitive) == .orderedSame
                        case .isNotEqualTo:
                            targetValue.compare(rule.value, options: .caseInsensitive) != .orderedSame
                        case .startsWith:
                            targetValue.range(of: rule.value, options: [.anchored, .caseInsensitive]) != nil
                        case .endsWith:
                            targetValue.range(of: rule.value, options: [.anchored, .backwards, .caseInsensitive]) != nil
                        case .matchesRegularExpression:
                            regularExpression?.firstMatch(in: targetValue, range: NSRange(0..<targetValue.utf16.count)) != nil
                    }
                
                case .fileSize(let rule):
                    return switch rule.comparison {
                        case .isEqualTo: values.fileSize == rule.byteCount
                        case .isLessThan: values.fileSize < rule.byteCount
                        case .isGreaterThan: values.fileSize > rule.byteCount
                    }
            }
        }
    }
}


private extension FileScope {
    
    struct Values {
        
        var filename: String
        var filePath: String
        var fileExtension: String
        var fileSize: Int
        
        
        /// Initializes values from a candidate.
        ///
        /// - Parameters:
        ///   - candidate: The file candidate to read.
        ///   - rootURL: The root folder URL for relative file paths.
        init(candidate: FolderFind.Candidate, rootURL: URL) {
            
            let fileURL = candidate.fileURL.standardizedFileURL
            
            self.filename = fileURL.lastPathComponent
            self.filePath = fileURL.searchPath(under: rootURL)
            self.fileExtension = fileURL.pathExtension
            self.fileSize = candidate.fileSize
        }
        
        
        /// Returns the value for the given text rule target.
        ///
        /// - Parameter target: The text rule target.
        /// - Returns: The target value.
        func value(for target: TextRule.Target) -> String {
            
            switch target {
                case .filename: self.filename
                case .filePath: self.filePath
                case .fileExtension: self.fileExtension
            }
        }
    }
}


private extension URL {
    
    /// Returns a slash-separated path relative to the given root folder.
    ///
    /// - Parameter rootURL: The root URL.
    /// - Returns: The relative path, or the absolute path if the URL is not under the root URL.
    func searchPath(under rootURL: URL) -> String {
        
        let pathComponents = self.standardizedFileURL.pathComponents
        let rootPathComponents = rootURL.standardizedFileURL.pathComponents
        
        guard pathComponents.starts(with: rootPathComponents) else {
            return self.standardizedFileURL.path(percentEncoded: false)
        }
        
        return pathComponents.dropFirst(rootPathComponents.count).joined(separator: "/")
    }
}
