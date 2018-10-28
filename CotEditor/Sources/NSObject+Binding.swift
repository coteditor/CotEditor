//
//  NSObject+Binding.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

extension NSObject {
    
    /// update binding options
    func rebind(_ binding: NSBindingName, updateHandler: (_ options: inout [NSBindingOption: Any]) -> Void) {
        
        guard
            let bindingInfo = self.infoForBinding(binding),
            let object = bindingInfo[.observedObject],
            let keyPath = bindingInfo[.observedKeyPath] as? String
            else { return assertionFailure() }
        
        var options = bindingInfo[.options] as? [NSBindingOption: Any] ?? [:]
        updateHandler(&options)
        
        self.unbind(binding)
        self.bind(binding, to: object, withKeyPath: keyPath, options: options)
    }
    
}
