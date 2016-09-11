/*
 
 EditorScrollView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-01-15.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

final class EditorScrollView: NSScrollView {
    
    // MARK: Lifecycle
    
    deinit {
        if let documentView = self.documentView as? NSTextView {
            documentView.removeObserver(self, forKeyPath: #keyPath(NSTextView.layoutOrientation))
        }
    }
    
    
    
    // MARK: Scroll View Methods
    
    /// use custom ruler view
    override class func rulerViewClass() -> AnyClass {
    
        return LineNumberView.self
    }
    
    
    /// set text view
    override var documentView: NSView? {
        
        willSet {
            if let documentView = newValue as? NSTextView {
                documentView.addObserver(self, forKeyPath: #keyPath(NSTextView.layoutOrientation), options: .initial, context: nil)
            }
        }
    }

    
    
    // MARK: KVO
    
    /// observed key value did update
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(NSTextView.layoutOrientation) {
            switch self.layoutOrientation {
            case .horizontal:
                self.hasVerticalRuler = true
                self.hasHorizontalRuler = false
            case .vertical:
                self.hasVerticalRuler = false
                self.hasHorizontalRuler = true
            }
            
            // invalidate line number view background
            self.window?.display()
        }
    }
    
    
    
    // MARK: Public Methods
    
    func invalidateLineNumber() {
        
        self.lineNumberView?.needsDisplay = true
    }
    
    
    
    // MARK: Private Methods
    
    /// return layout orientation of document text view
    private var layoutOrientation: NSTextLayoutOrientation {
        
        guard let documentView = self.documentView as? NSTextView else {
            return .horizontal
        }
        
        return documentView.layoutOrientation
    }
    
    
    /// return current line number view
    private var lineNumberView: NSRulerView? {
    
        switch self.layoutOrientation {
        case .horizontal:
            return self.verticalRulerView
            
        case .vertical:
            return self.horizontalRulerView
        }
    }
    
}
