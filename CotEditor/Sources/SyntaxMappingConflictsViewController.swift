/*
 
 SyntaxMappingConflictsViewController.m
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-25.
 
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

// data model
final class MappingConflict: NSObject {
    
    let name: String
    let primaryStyle: String
    let doubledStyles: String
    
    
    required init(name: String, primaryStyle: String, doubledStyles: String) {
        
        self.name = name
        self.primaryStyle = primaryStyle
        self.doubledStyles = doubledStyles
        
        super.init()
    }
}




final class SyntaxMappingConflictsViewController: NSViewController {
    
    // MARK: Private Properties
    
    private dynamic let extensionConflicts: [MappingConflict]
    private dynamic let filenameConflicts: [MappingConflict]
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        extensionConflicts = self.dynamicType.parseConflictDict(conflictDict: SyntaxManager.shared.extensionConflicts)
        filenameConflicts = self.dynamicType.parseConflictDict(conflictDict: SyntaxManager.shared.filenameConflicts)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: String? {
        
        return "SyntaxMappingConflictView"
    }
    
    
    
    // MARK: Private Methods
    
    /// convert conflictDict data for table
    private static func parseConflictDict(conflictDict: [String: [String]]) -> [MappingConflict] {
        
        return conflictDict.map { (key, styles) in
            
            let primaryStyle = styles.first!
            let doubledStyles = styles.dropFirst().joined(separator: ", ")
            
            return MappingConflict(name: key,
                                   primaryStyle: primaryStyle,
                                   doubledStyles: doubledStyles)
        }
    }
    
}
