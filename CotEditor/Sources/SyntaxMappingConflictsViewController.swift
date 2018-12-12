//
//  SyntaxMappingConflictsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-03-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

import Cocoa

final class MappingConflict: NSObject {
    
    @objc dynamic let name: String
    @objc dynamic let primaryStyle: String
    @objc dynamic let doubledStyles: String
    
    
    required init(name: String, styles: [String]) {
        
        self.name = name
        self.primaryStyle = styles.first!
        self.doubledStyles = styles.dropFirst().joined(separator: ", ")
        
        super.init()
    }
}



final class SyntaxMappingConflictsViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic var extensionConflicts: [MappingConflict] = []
    @objc private dynamic var filenameConflicts: [MappingConflict] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let conflictDicts = SyntaxManager.shared.mappingConflicts
        self.extensionConflicts = conflictDicts[.extensions]?.map { MappingConflict(name: $0.key, styles: $0.value) } ?? []
        self.filenameConflicts = conflictDicts[.filenames]?.map { MappingConflict(name: $0.key, styles: $0.value) } ?? []
    }
    
}
