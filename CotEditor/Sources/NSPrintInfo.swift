//
//  NSPrintInfo.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-10-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2022 1024jp
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

extension NSPrintInfo {
    
    /// The content size of the paper.
    var paperContentSize: NSSize {
        
        var size = self.paperSize
        size.width -= self.leftMargin + self.rightMargin
        size.height -= self.topMargin + self.bottomMargin
        
        return size.scaled(to: 1 / self.scalingFactor)
    }
    
    
    /// KVO compatible accessor for Cocoa print setting.
    subscript<Value>(key: NSPrintInfo.AttributeKey) -> Value? {
        
        get { self.dictionary().value(forKey: key.rawValue) as? Value }
        set { self.dictionary().setValue(newValue, forKey: key.rawValue) }
    }
}
