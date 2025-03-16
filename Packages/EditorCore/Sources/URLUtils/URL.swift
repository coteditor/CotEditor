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
//  © 2016-2025 1024jp
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
    
    
    /// Returns the path string relative to the given URL.
    ///
    /// - Note: The `baseURL` is assumed its `directoryHint` is properly set.
    ///
    /// - Parameter baseURL: The URL the relative path based on.
    /// - Returns: A path string.
    func path(relativeTo baseURL: URL) -> String {
        
        assert(self.isFileURL)
        assert(baseURL.isFileURL)
        
        let isDirectory = (try? baseURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? baseURL.hasDirectoryPath
        
        if baseURL == self, !isDirectory {
            return self.lastPathComponent
        }
        
        let filename = self.lastPathComponent
        let pathComponents = self.pathComponents.dropLast()
        let basePathComponents = baseURL.pathComponents.dropLast(isDirectory ? 0 : 1)
        
        let sameCount = zip(basePathComponents, pathComponents).prefix(while: { $0.0 == $0.1 }).count
        let parentCount = basePathComponents.count - sameCount
        let parentComponents = [String](repeating: "..", count: parentCount)
        let diffComponents = pathComponents[sameCount...]
        let components = parentComponents + diffComponents + [filename]
            
        return components.joined(separator: "/")
    }
    
    
    /// Checks the given URL is an ancestor of the receiver.
    ///
    /// - Parameter url: The child candidate URL.
    /// - Returns: `true` if the given URL is child.
    func isAncestor(of url: URL) -> Bool {
        
        let ancestorComponents = self.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let childComponents = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        
        guard ancestorComponents.count < childComponents.count else { return false }
        
        return zip(ancestorComponents, childComponents).allSatisfy(==)
    }
    
    
    /// Returns the URL of the first unique directory among the given URLs.
    ///
    /// - Parameter urls: The file URLs to find.
    /// - Returns: A directory URL.
    func firstUniqueDirectoryURL(in urls: [URL]) -> URL? {
        
        let duplicatedURLs = urls
            .filter { $0 != self }
            .filter { $0.lastPathComponent == self.lastPathComponent }
        
        guard !duplicatedURLs.isEmpty else { return nil }
        
        let components = duplicatedURLs
            .map { Array($0.pathComponents.reversed()) }
        
        let offset = self.pathComponents
            .reversed()
            .enumerated()
            .dropFirst()  // last path component is already checked
            .first { (index, component) in
                !components
                    .filter { $0.indices.contains(index) }
                    .compactMap { $0[index] }
                    .contains(component)
            }?
            .offset
        
        guard let offset else { return nil }
        
        return (0..<offset).reduce(into: self) { (url, _) in url.deleteLastPathComponent() }
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
    
    private static let homeDirectory = getpwuid(getuid())?.pointee.pw_dir.map { String(cString: $0) } ?? NSHomeDirectory()
    
    
    /// A path string that replaces the user's home directory with a tilde (~) character.
    var pathAbbreviatingWithTilde: String {
        
        self.path(percentEncoded: false).replacingOccurrences(of: Self.homeDirectory, with: "~", options: .anchored)
    }
}
