/*
 
 SyntaxMappingConflictsViewController.m
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-25.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
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

import Cocoa

// data model
final class MappingConflict: NSObject {
    
    @objc dynamic let name: String
    @objc dynamic let primaryStyle: String
    @objc dynamic let doubledStyles: String
    
    
    required init(name: String, primaryStyle: String, doubledStyles: String) {
        
        self.name = name
        self.primaryStyle = primaryStyle
        self.doubledStyles = doubledStyles
        
        super.init()
    }
}




final class SyntaxMappingConflictsViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic let extensionConflicts: [MappingConflict]
    @objc private dynamic let filenameConflicts: [MappingConflict]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        
        let conflictDicts = SyntaxManager.shared.mappingConflicts
        
        self.extensionConflicts = type(of: self).parseConflictDict(conflictDict: conflictDicts[.extensions]!)
        self.filenameConflicts = type(of: self).parseConflictDict(conflictDict: conflictDicts[.filenames]!)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("SyntaxMappingConflictView")
    }
    
    
    
    // MARK: Private Methods
    
    /// convert conflictDict data for table
    private static func parseConflictDict(conflictDict: [String: [String]]) -> [MappingConflict] {
        
        return conflictDict.map { item in
            
            let styles = item.value
            let primaryStyle = styles.first!
            let doubledStyles = styles.dropFirst().joined(separator: ", ")
            
            return MappingConflict(name: item.key,
                                   primaryStyle: primaryStyle,
                                   doubledStyles: doubledStyles)
        }
    }
    
}
