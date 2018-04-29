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
//  © 2014-2018 1024jp
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

final class OutlineParseOperation: AsynchronousOperation, ProgressReporting {
    
    // MARK: Public Properties
    
    var string: String?
    var parseRange: NSRange = .notFound
    
    let progress: Progress
    private(set) var results = [OutlineItem]()
    
    
    // MARK: Private Properties
    
    private let extractors: [OutlineExtractor]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(extractors: [OutlineExtractor]) {
        
        self.extractors = extractors
        self.progress = Progress(totalUnitCount: Int64(extractors.count + 1))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
        
        self.queuePriority = .low
    }
    
    
    
    // MARK: Operation Methods
    
    /// is ready to run
    override var isReady: Bool {
        
        return self.string != nil && self.parseRange.location != NSNotFound
    }
    
    
    /// parse string in background and return extracted outline items
    override func main() {
        
        defer {
            self.finish()
        }
        
        guard !self.extractors.isEmpty else { return }
        
        guard
            let string = self.string,
            !string.isEmpty,
            self.parseRange.location != NSNotFound
            else { return }
        
        var outlineItems = [OutlineItem]()
        
        for extractor in self.extractors {
            guard !self.isCancelled else { return }
            
            outlineItems += extractor.items(in: string, range: self.parseRange)
            
            DispatchQueue.main.async { [weak self] in
                self?.progress.completedUnitCount += 1
            }
        }
        
        guard !self.isCancelled else { return }
        
        outlineItems.sort {
            $0.range.location < $1.range.location
        }
        
        self.results = outlineItems
        
        DispatchQueue.main.async { [weak self] in
            self?.progress.completedUnitCount += 1
        }
    }
    
}
