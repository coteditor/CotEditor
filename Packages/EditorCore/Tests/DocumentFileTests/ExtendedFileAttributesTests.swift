//
//  ExtendedFileAttributesTests.swift
//  DocumentFileTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-04.
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
@testable import DocumentFile

struct ExtendedFileAttributesTests {
    
    @Test func initializeFromFileAttributeDictionary() {
        
        let dictionary: [FileAttributeKey: Any] = [
            .extendedAttributes: [
                ExtendedFileAttributeName.encoding: Data("utf-8;134217984".utf8),
                ExtendedFileAttributeName.verticalText: Data(),
                ExtendedFileAttributeName.allowLineEndingInconsistency: Data([1]),
            ],
        ]
        
        let attributes = ExtendedFileAttributes(dictionary: dictionary)
        
        #expect(attributes.encoding == .utf8)
        #expect(attributes.isVerticalText)
        #expect(attributes.allowsInconsistentLineEndings)
    }
    
    
    @Test func initializeWithoutExtendedAttributeDictionary() {
        
        let attributes = ExtendedFileAttributes(dictionary: [:])
        
        #expect(attributes.encoding == nil)
        #expect(!attributes.isVerticalText)
        #expect(!attributes.allowsInconsistentLineEndings)
    }
}
