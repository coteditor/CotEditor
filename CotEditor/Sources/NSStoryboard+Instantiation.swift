//
//  NSStoryboard+Instantiation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-11-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

protocol StoryboardInstantiatable: AnyObject {
    
    /// Instantinate control from a storyboard.
    ///
    /// - Parameters:
    ///   - name: The name of the storyboard.
    ///   - bundle: The bundle where the storyboard file exists. When nil, the app’s main bundle will be used.
    /// - Returns: A instance of the receiver class that is instantiated from the storyboard.
    static func instantiate(storyboard: NSStoryboard.Name, bundle: Bundle?) -> Self
}


extension StoryboardInstantiatable {
    
    /// instantinate control from a storyboard
    static func instantiate(storyboard name: NSStoryboard.Name, bundle: Bundle? = nil) -> Self {
        
        return NSStoryboard(name: name, bundle: bundle).instantiateInitialController() as! Self
    }
}


extension NSWindowController: StoryboardInstantiatable { }
extension NSViewController: StoryboardInstantiatable { }
