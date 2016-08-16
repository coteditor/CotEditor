/*
 
 NSWindow+ScriptingSupport.swift
 
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

/// scripting support
extension NSWindow {
    
    /// opacity of the editor view for AppleScript (real type)
    var viewOpacity: NSNumber {
        
        get {
            guard let alphaWindow = self as? AlphaWindow else { return 1.0 }
            
            return NSNumber(value: Double(alphaWindow.backgroundAlpha))
        }
        
        set {
            guard let alphaWindow = self as? AlphaWindow else { return }
            
            alphaWindow.backgroundAlpha = CGFloat(viewOpacity.doubleValue)
        }
    }
    
}
