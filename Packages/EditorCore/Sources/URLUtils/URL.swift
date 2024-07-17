//
//  URL.swift
//  URLUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-07-03.
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

public extension URL {
    
    /// Simply checks the reachability of the URL by ignoring errors.
    var isReachable: Bool {
        
        (try? self.checkResourceIsReachable()) == true
    }
    
    
    /// Returns relative-path components.
    ///
    /// - Note: The `baseURL` is assumed its `directoryHint` is properly set.
    ///
    /// - Parameter baseURL: The URL the relative path based on.
    /// - Returns: Path components.
    func components(relativeTo baseURL: URL) -> [String] {
        
        assert(self.isFileURL)
        assert(baseURL.isFileURL)
        
        if baseURL == self, !baseURL.hasDirectoryPath {
            return [self.lastPathComponent]
        }
        
        let filename = self.lastPathComponent
        let pathComponents = self.pathComponents.dropLast()
        let basePathComponents = baseURL.pathComponents.dropLast(baseURL.hasDirectoryPath ? 0 : 1)
        
        let sameCount = zip(basePathComponents, pathComponents).prefix(while: { $0.0 == $0.1 }).count
        let parentCount = basePathComponents.count - sameCount
        let parentComponents = [String](repeating: "..", count: parentCount)
        let diffComponents = pathComponents[sameCount...]
        
        return parentComponents + diffComponents + [filename]
    }
    
    
    /// Returns relative-path string.
    ///
    /// - Note: The `baseURL` is assumed its `directoryHint` is properly set.
    ///
    /// - Parameter baseURL: The URL the relative path based on.
    /// - Returns: A path string.
    func path(relativeTo baseURL: URL) -> String {
        
        self.components(relativeTo: baseURL).joined(separator: "/")
    }
    
    
    /// Creates an URL with a unique filename at the same directory by appending a number before the path extension.
    ///
    /// - Returns: A unique file URL, or `self` if it is already unique.
    func appendingUniqueNumber() -> URL {
        
        guard self.isReachable else { return self }
        
        let pathExtension = self.pathExtension
        let baseName = self.deletingPathExtension().lastPathComponent
        let baseURL = self.deletingLastPathComponent()
        
        return (2...).lazy
            .map { "\(baseName) \($0)" }
            .map { baseURL.appending(component: $0).appendingPathExtension(pathExtension) }
            .first { !$0.isReachable }!
    }
    
    
    /// Checks the given URL is ancestor of the receiver.
    ///
    /// - Parameter url: The child candidate URL.
    /// - Returns: `true` if the given URL is child.
    func isAncestor(of url: URL) -> Bool {
        
        let ancestorComponents = self.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let childComponents = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        
        return ancestorComponents.count < childComponents.count
            && !zip(ancestorComponents, childComponents).contains(where: !=)
    }
}


// MARK: User Domain

public extension URL {
    
    /// A temporary URL in the user domain for file replacement.
    static var itemReplacementDirectory: URL {
        
        get throws {
            try URL(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: .userDirectory, create: true)
        }
    }
}


public extension FileManager {
    
    /// Creates intermediate directories to the given URL if not available.
    ///
    /// - Parameter fileURL: The file URL.
    final func createIntermediateDirectories(to fileURL: URL) throws {
        
        try self.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
}


// MARK: Sandboxing

public extension URL {
    
    private static let homeDirectory = getpwuid(getuid())?.pointee.pw_dir.flatMap { String(cString: $0) } ?? NSHomeDirectory()
    
    
    /// A path string that replaces the user's home directory with a tilde (~) character.
    var pathAbbreviatingWithTilde: String {
        
        self.path.replacingOccurrences(of: Self.homeDirectory, with: "~", options: .anchored)
    }
}
