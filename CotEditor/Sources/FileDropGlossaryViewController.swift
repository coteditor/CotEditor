/*
 
 FileDropGlossaryViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-06.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit

final class FileDropGlossaryViewController: NSViewController {
    
    @IBOutlet private var textView: NSTextView?  // NSTextView cannot be weak
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let textView = self.textView!
        
        let fontSize = NSFont.smallSystemFontSize()
        textView.font = .userFont(ofSize: fontSize) ?? .systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.textContainerInset = NSSize(width: 2, height: 6)
        
        let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineSpacing = 1
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.headIndent = 12
        textView.defaultParagraphStyle = paragraphStyle
        
        // set localized glossary to view
        textView.string = FileDropComposer.Token.all
            .map { $0.token + LineEnding.lineSeparator.string + $0.localizedDescription }
            .joined(separator: LineEnding.paragraphSeparator.string)
    }
    
}
