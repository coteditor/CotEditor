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

struct OutlineExtractor {
    
    var regex: NSRegularExpression
    var template: String
    var style: OutlineItem.Style
    
    
    init(definition: OutlineDefinition) throws {
        
        // compile to regex object
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if definition.ignoreCase {
            options.update(with: .caseInsensitive)
        }
        self.regex = try NSRegularExpression(pattern: definition.pattern, options: options)
        
        self.template = definition.template
        
        var style = OutlineItem.Style()
        if definition.bold {
            style.update(with: .bold)
        }
        if definition.italic {
            style.update(with: .italic)
        }
        if definition.underline {
            style.update(with: .underline)
        }
        self.style = style
    }
    
    
    /// extract outline items in given string
    func items(in string: String, range parseRange: NSRange) -> [OutlineItem] {
        
        var items = [OutlineItem]()
        
        self.regex.enumerateMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange) { (result: NSTextCheckingResult?, flags, stop) in
            guard let result = result else { return }
            
            let range = result.range
            
            // separator item
            if self.template == .separator {
                let item = OutlineItem(title: self.template, range: range)
                items.append(item)
                return
            }
            
            // menu item title
            var title: String
            
            if self.template.isEmpty {
                // no pattern definition
                title = (string as NSString).substring(with: range)
                
            } else {
                // replace matched string with template
                title = self.regex.replacementString(for: result, in: string, offset: 0, template: self.template)
                
                // replace $LN with line number of the beginning of the matched range
                if title.contains("$LN") {
                    let lineNumber = string.lineNumber(at: range.location)
                    
                    title = title.replacingOccurrences(of: "(?<!\\\\)\\$LN", with: String(lineNumber), options: .regularExpression)
                }
            }
            
            // replace whitespaces
            title = title.replacingOccurrences(of: "\n", with: " ")
            
            // append outline item
            let item = OutlineItem(title: title, range: range, style: self.style)
            items.append(item)
        }
        
        return items
    }
    
}


extension OutlineExtractor: Equatable {
    
    static func == (lhs: OutlineExtractor, rhs: OutlineExtractor) -> Bool {
        
        return lhs.regex.pattern == rhs.regex.pattern &&
            lhs.regex.options == rhs.regex.options &&
            lhs.template == rhs.template &&
            lhs.style == rhs.style
    }
    
}



// MARK: -

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
