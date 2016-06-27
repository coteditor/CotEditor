/*
 
 ConsolePanelController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-12.
 
 ------------------------------------------------------------------------------
 
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

import Cocoa

private let ConsoleFontSize: CGFloat = 11.0


class ConsolePanelController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = ConsolePanelController()
    
    
    // MARK: Private Properties
    
    private let fontSize: CGFloat = ConsoleFontSize
    
    private let messageParagraphStyle: NSParagraphStyle = {
        // indent for message body
        var paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.headIndent = ConsoleFontSize
        paragraphStyle.firstLineHeadIndent = ConsoleFontSize
        return paragraphStyle
    }()
    
    private let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:MM:SS"
        return formatter
    }()
    
    @IBOutlet private var textView: NSTextView?  // NSTextView cannot be weak
    @IBOutlet private weak var textFinder: NSTextFinder?
    
    
    
    // MARK:
    // MARK: WindowController Methods
    
    /// nib name
    override var windowNibName: String? {
        
        return "ConsolePanel"
    }
    
    
    /// setup UI
    override func windowDidLoad() {
        
        super.windowDidLoad()
    
        self.textView?.font = NSFont.messageFont(ofSize: self.fontSize)
        self.textView?.textContainerInset = NSSize(width: 0.0, height: 4.0)
    }
    
    
    
    // MARK: Public Methods
    
    /// append given message to the console
    func append(message: String, title: String) {
        
        let date = self.dateFormatter.string(from: Date())
        let attrString = NSMutableAttributedString(string: "[" + date + "] ")
        
        // append bold title
        let attrTitle = NSMutableAttributedString(string: title)
        attrTitle.applyFontTraits(.boldFontMask, range: NSRange(location: 0, length: title.utf16.count))
        attrString.append(attrTitle)
        
        // append indented message
        let attrMessage = AttributedString(string: "\n" + message + "\n", attributes: [NSParagraphStyleAttributeName: self.messageParagraphStyle])
        attrString.append(attrMessage)
        
        self.textView?.textStorage?.append(attrString)
    }
    
    
    /// flush console
    @IBAction func cleanConsole(_ sender: AnyObject?) {
        
        self.textView?.string = ""
    }
    
}



// MARK:
// MARK: TextFinder Support

/// Map find actions to NSTextFinder, since find action key bindings are configured for CETextFinder.
extension ConsolePanelController {
    
    /// bridge find action to NSTextFinder
    @IBAction func showFindPanel(_ sender: AnyObject?) {
        
        self.textFinder?.performAction(.showFindInterface)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func findNext(_ sender: AnyObject?) {
        
        self.textFinder?.performAction(.nextMatch)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func findPrevious(_ sender: AnyObject?) {
        
        self.textFinder?.performAction(.previousMatch)
    }
    
    
    /// bridge find action to NSTextFinder
    @IBAction func useSelectionForFind(_ sender: AnyObject?) {
        
        self.textFinder?.performAction(.setSearchString)
    }
    
}
