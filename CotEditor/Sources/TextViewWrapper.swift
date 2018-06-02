//
//  TextViewWrapper.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-06-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

import AppKit

final class TextViewWrapper<T: NSTextView> {
    
    // MARK: Private Properties
    
    private weak var textContainer: NSTextContainer?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(_ textView: T) {
        
        // hold textContainer instead of NSTextView (subclass) which cannot be weak
        // -> Under OS X 10.11, NSTextView can be neither `weak` nor `unowned`. (2018-06 on macOS 10.13 SDK)
        self.textContainer = textView.textContainer
    }
    
    
    
    // MARK: Public Methods
    
    var textView: T? {
        
        return self.textContainer?.textView as? T
    }
    
}
