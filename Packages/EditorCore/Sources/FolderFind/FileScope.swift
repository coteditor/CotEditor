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
    /// - Throws: `Error.emptyValue` if a rule value is empty, or `Error.invalidRegularExpression` if a regular expression rule is invalid.
    public func validate() throws(Error) {
        
        _ = try Matcher(self)
    }
    
    
    /// Returns whether the candidate is included in the file scope.
    ///
    /// - Parameters:
    ///   - candidate: The file candidate to evaluate.
    ///   - rootURL: The root folder URL for file path rules.
    /// - Returns: `true` if the candidate is included.
    public func contains(_ candidate: FolderFind.Candidate, relativeTo rootURL: URL) -> Bool {
        
        guard !self.rules.isEmpty else { return true }
        guard let matcher = try? Matcher(self) else { return false }
        
        return matcher.contains(candidate, relativeTo: rootURL)
    }
}


public extension FileScope {
    
    enum Error: Swift.Error, Equatable, Sendable {
        
        case emptyValue
        case invalidRegularExpression(pattern: String)
    }
    
    
    struct Rule: Equatable, Codable, Sendable {
        
        public var target: Target
        public var comparison: Comparison
        public var value: String
        
        public var isValid: Bool  { (try? self.validate()) != nil }
        
        
        /// Initializes a file scope rule.
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
        public func validate() throws(Error) {
            
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
}


public extension FileScope.Rule {
    
    enum Target: String, Codable, CaseIterable, Sendable {
        
        case filename
        case filePath
        case fileExtension
    }
    
    
    /// A comparison that a file scope rule applies.
    ///
    /// String comparisons other than regular expressions are case-insensitive.
    /// Regular expressions are case-sensitive unless the pattern specifies otherwise, for example with `(?i)`.
    enum Comparison: String, Codable, CaseIterable, Sendable {
        
        case contains
        case isEqualTo
        case isNotEqualTo
        case startsWith
        case endsWith
        case matchesRegularExpression
    }
}


extension FileScope {
    
    struct Matcher {
        
        private var rules: [CompiledRule]
        
        
        /// Initializes a file scope matcher.
        ///
        /// - Parameter fileScope: The file scope to match.
        /// - Throws: `Error.emptyValue` if a rule value is empty, or `Error.invalidRegularExpression` if a regular expression rule is invalid.
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
    
    struct CompiledRule {
        
        var target: FileScope.Rule.Target
        var comparison: FileScope.Rule.Comparison
        var value: String
        var regularExpression: NSRegularExpression?
        
        
        /// Initializes a compiled file scope rule.
        ///
        /// - Parameter rule: The file scope rule to compile.
        /// - Throws: `FileScope.Error.emptyValue` if the rule value is empty, or `FileScope.Error.invalidRegularExpression` if the regular expression pattern is invalid.
        init(_ rule: FileScope.Rule) throws(FileScope.Error) {
            
            guard !rule.value.isEmpty else {
                throw .emptyValue
            }
            
            self.target = rule.target
            self.comparison = rule.comparison
            self.value = rule.value
            
            guard rule.comparison == .matchesRegularExpression else { return }
            
            do {
                self.regularExpression = try NSRegularExpression(pattern: rule.value)
            } catch {
                throw .invalidRegularExpression(pattern: rule.value)
            }
        }
        
        
        /// Returns whether the rule matches the given values.
        ///
        /// - Parameter values: The file values to evaluate.
        /// - Returns: `true` if the rule matches.
        func matches(values: FileScope.Values) -> Bool {
            
            let targetValue = values.value(for: self.target)
            
            return switch self.comparison {
                case .contains:
                    targetValue.range(of: self.value, options: .caseInsensitive) != nil
                case .isEqualTo:
                    targetValue.compare(self.value, options: .caseInsensitive) == .orderedSame
                case .isNotEqualTo:
                    targetValue.compare(self.value, options: .caseInsensitive) != .orderedSame
                case .startsWith:
                    targetValue.range(of: self.value, options: [.anchored, .caseInsensitive]) != nil
                case .endsWith:
                    targetValue.range(of: self.value, options: [.anchored, .backwards, .caseInsensitive]) != nil
                case .matchesRegularExpression:
                    self.matchesRegularExpression(in: targetValue)
            }
        }
        
        
        /// Returns whether the regular expression matches the whole target string.
        ///
        /// - Parameter string: The string to evaluate.
        /// - Returns: `true` if the regular expression matches the whole string.
        private func matchesRegularExpression(in string: String) -> Bool {
            
            guard let regularExpression else { return false }
            
            let range = NSRange(0..<string.utf16.count)
            
            return regularExpression.firstMatch(in: string, range: range)?.range == range
        }
    }
}


private extension FileScope {
    
    struct Values {
        
        var filename: String
        var filePath: String
        var fileExtension: String
        
        
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
        }
        
        
        /// Returns the value for the given target.
        ///
        /// - Parameter target: The file rule target.
        /// - Returns: The target value.
        func value(for target: Rule.Target) -> String {
            
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
