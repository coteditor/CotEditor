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
        case script
    }
    
    
    let id = UUID()
    
    var kind: Kind
    var title: String
    var paths: [String] = []
    var shortcut: Shortcut?
    
    var action: Selector
    var target: Any?
    var tag: Int = 0
    var representedObject: Any?
    
    
    /// Performs the original menu action.
    @discardableResult
    @MainActor func perform() -> Bool {
        
        let sender = NSMenuItem()
        sender.title = self.title
        sender.action = self.action
        sender.tag = self.tag
        sender.representedObject = self.representedObject
        
        return NSApp.sendAction(self.action, to: self.target, from: sender)
    }
}


extension ActionCommand {
    
    struct MatchedPath {
        
        var string: String
        var ranges: [Range<String.Index>]
    }
    
    
    func match(command: String) -> (result: [MatchedPath], score: Int)? {
        
        guard !command.isEmpty else { return nil }
        
        var matches: [MatchedPath] = []
        var score = 0
        var remaining = command
        for string in (self.paths[1...] + [self.title]) {
            let match = string.abbreviatedMatch(with: remaining)
            
            if matches.isEmpty, match == nil { continue }
            
            matches.append(.init(string: string, ranges: match?.ranges ?? []))
            score += match?.score ?? 0
            remaining = match?.remaining ?? remaining
        }
        
        guard remaining.isEmpty else { return nil }
        
        return (matches, score)
    }
}


extension NSApplication {
    
    /// All active ActionCommands in the main menu for the Quick Action bar.
    final var actionCommands: [ActionCommand] {
        
        self.mainMenu?.items.flatMap(\.actionCommands) ?? []
    }
}



// MARK: - Private Extensions

private extension NSMenuItem {
    
    /// The flat collection of `ActionCommand` representation including descendant items.
    var actionCommands: [ActionCommand] {
        
        if let submenu = self.submenu {
            submenu.update()
            return submenu.items
                .flatMap(\.actionCommands)
                .map {
                    var command = $0
                    command.paths.insert(self.title, at: 0)
                    return command
                }
            
        } else if self.isEnabled, !self.isHidden, let action = self.action, !ActionCommand.unsupportedActions.contains(action) {
            return [ActionCommand(kind: (action == #selector(ScriptManager.launchScript)) ? .script : .command,
                                  title: self.actionTitle, paths: [], shortcut: self.shortcut?.normalized, action: action, target: self.target, tag: self.tag,
                                  representedObject: self.representedObject)]
            
        } else {
            return []
        }
    }
    
    
    /// The title for command action.
    private var actionTitle: String {
        
        // append the device name to the title for "Insert from iPhone/iPad" actions
        guard
            self.action == Selector(("importFromDevice:")),
            let siblings = self.menu?.items,
            let index = siblings.firstIndex(of: self),
            let deviceNameItem = siblings[0..<index].last(where: { !$0.isEnabled && $0.action == Selector(("_importFromDeviceText:")) })
        else { return self.title }
        
        return "\(self.title) (\(deviceNameItem.title))"
    }
}


private extension ActionCommand {
    
    static let unsupportedActions: [Selector] = [
        #selector(AppDelegate.showQuickActions),
        Selector(("_importFromDeviceText:")),
    ]
}
