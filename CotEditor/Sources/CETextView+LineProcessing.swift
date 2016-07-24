/*
 
 CETextView+LineProcessing.swift
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
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

import Foundation

extension CETextView {
    
    // MARK: Action Messages
    
    /// move selected line up
    @IBAction func  moveLineUp(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// move selected line down
    @IBAction func  moveLineDown(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// sort selected lines (only in the first selection) ascending
    @IBAction func  sortLinesAscending(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// reverse selected lines (only in the first selection)
    @IBAction func  reverseLines(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// delete duplicate lines in selection
    @IBAction func  deleteDuplicateLine(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// duplicate selected lines below
    @IBAction func  duplicateLine(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// remove selected lines
    @IBAction func  deleteLine(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    /// trim all trailing whitespace
    @IBAction func  trimTrailingWhitespace(_ sender: AnyObject?) {
        
        fatalError()
    }
    
    
    
    // MARK: Private Methods
    
    /// extract line by line line ranges which selected ranges include
    private var selectedLineRanges: [NSRange] {
        
        fatalError()
    }
    
}
