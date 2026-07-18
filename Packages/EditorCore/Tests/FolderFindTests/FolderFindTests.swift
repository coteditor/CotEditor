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
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.findString == "needle")
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
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern(), progress: progress)
        let summary = try await search.run()
        
        #expect(progress.snapshot.findString == "needle")
        #expect(progress.snapshot == summary.metrics)
    }
    
    
    @Test func progressIsNotUpdatedForInvalidQuery() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let progress = FolderFindProgress(findString: "")
        
        await #expect(throws: TextFind.Error.emptyFindString) {
            var search = try Search(rootURL: rootURL, pattern: Self.query("").pattern(), progress: progress)
            _ = try await search.run()
        }
        
        #expect(progress.snapshot.matchCount == 0)
        #expect(progress.snapshot.matchedFileCount == 0)
    }
    
    
    @Test func summaryRemovesSelectedResult() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nhay\nneedle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        try Data("hay\nneedle\n".utf8).write(to: rootURL.appending(path: "b.txt"))
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        var summary = try await search.run()
        
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
        
        let didUpdate = summary.updateMatchRanges(in: fileURL, editedRange: NSRange(location: 3, length: 4), changeInLength: 4, length: 80)
        
        #expect(didUpdate)
        
        #expect(summary.files[0].matches.map(\.range) == [
            NSRange(location: 14, length: 6),
            NSRange(location: 34, length: 6),
        ])
        #expect(summary.files[0].matches.map(\.id) == [firstID, secondID])
        #expect(summary.files[0].matches[0].line == line)
        #expect(summary.files[0].matches[0].rangeInLine == rangeInLine)
        #expect(summary.files[1].matches.map(\.range) == [NSRange(location: 10, length: 6)])
        
        // edits after all matches change nothing
        let didUpdateBehind = summary.updateMatchRanges(in: fileURL, editedRange: NSRange(location: 70, length: 2), changeInLength: 2, length: 82)
        
        #expect(!didUpdateBehind)
        #expect(summary.files[0].matches.map(\.range) == [
            NSRange(location: 14, length: 6),
            NSRange(location: 34, length: 6),
        ])
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
        
        let didUpdate = summary.updateMatchRanges(in: fileURL, editedRange: NSRange(location: 12, length: 0), changeInLength: -6, length: 40)
        
        #expect(didUpdate)
        
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
        var search = try Search(rootURL: rootURL, pattern: query.pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 3)
    }
    
    
    @Test func regularExpressionSearch() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("item-1\nitem-22\nitem-x\n".utf8).write(to: rootURL.appending(path: "regex.txt"))
        
        let query = FolderFind.Query(findString: #"item-\d+"#, mode: .regularExpression(options: [], unescapesReplacement: false))
        var search = try Search(rootURL: rootURL, pattern: query.pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 2)
        #expect(summary.files.first?.matches.map(\.line) == ["item-1", "item-22"])
    }
    
    
    @Test func invalidQueryThrowsBeforeScanning() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        await #expect(throws: TextFind.Error.emptyFindString) {
            var search = try Search(rootURL: rootURL, pattern: Self.query("").pattern())
            _ = try await search.run()
        }
        
        await #expect(throws: TextFind.Error.self) {
            let query = FolderFind.Query(findString: "[", mode: .regularExpression(options: [], unescapesReplacement: false))
            var search = try Search(rootURL: rootURL, pattern: query.pattern())
            _ = try await search.run()
        }
    }
    
    
    @Test func hiddenAndExcludedItemsAreNotSearched() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: ".hidden.txt"))
        try FileManager.default.createDirectory(at: rootURL.appending(path: ".git", directoryHint: .isDirectory), withIntermediateDirectories: true)
        try Data("needle".utf8).write(to: rootURL.appending(path: ".git/config"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "visible.txt"))
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["visible.txt"])
    }
    
    
    @Test func hiddenItemsCanBeIncluded() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: ".hidden.txt"))
        
        var search = try Search(rootURL: rootURL,
                                pattern: Self.query("needle").pattern(),
                                options: .init(includesHiddenFiles: true))
        let summary = try await search.run()
        
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
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
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
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
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
        
        var defaultSearch = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let defaultSummary = try await defaultSearch.run()
        #expect(defaultSummary.metrics.matchCount == 0)
        
        var otherFileTypesSearch = try Search(rootURL: rootURL,
                                              pattern: Self.query("needle").pattern(),
                                              options: .init(includesOtherFileTypes: true))
        let otherFileTypesSummary = try await otherFileTypesSearch.run()
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
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern(), options: .init(fileScope: fileScope))
        let summary = try await search.run()
        
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
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern(), options: .init(fileScope: fileScope))
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 2)
        #expect(Set(summary.files.map(\.filename)) == ["README.md", "index.html"])
    }
    
    
    @Test func fileScopeRuleComparisons() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let fileURL = rootURL.appending(path: "Package.swift")
        try Data("needle".utf8).write(to: fileURL)
        let candidate = try FolderFind.Candidate(at: fileURL)
        
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .contains, value: "package"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .doesNotContain, value: "objc"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try !FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .doesNotContain, value: "PACKAGE"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .fileExtension, comparison: .isNotEqualTo, value: "txt"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .endsWith, value: ".swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: #"Package\..+"#),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: #"Package|Package\.swift"#),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try !FileScope(rules: [
            FileScope.Rule(target: .filename, comparison: .matchesRegularExpression, value: "swift"),
        ]).contains(candidate, relativeTo: rootURL))
    }
    
    
    @Test func fileScopeConjunctionCombinesRules() throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let buildDirectoryURL = rootURL.appending(path: "build", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: buildDirectoryURL, withIntermediateDirectories: true)
        try Data("needle".utf8).write(to: rootURL.appending(path: "main.swift"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "README.md"))
        try Data("needle".utf8).write(to: buildDirectoryURL.appending(path: "generated.swift"))
        
        let source = try FolderFind.Candidate(at: rootURL.appending(path: "main.swift"))
        let readme = try FolderFind.Candidate(at: rootURL.appending(path: "README.md"))
        let generated = try FolderFind.Candidate(at: buildDirectoryURL.appending(path: "generated.swift"))
        
        let rules = [
            FileScope.Rule(target: .fileExtension, comparison: .isEqualTo, value: "swift"),
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "build/"),
        ]
        
        // include files matching any of the rules
        #expect(try FileScope(conjunction: .any, rules: rules).contains(source, relativeTo: rootURL))
        #expect(try !FileScope(conjunction: .any, rules: rules).contains(readme, relativeTo: rootURL))
        #expect(try FileScope(conjunction: .any, rules: rules).contains(generated, relativeTo: rootURL))
        
        // include only files matching all the rules
        #expect(try !FileScope(conjunction: .all, rules: rules).contains(source, relativeTo: rootURL))
        #expect(try !FileScope(conjunction: .all, rules: rules).contains(readme, relativeTo: rootURL))
        #expect(try FileScope(conjunction: .all, rules: rules).contains(generated, relativeTo: rootURL))
        
        // combine an inclusion and an exclusion
        let mixedScope = FileScope(conjunction: .all, rules: [
            FileScope.Rule(target: .fileExtension, comparison: .isEqualTo, value: "swift"),
            FileScope.Rule(target: .filePath, comparison: .doesNotContain, value: "build"),
        ])
        #expect(try mixedScope.contains(source, relativeTo: rootURL))
        #expect(try !mixedScope.contains(generated, relativeTo: rootURL))
        
        // an empty scope includes all files regardless of the conjunction
        for conjunction in FileScope.Conjunction.allCases {
            #expect(try FileScope(conjunction: conjunction).contains(generated, relativeTo: rootURL))
        }
    }
    
    
    @Test func fileScopeRoundTripsThroughCodable() throws {
        
        let fileScope = FileScope(conjunction: .all, rules: [
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "build/"),
        ])
        let data = try JSONEncoder().encode(fileScope)
        let decoded = try JSONDecoder().decode(FileScope.self, from: data)
        
        #expect(decoded == fileScope)
        #expect(FileScope().conjunction == .any)
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
        
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .isEqualTo, value: "src/main.swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "src/"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .endsWith, value: "main.swift"),
        ]).contains(candidate, relativeTo: rootURL))
        #expect(try !FileScope(rules: [
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
        
        #expect(try FileScope(rules: [
            FileScope.Rule(target: .filePath, comparison: .startsWith, value: "/"),
        ]).contains(candidate, relativeTo: unrelatedURL))
        #expect(try FileScope(rules: [
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
            var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern(), options: .init(fileScope: fileScope), progress: progress)
            _ = try await search.run()
        }
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
            var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern(), options: .init(fileScope: fileScope), progress: progress)
            _ = try await search.run()
        }
    }
    
    
    @Test func unreadableTextIsSkipped() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data([0xFF]).write(to: rootURL.appending(path: "invalid.txt"))
        try Data("needle".utf8).write(to: rootURL.appending(path: "valid.txt"))
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 1)
    }
    
    
    @Test func fileLargerThanMaximumFileSizeIsSkipped() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "small.txt"))
        try Data("needle needle".utf8).write(to: rootURL.appending(path: "large.txt"))
        
        var search = try Search(rootURL: rootURL,
                                pattern: Self.query("needle").pattern(),
                                options: .init(maximumFileSize: 8))
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["small.txt"])
    }
    
    
    @Test func unreadableDirectoryIsSkipped() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        let lockedURL = rootURL.appending(path: "locked", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: lockedURL, withIntermediateDirectories: true)
        try Data("needle".utf8).write(to: lockedURL.appending(path: "b.txt"))
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: lockedURL.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: lockedURL.path) }
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern())
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.files.map(\.filename) == ["a.txt"])
    }
    
    
    @Test func customInclusionCanSearchSyntaxMappedFiles() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "Custom.syntaxless"))
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern()) { candidate in
            candidate.fileURL.lastPathComponent == "Custom.syntaxless"
        }
        let summary = try await search.run()
        
        #expect(summary.metrics.matchCount == 1)
    }
    
    
    @Test func customInclusionDoesNotExcludeSearchableFiles() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        var search = try Search(rootURL: rootURL, pattern: Self.query("needle").pattern()) { _ in false }
        let summary = try await search.run()
        
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


private extension FileScope {
    
    /// Returns whether the candidate is included in the file scope.
    ///
    /// - Parameters:
    ///   - candidate: The file candidate to evaluate.
    ///   - rootURL: The root folder URL for file path rules.
    /// - Returns: `true` if the candidate is included.
    /// - Throws: `FileScope.Error` if the file scope is invalid.
    func contains(_ candidate: FolderFind.Candidate, relativeTo rootURL: URL) throws -> Bool {
        
        try Matcher(self).contains(candidate, relativeTo: rootURL)
    }
}
