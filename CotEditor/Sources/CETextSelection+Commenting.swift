/*
 
 CETextSelection+Commenting.swift
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-01.
 
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

extension CETextSelection {
    
    /// uncomment the selection
    func handleCommentOut(_ command: NSScriptCommand) {
        
        self.textView?.commentOut(types: .both, fromLineHead: false)
    }
    
    
    /// uncomment the selection
    func handleUncomment(_ command: NSScriptCommand) {
        
        self.textView?.uncomment(types: .both, fromLineHead: false)
    }
    
    
    // MARK: Private Methods
    
    private var textView: CETextView? {
        
        return self.document?.editor?.focusedTextView as? CETextView
    }
    
}
