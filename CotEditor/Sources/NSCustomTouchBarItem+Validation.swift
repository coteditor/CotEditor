/*
 
 NSCustomTouchBarItem+Validation.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-11-27.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

@available(macOS 10.12.1, *)
protocol TouchBarItemValidations: class {
    
    func validateTouchBarItem(_ item: NSTouchBarItem) -> Bool
}



@available(macOS 10.12.1, *)
extension NSTouchBarProvider {
    
    func validateTouchBarItems() {
        
        guard NSClassFromString("NSTouchBar") != nil else { return }  // run-time check
        
        guard let touchBar = self.touchBar else { return }
        
        // validate currently visible touch bar items
        for identifier in touchBar.itemIdentifiers {
            guard let item = touchBar.item(forIdentifier: identifier) as? NSCustomTouchBarItem else { continue }
            
            item.validate()
        }
    }
    
}


@available(macOS 10.12.1, *)
extension NSCustomTouchBarItem: NSValidatedUserInterfaceItem {
    
    func validate() {
        
        // validate content control
        if let control = self.control,
            let action = control.action,
            let validator = NSApp.target(forAction: action, to: control.target, from: self)
        {
            if let validator = validator as? TouchBarItemValidations {
                control.isEnabled = validator.validateTouchBarItem(self)
                
            } else if let validator = validator as? NSUserInterfaceValidations {
                control.isEnabled = (validator as AnyObject).validateUserInterfaceItem(self)
            }
        }
    }
    
    
    
    // MARK: Validated User Interface Item Protocol
    
    public var action: Selector? {
        
        return self.control?.action
    }
    
    
    public var tag: Int {
        
        return self.control?.tag ?? 0
    }
    
    
    
    // MARK: Private Methods
    
    private var control: NSControl? {
        
        return self.view as? NSControl
    }
    
}
