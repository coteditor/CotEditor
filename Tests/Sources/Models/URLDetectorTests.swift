//
//  URLDetectorTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-08-05.
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

import AppKit.NSTextStorage
import Testing
import ValueRange
@testable import CotEditor

@MainActor struct URLDetectorTests {
    
    /// Tests linking URLs in the entire text storage.
    @Test func linkURLs() async throws {
        
        let string = "Visit https://coteditor.com and https://example.com."
        let textStorage = NSTextStorage(string: string)
        let cotEditorURL = try #require(URL(string: "https://coteditor.com"))
        let exampleURL = try #require(URL(string: "https://example.com"))
        
        try await textStorage.linkURLs()
        
        #expect(self.links(in: textStorage) == [
            ValueRange(value: cotEditorURL,
                       range: (string as NSString).range(of: "https://coteditor.com")),
            ValueRange(value: exampleURL,
                       range: (string as NSString).range(of: "https://example.com")),
        ])
    }
    
    
    /// Tests updating links around an edited line.
    @Test func updateAfterEditing() async throws {
        
        let firstURL = "https://example.com"
        let secondURL = "https://coteditor.com"
        let textStorage = NSTextStorage(string: "\(firstURL)\n\(secondURL)")
        let secondLink = try #require(URL(string: secondURL))
        let detector = URLDetector(textStorage: textStorage)
        defer { detector.cancel() }
        
        let didDetectInitialLinks = await self.waitFor {
            self.links(in: textStorage).count == 2
        }
        try #require(didDetectInitialLinks, "The initial URLs must be detected.")
        
        textStorage.replaceCharacters(in: (textStorage.string as NSString).range(of: firstURL), with: "Not a URL")
        
        let didRemoveEditedLink = await self.waitFor {
            self.links(in: textStorage) == [
                ValueRange(value: secondLink,
                           range: (textStorage.string as NSString).range(of: secondURL)),
            ]
        }
        #expect(didRemoveEditedLink, "The edited link must be removed without affecting the other line.")
        
        let replacementURL = "https://example.org"
        let replacementLink = try #require(URL(string: replacementURL))
        textStorage.replaceCharacters(in: (textStorage.string as NSString).range(of: "Not a URL"), with: replacementURL)
        
        let didDetectReplacementLink = await self.waitFor {
            self.links(in: textStorage) == [
                ValueRange(value: replacementLink,
                           range: (textStorage.string as NSString).range(of: replacementURL)),
                ValueRange(value: secondLink,
                           range: (textStorage.string as NSString).range(of: secondURL)),
            ]
        }
        #expect(didDetectReplacementLink, "The replacement URL must be detected.")
    }
    
    
    /// Tests stopping URL detection.
    @Test func cancel() async throws {
        
        let textStorage = NSTextStorage(string: "https://example.com")
        let detector = URLDetector(textStorage: textStorage)
        
        let didDetectInitialLink = await self.waitFor {
            !self.links(in: textStorage).isEmpty
        }
        try #require(didDetectInitialLink, "The initial URL must be detected.")
        
        detector.cancel()
        
        #expect(self.links(in: textStorage).isEmpty)
        
        textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: "https://coteditor.com")
        try await Task.sleep(for: .seconds(1))
        
        #expect(self.links(in: textStorage).isEmpty, "URL detection must remain stopped after cancellation.")
    }
    
    
    /// Tests propagating task cancellation to URL detection.
    @Test func cancellation() async {
        
        let textStorage = NSTextStorage(string: "https://example.com")
        let task = Task { @MainActor in
            while !Task.isCancelled {
                await Task.yield()
            }
            
            try await textStorage.linkURLs()
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(self.links(in: textStorage).isEmpty)
    }
    
    
    // MARK: Private Methods
    
    /// Returns the links in the given text storage.
    ///
    /// - Parameter textStorage: The text storage to inspect.
    /// - Returns: The link values and ranges.
    private func links(in textStorage: NSTextStorage) -> [ValueRange<URL>] {
        
        var links: [ValueRange<URL>] = []
        textStorage.enumerateAttribute(.link, in: NSRange(location: 0, length: textStorage.length)) { value, range, _ in
            guard let url = value as? URL else { return }
            
            links.append(ValueRange(value: url, range: range))
        }
        
        return links
    }
    
    
    /// Waits until the given condition is satisfied.
    ///
    /// - Parameters:
    ///   - timeout: The maximum duration to wait.
    ///   - interval: The interval between condition checks.
    ///   - condition: The condition to evaluate.
    /// - Returns: `true` if the condition was satisfied; otherwise, `false`.
    private func waitFor(timeout: Duration = .seconds(2), interval: Duration = .milliseconds(20), _ condition: @escaping () -> Bool) async -> Bool {
        
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        
        while clock.now < deadline {
            if condition() { return true }
            try? await Task.sleep(for: interval)
        }
        
        return condition()
    }
}
