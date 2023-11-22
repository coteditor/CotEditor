//
//  ActionCommand.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

struct ActionCommand: Identifiable {
    
    enum Kind {
        
        case command
        case outline
        case script
    }
    
    let id = UUID()
    
    var kind: Kind
    var title: String
    var paths: [String] = []
    var shortcut: Shortcut?
    
    var action: Selector
    var tag: Int = 0
    
    
    /// Perform the original menu action.
    @discardableResult
    func perform() -> Bool {
        
        let sender = NSMenuItem()
        sender.title = self.title
        sender.action = self.action
        sender.tag = self.tag
        
        return NSApp.sendAction(self.action, to: nil, from: sender)
    }
}


extension NSMenuItem {
    
    /// The flat collection of `ActionCommand` representation including  descendant items.
    var actionCommands: [ActionCommand] {
        
        if let submenu = self.submenu {
            return submenu.items
                .flatMap { $0.actionCommands }
                .map {
                    var command = $0
                    command.paths.insert(self.title, at: 0)
                    return command
                }
            
        } else if let action = self.action, !self.isHidden, !ActionCommand.unsupportedActions.contains(action) {
            self.validate()
            return [ActionCommand(kind: (action == #selector(ScriptManager.launchScript)) ? .script : .command,
                                  title: self.title, paths: [], shortcut: self.shortcut, action: action, tag: self.tag)]
            
        } else {
            return []
        }
    }
    
    
    /// Validate the menu item so that the menu item properties, such as title, are updated to fit to the latest states.
    private func validate() {
        
        guard
            let validator = self.target
                ?? self.action.flatMap({ NSApp.target(forAction: $0, to: self.target, from: self) }) as AnyObject?
        else { return }
        
        switch validator {
            case let validator as any NSMenuItemValidation:
                validator.validateMenuItem(self)
            case let validator as any NSUserInterfaceValidations:
                validator.validateUserInterfaceItem(self)
            default:
                break
        }
    }
}


private extension ActionCommand {
    
    static let unsupportedActions: [Selector] = [
        #selector(AppDelegate.showQuickActions),
    ]
}
