//
//  MainMenu.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-10-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

enum MainMenu: Int {
    
    case application
    case file
    case edit
    case format
    case view
    case text
    case find
    case window
    case script
    case help
    
    
    /// Menu item tags not to list up in the Key Bindings setting.
    enum MenuItemTag: Int {
        
        case recentDocuments = 2999
    }
}
