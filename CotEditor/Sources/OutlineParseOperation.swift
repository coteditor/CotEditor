//
//  OutlineParseOperation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2020 1024jp
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

final class OutlineParseOperation: Operation, ProgressReporting {
    
    // MARK: Public Properties
    
    let progress: Progress
    private(set) var results = [OutlineItem]()
    
    
    // MARK: Private Properties
    
    private let extractors: [OutlineExtractor]
    private let string: String
    private let parseRange: NSRange
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(extractors: [OutlineExtractor], string: String, range parseRange: NSRange) {
        
        assert(parseRange.location != NSNotFound)
        assert(!(string is NSMutableString))
        
        self.extractors = extractors
        self.string = string
        self.parseRange = parseRange
        
        self.progress = Progress(totalUnitCount: Int64(extractors.count + 1))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }
    
    
    
    // MARK: Operation Methods
    
    /// parse string and extract outline items
    override func main() {
        
        guard
            !self.extractors.isEmpty,
            !self.string.isEmpty
            else {
                self.progress.completedUnitCount = self.progress.totalUnitCount
                return
            }
        
        for extractor in self.extractors {
            guard !self.isCancelled else { return }
            
            self.results += extractor.items(in: self.string, range: self.parseRange) { (stop) in
                stop = self.isCancelled
            }
            
            self.progress.completedUnitCount += 1
        }
        
        guard !self.isCancelled else { return }
        
        self.results.sort(\.range.location)
        
        self.progress.completedUnitCount += 1
    }
    
}
