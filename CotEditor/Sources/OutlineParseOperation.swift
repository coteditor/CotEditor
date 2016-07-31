/*
 
 OutlineParseOperation.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-06.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

struct OutlineDefinition: Equatable, CustomDebugStringConvertible {
    
    let regex: RegularExpression
    let template: String
    let isSeparator: Bool
    
    let isBold: Bool
    let isItalic: Bool
    let hasUnderline: Bool
    
    
    init?(definition: [String: AnyObject]) {
        
        guard let pattern = definition[SyntaxDefinitionKey.beginString.rawValue] as? String else { return nil }
        
        let ignoreCase = (definition[SyntaxDefinitionKey.ignoreCase.rawValue] as? Bool) ?? false
        var options: RegularExpression.Options = .anchorsMatchLines
        if ignoreCase {
            options.update(with: .caseInsensitive)
        }
        
        // compile to regex object
        do {
            self.regex = try RegularExpression(pattern: pattern, options: options)
            
        } catch let error as NSError {
            print("Error on outline parsing: " + error.description)
            return nil
        }
        
        self.template = (definition[SyntaxDefinitionKey.keyString.rawValue] as? String) ?? ""
        self.isSeparator = (self.template == String.separator)
        
        self.isBold = (definition[OutlineStyleKey.bold.rawValue] as? Bool) ?? false
        self.isItalic = (definition[OutlineStyleKey.italic.rawValue] as? Bool) ?? false
        self.hasUnderline = (definition[OutlineStyleKey.underline.rawValue] as? Bool) ?? false
    }
    
    
    var debugDescription: String {
        
        return "<\(self): \(self.regex.pattern) template: \(self.template)>"
    }
    
}

func ==(lhs: OutlineDefinition, rhs: OutlineDefinition) -> Bool {
    
    return lhs.regex == rhs.regex &&
        lhs.template == rhs.template &&
        lhs.isBold == rhs.isBold &&
        lhs.isItalic == rhs.isItalic &&
        lhs.hasUnderline == rhs.hasUnderline
}



// MARK:

class OutlineParseOperation: Operation {
    
    // MARK: Public Properties
    
    var string: String?
    var parseRange: NSRange = NotFoundRange
    
    let progress: Progress
    private(set) var results = [OutlineItem]()
    
    
    // MARK: Private Properties
    
    private let definitions: [OutlineDefinition]
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(definitions: [OutlineDefinition]) {
        
        self.definitions = definitions
        self.progress = Progress(totalUnitCount: Int64(definitions.count))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
        
        self.queuePriority = .low
    }
    
    
    
    // MARK: Operation Methods
    
    /// runs asynchronous
    override var isAsynchronous: Bool {
        
        return true
    }
    
    
    /// is ready to run
    override var isReady: Bool {
        
        return self.string != nil && self.parseRange.location != NSNotFound
    }
    
    
    /// parse string in background and return extracted outline items
    override func main() {
        
        guard !self.definitions.isEmpty else { return }
        
        let parseRange = self.parseRange
        guard let string = self.string, !string.isEmpty && parseRange.location != NSNotFound else { return }
        
        var outlineItems = [OutlineItem]()
        
        for definition in self.definitions {
            self.progress.completedUnitCount += 1
            
            definition.regex.enumerateMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds] , range: parseRange, using:
                { [unowned self] (result: TextCheckingResult?, flags, stop) in
                    
                    guard !self.isCancelled else {
                        stop.pointee = true
                        return
                    }
                    guard let result = result else { return }
                    
                    let range = result.range
                    
                    // separator item
                    if definition.isSeparator {
                        let item = OutlineItem(title: definition.template, range: range)
                        outlineItems.append(item)
                        return
                    }
                    
                    // menu item title
                    var title: String
                    
                    if definition.template.isEmpty {
                        // no pattern definition
                        title = (string as NSString).substring(with: range)
                        
                    } else {
                        // replace matched string with template
                        title = definition.regex.replacementString(for: result, in: string, offset: 0, template: definition.template)
                        
                        // replace $LN with line number of the beginning of the matched range
                        if title.contains("$LN") {
                            let lineNumber = string.lineNumber(at: range.location)
                            
                            title = title.replacingOccurrences(of: "(?<!\\\\)\\$LN",
                                                               with: String(lineNumber),
                                                               options: .regularExpression)
                        }
                    }
                        
                    // replace whitespaces
                    title = title.replacingOccurrences(of: "\n", with: " ")
                    
                    let item = OutlineItem(title: title,
                                           range: range,
                                           isBold: definition.isBold,
                                           isItalic: definition.isItalic,
                                           hasUnderline: definition.hasUnderline)
                    
                    // append outline item
                    outlineItems.append(item)
                    
                    guard !self.isCancelled else { return }
                })
            
            // sort by location
            outlineItems.sort {
                $0.range.location < $1.range.location
            }
            
            self.results = outlineItems
        }
    }
    
}
