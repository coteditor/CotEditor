//
//  SegmentedArrayControl.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-10-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2023 1024jp
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
import Combine

final class SegmentedArrayControl: NSSegmentedControl {
    
    // MARK: Private Properties
    
    private var arrayObservers: Set<AnyCancellable> = []
    
    @IBOutlet private var arrayController: NSArrayController? {
        
        didSet {
            self.target = self
            self.action = #selector(addRemove)
            
            if let arrayController {
                self.arrayObservers = [
                    arrayController.publisher(for: \.canAdd, options: .initial)
                        .sink { [weak self] in self?.setEnabled($0, forSegment: 0) },
                    arrayController.publisher(for: \.canRemove, options: .initial)
                        .sink { [weak self] in self?.setEnabled($0, forSegment: 1) },
                ]
            } else {
                self.arrayObservers.removeAll()
            }
        }
    }
    
    
    
    // MARK: -
    // MARK: Action Messages
    
    @IBAction func addRemove(_ sender: NSSegmentedControl) {
        
        guard
            sender == self,
            let arrayController = self.arrayController
        else { return assertionFailure() }
        
        switch sender.selectedSegment {
            case 0:  // add
                guard arrayController.canAdd else { return assertionFailure() }
                self.window?.makeFirstResponder(nil)  // end current editing
                arrayController.add(sender)
                
            case 1:  // remove
                guard arrayController.canRemove else { return assertionFailure() }
                self.window?.makeFirstResponder(nil)  // end current editing
                arrayController.remove(sender)
                
            default:
                preconditionFailure()
        }
    }
}
