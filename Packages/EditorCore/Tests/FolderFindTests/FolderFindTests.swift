//
//  FolderFindTests.swift
//  FolderFindTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
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
import Testing
import TextFind
import UniformTypeIdentifiers
@testable import FolderFind

struct FolderFindTests {
    
    @Test func textualSearchGroupsMatchesByFile() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nhay\nneedle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        try FileManager.default.createDirectory(at: rootURL.appending(path: "Subfolder", directoryHint: .isDirectory), withIntermediateDirectories: true)
        try Data("hay\nneedle\n".utf8).write(to: rootURL.appending(path: "Subfolder/b.txt"))
        try Data("hay\n".utf8).write(to: rootURL.appending(path: "c.txt"))
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        #expect(summary.metrics.findString == "needle")
        #expect(summary.metrics.searchedFileCount == 3)
        #expect(summary.metrics.skippedFileCount == 0)
        #expect(summary.metrics.matchedFileCount == 2)
        #expect(summary.metrics.matchCount == 3)
        #expect(summary.files.map(\.filename) == ["b.txt", "a.txt"])
        #expect(summary.files.map(\.directoryPathComponents) == [["Subfolder"], []])
        #expect(summary.files[0].matches.map(\.range.location) == [4])
        #expect(summary.files[1].matches.map(\.range.location) == [0, 11])
        
        let fileResult = try #require(summary.result(for: .file(summary.files[0].id)))
        #expect(fileResult.file == summary.files[0])
        #expect(fileResult.match == nil)
        
        let matchResult = try #require(summary.result(for: .match(fileID: summary.files[1].id,
                                                                   matchID: summary.files[1].matches[1].id)))
        #expect(matchResult.file == summary.files[1])
        #expect(matchResult.match == summary.files[1].matches[1])
        
        #expect(summary.result(for: .match(fileID: summary.files[0].id, matchID: UUID())) == nil)
    }
    
    
    @Test func progressTracksSearchMetrics() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nneedle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        try Data("hay\nneedle\n".utf8).write(to: rootURL.appending(path: "b.txt"))
        try Data("hay\n".utf8).write(to: rootURL.appending(path: "c.txt"))
        try Data([0xFF]).write(to: rootURL.appending(path: "invalid.txt"))
        
        let progress = FolderFindProgress(findString: "needle")
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"), progress: progress)
        
        #expect(progress.snapshot.findString == "needle")
        #expect(progress.snapshot == summary.metrics)
    }
    
    
    @Test func progressIsNotUpdatedForInvalidQuery() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let progress = FolderFindProgress(findString: "")
        
        await #expect(throws: TextFind.Error.emptyFindString) {
            try await FolderFind.find(in: rootURL, query: Self.query(""), progress: progress)
        }
        
        #expect(progress.snapshot.matchCount == 0)
        #expect(progress.snapshot.matchedFileCount == 0)
        #expect(progress.snapshot.searchedFileCount == 0)
        #expect(progress.snapshot.skippedFileCount == 0)
    }
    
    
    @Test func summaryRemovesSelectedResult() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nhay\nneedle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        try Data("hay\nneedle\n".utf8).write(to: rootURL.appending(path: "b.txt"))
        
        var summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        let firstFile = try #require(summary.files.first { $0.filename == "a.txt" })
        let firstMatch = try #require(firstFile.matches.first)
        
        summary.removeResult(for: .match(fileID: firstFile.id, matchID: firstMatch.id))
        
        let updatedFirstFile = try #require(summary.files.first { $0.filename == "a.txt" })
        #expect(updatedFirstFile.matches.map(\.range.location) == [11])
        #expect(summary.metrics.matchedFileCount == 2)
        #expect(summary.metrics.matchCount == 2)
        
        let secondFile = try #require(summary.files.first { $0.filename == "b.txt" })
        let onlyMatch = try #require(secondFile.matches.first)
        
        summary.removeResult(for: .match(fileID: secondFile.id, matchID: onlyMatch.id))
        
        #expect(summary.files.map(\.filename) == ["a.txt"])
        #expect(summary.metrics.matchedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
        
        summary.removeResult(for: .file(updatedFirstFile.id))
        
        #expect(summary.files.isEmpty)
        #expect(summary.metrics.matchedFileCount == 0)
        #expect(summary.metrics.matchCount == 0)
    }
    
    
    @Test func summaryUpdatesMatchRangesAfterEditing() throws {
        
        let fileURL = URL(fileURLWithPath: "/tmp/a.txt").standardizedFileURL
        let otherFileURL = URL(fileURLWithPath: "/tmp/b.txt").standardizedFileURL
        var summary = FolderFind.Summary(metrics: .init(findString: "needle"),
                                         files: [
                                            FolderFind.FileResult(fileURL: fileURL, directoryPathComponents: [],
                                                                  matches: [
                                                                    FolderFind.Match(range: NSRange(location: 10, length: 6), line: "first needle", rangeInLine: NSRange(location: 6, length: 6)),
                                                                    FolderFind.Match(range: NSRange(location: 30, length: 6), line: "second needle", rangeInLine: NSRange(location: 7, length: 6)),
                                                                  ]),
                                            FolderFind.FileResult(fileURL: otherFileURL, directoryPathComponents: [],
                                                                  matches: [
                                                                    FolderFind.Match(range: NSRange(location: 10, length: 6), line: "other needle", rangeInLine: NSRange(location: 6, length: 6)),
                                                                  ]),
                                         ])
        let firstID = summary.files[0].matches[0].id
        let secondID = summary.files[0].matches[1].id
        let line = summary.files[0].matches[0].line
        let rangeInLine = summary.files[0].matches[0].rangeInLine
        
        summary.updateMatchRanges(in: fileURL, editedRange: NSRange(location: 3, length: 4), changeInLength: 4, length: 80)
        
        #expect(summary.files[0].matches.map(\.range) == [
            NSRange(location: 14, length: 6),
            NSRange(location: 34, length: 6),
        ])
        #expect(summary.files[0].matches.map(\.id) == [firstID, secondID])
        #expect(summary.files[0].matches[0].line == line)
        #expect(summary.files[0].matches[0].rangeInLine == rangeInLine)
        #expect(summary.files[1].matches.map(\.range) == [NSRange(location: 10, length: 6)])
    }
    
    
    @Test func summaryKeepsOverlappingEditedMatchInBounds() throws {
        
        let fileURL = URL(fileURLWithPath: "/tmp/a.txt").standardizedFileURL
        var summary = FolderFind.Summary(metrics: .init(findString: "needle"),
                                         files: [
                                            FolderFind.FileResult(fileURL: fileURL, directoryPathComponents: [],
                                                                  matches: [
                                                                    FolderFind.Match(range: NSRange(location: 10, length: 10), line: "overlapping needle", rangeInLine: NSRange(location: 12, length: 6)),
                                                                    FolderFind.Match(range: NSRange(location: 30, length: 6), line: "later needle", rangeInLine: NSRange(location: 6, length: 6)),
                                                                  ]),
                                         ])
        
        summary.updateMatchRanges(in: fileURL, editedRange: NSRange(location: 12, length: 0), changeInLength: -6, length: 40)
        
        #expect(summary.files[0].matches.map(\.range) == [
            NSRange(location: 10, length: 4),
            NSRange(location: 24, length: 6),
        ])
    }
    
    
    @Test func caseInsensitiveSearch() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("Needle\nneedle\nNEEDLE\n".utf8).write(to: rootURL.appending(path: "case.txt"))
        
        let query = FolderFind.Query(findString: "needle", mode: .textual(options: .caseInsensitive, fullWord: false))
        let summary = try await FolderFind.find(in: rootURL, query: query)
        
        #expect(summary.metrics.matchCount == 3)
    }
    
    
    @Test func regularExpressionSearch() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("item-1\nitem-22\nitem-x\n".utf8).write(to: rootURL.appending(path: "regex.txt"))
        
        let query = FolderFind.Query(findString: #"item-\d+"#, mode: .regularExpression(options: [], unescapesReplacement: false))
        let summary = try await FolderFind.find(in: rootURL, query: query)
        
        #expect(summary.metrics.matchCount == 2)
        #expect(summary.files.first?.matches.map(\.line) == ["item-1", "item-22"])
    }
    
    
    @Test func invalidQueryThrowsBeforeScanning() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        await #expect(throws: TextFind.Error.emptyFindString) {
            try await FolderFind.find(in: rootURL, query: Self.query(""))
        }
        
        await #expect(throws: TextFind.Error.self) {
            try await FolderFind.find(in: rootURL, query: FolderFind.Query(findString: "[", mode: .regularExpression(options: [], unescapesReplacement: false)))
        }
    }
    
    
    @Test func hiddenAndExcludedItemsAreNotSearched() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: ".hidden.txt"))
        try FileManager.default.createDirectory(at: rootURL.appending(path: ".git", directoryHint: .isDirectory), withIntermediateDirectories: true)
        try Data("needle".utf8).write(to: rootURL.appending(path: ".git/config"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "visible.txt"))
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        #expect(summary.metrics.searchedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["visible.txt"])
    }
    
    
    @Test func hiddenItemsCanBeIncluded() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: ".hidden.txt"))
        
        let summary = try await FolderFind.find(in: rootURL,
                                                    query: Self.query("needle"),
                                                    options: .init(includesHiddenFiles: true))
        
        #expect(summary.metrics.searchedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == [".hidden.txt"])
    }
    
    
    @Test func symbolicLinkCycleIsNotFollowedInfinitely() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        let subURL = rootURL.appending(path: "sub", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: subURL, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: subURL.appending(path: "loop"), withDestinationURL: rootURL)
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        #expect(summary.metrics.searchedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["a.txt"])
    }
    
    
    @Test func binaryPropertyListIsSkipped() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let propertyList = ["key": "needle"]
        let xmlData = try PropertyListSerialization.data(fromPropertyList: propertyList, format: .xml, options: 0)
        let binaryData = try PropertyListSerialization.data(fromPropertyList: propertyList, format: .binary, options: 0)
        
        try xmlData.write(to: rootURL.appending(path: "xml.plist"))
        try binaryData.write(to: rootURL.appending(path: "binary.plist"))
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        #expect(summary.metrics.searchedFileCount == 1)
        #expect(summary.metrics.skippedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["xml.plist"])
    }
    
    
    @Test func candidateReadsMetadataForDefaultInclusion() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let textURL = rootURL.appending(path: "text.txt")
        let extensionlessURL = rootURL.appending(path: "Makefile")
        
        try Data("needle".utf8).write(to: textURL)
        try Data("needle".utf8).write(to: extensionlessURL)
        
        let textCandidate = try FolderFind.Candidate(at: textURL)
        let extensionlessCandidate = try FolderFind.Candidate(at: extensionlessURL)
        let directoryCandidate = try FolderFind.Candidate(at: rootURL)
        
        #expect(textCandidate.fileURL == textURL.standardizedFileURL)
        #expect(textCandidate.contentType.conforms(to: .text))
        #expect(!textCandidate.isDirectory)
        #expect(!textCandidate.isHidden)
        #expect(FolderFind.isSearchableText(textCandidate))
        #expect(FolderFind.isSearchableText(extensionlessCandidate))
        #expect(directoryCandidate.isDirectory)
        #expect(!FolderFind.isSearchableText(directoryCandidate))
    }
    
    
    @Test func otherFileTypesOptionSearchesDecodableNonTextFiles() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "data.bin"))
        
        let defaultSummary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        #expect(defaultSummary.metrics.searchedFileCount == 0)
        #expect(defaultSummary.metrics.matchCount == 0)
        
        let otherFileTypesSummary = try await FolderFind.find(in: rootURL,
                                                              query: Self.query("needle"),
                                                              options: .init(includesOtherFileTypes: true))
        #expect(otherFileTypesSummary.metrics.searchedFileCount == 1)
        #expect(otherFileTypesSummary.metrics.matchCount == 1)
        #expect(otherFileTypesSummary.files.map(\.filename) == ["data.bin"])
    }
    
    
    @Test func fileScopeRulesFilterCandidates() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "README.md"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "index.html"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "note.txt"))
        
        let fileScope = FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .isEqualTo, value: "README.md"),
            FileScope.Rule(target: .fileExtension, comparison: .isEqualTo, value: "html"),
        ])
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"), options: .init(fileScope: fileScope))
        
        #expect(summary.metrics.searchedFileCount == 2)
        #expect(summary.metrics.matchCount == 2)
        #expect(Set(summary.files.map(\.filename)) == ["README.md", "index.html"])
    }
    
    
    @Test func fileScopeRegularExpressionRulesFilterCandidates() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "README.md"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "index.html"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "note.txt"))
        
        let fileScope = FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: #".+\.(md|html)"#),
        ])
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"), options: .init(fileScope: fileScope))
        
        #expect(summary.metrics.searchedFileCount == 2)
        #expect(summary.metrics.matchCount == 2)
        #expect(Set(summary.files.map(\.filename)) == ["README.md", "index.html"])
    }
    
    
    @Test func fileScopeRuleComparisons() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let fileURL = rootURL.appending(path: "Package.swift")
        try Data("needle".utf8).write(to: fileURL)
        let candidate = try FolderFind.Candidate(at: fileURL)
        
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .contains, value: "package"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .fileExtension, comparison: .isNotEqualTo, value: "txt"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .endsWith, value: ".swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: #"Package\..+"#),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(!FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: "swift"),
        ]).contains(candidate, relativeTo: rootURL))
    }
    
    
    @Test func fileScopeMatcherRejectsInvalidRules() {
        
        #expect(throws: FileScope.Error.invalidRegularExpression(pattern: "[")) {
            _ = try FileScope.Matcher(FileScope(rules: [
                FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: "["),
            ]))
        }
        
        #expect(throws: FileScope.Error.emptyValue) {
            _ = try FileScope.Matcher(FileScope(rules: [
                FileScope.Rule(target: .filename, comparison: .contains, value: ""),
            ]))
        }
    }
    
    
    @Test func fileScopePathTargetUsesRelativePath() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let subDirectoryURL = rootURL.appending(path: "src", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: subDirectoryURL, withIntermediateDirectories: true)
        let fileURL = subDirectoryURL.appending(path: "main.swift")
        try Data("needle".utf8).write(to: fileURL)
        let candidate = try FolderFind.Candidate(at: fileURL)
        
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .isEqualTo, value: "src/main.swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "src/"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .endsWith, value: "main.swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(!FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .isEqualTo, value: "main.swift"),
        ]).contains(candidate, relativeTo: rootURL))
    }
    
    
    @Test func fileScopePathTargetFallsBackToAbsolutePath() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let fileURL = rootURL.appending(path: "main.swift")
        try Data("needle".utf8).write(to: fileURL)
        let candidate = try FolderFind.Candidate(at: fileURL)
        
        // the absolute path is used when the candidate is not under the root folder
        let unrelatedURL = rootURL.appending(path: "other", directoryHint: .isDirectory)
        
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "/"),
        ]).contains(candidate, relativeTo: unrelatedURL))
        #expect(FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .endsWith, value: "/main.swift"),
        ]).contains(candidate, relativeTo: unrelatedURL))
    }
    
    
    @Test func invalidFileScopeThrowsBeforeScanning() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let progress = FolderFindProgress(findString: "needle")
        let fileScope = FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: "["),
        ])
        
        await #expect(throws: FileScope.Error.invalidRegularExpression(pattern: "[")) {
            try await FolderFind.find(in: rootURL, query: Self.query("needle"), options: .init(fileScope: fileScope), progress: progress)
        }
        
        #expect(progress.snapshot.searchedFileCount == 0)
        #expect(progress.snapshot.skippedFileCount == 0)
    }
    
    
    @Test func emptyFileScopeRuleValueThrowsBeforeScanning() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let progress = FolderFindProgress(findString: "needle")
        let fileScope = FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .contains, value: ""),
        ])
        
        await #expect(throws: FileScope.Error.emptyValue) {
            try await FolderFind.find(in: rootURL, query: Self.query("needle"), options: .init(fileScope: fileScope), progress: progress)
        }
        
        #expect(progress.snapshot.searchedFileCount == 0)
        #expect(progress.snapshot.skippedFileCount == 0)
    }
    
    
    @Test func unreadableTextIsSkipped() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data([0xFF]).write(to: rootURL.appending(path: "invalid.txt"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "valid.txt"))
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle"))
        
        #expect(summary.metrics.searchedFileCount == 1)
        #expect(summary.metrics.skippedFileCount == 1)
        #expect(summary.metrics.matchCount == 1)
    }
    
    
    @Test func customInclusionCanSearchSyntaxMappedFiles() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "Custom.syntaxless"))
        
        let summary = try await FolderFind.find(in: rootURL, query: Self.query("needle")) { candidate in
            FolderFind.isSearchableText(candidate) || candidate.fileURL.lastPathComponent == "Custom.syntaxless"
        }
        
        #expect(summary.metrics.matchCount == 1)
    }
    
    
    // MARK: Private Methods
    
    /// Returns a textual search query.
    ///
    /// - Parameter string: The string to search.
    /// - Returns: A folder search query.
    private static func query(_ string: String) -> FolderFind.Query {
        
        FolderFind.Query(findString: string, mode: .textual(options: [], fullWord: false))
    }
    
    
    /// Creates a temporary directory for a test.
    ///
    /// - Returns: The created directory URL.
    private static func makeTemporaryDirectory() throws -> URL {
        
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
}
