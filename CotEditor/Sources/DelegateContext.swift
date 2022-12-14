//
//  DelegateContext.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-09-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

import Foundation.NSObjCRuntime

struct DelegateContext {
    
    var delegate: Any?
    var selector: Selector?
    var contextInfo: UnsafeMutableRawPointer?
    
    
    /// Manually invoke the original delegate method stored as a DelegateContext.
    ///
    /// - SeeAlso: *Advice for Overriders of Methods that Follow the delegate:didSomethingSelector:contextInfo: Pattern* in
    ///   <https://developer.apple.com/library/archive/releasenotes/AppKit/RN-AppKitOlderNotes/>.
    ///
    /// - Parameters:
    ///   - caller: The object sent as the third argument.
    ///   - flag: The boolean flag to tell the result state to the delegate.
    func perform(from caller: AnyObject, flag: Bool) {
        
        guard
            let delegate = self.delegate as? AnyObject,
            let selector = self.selector,
            let objcClass = objc_getClass(delegate.className) as? AnyClass,
            let method = class_getMethodImplementation(objcClass, selector)
        else { return assertionFailure() }
        
        typealias Signature = @convention(c) (AnyObject, Selector, AnyObject, Bool, UnsafeMutableRawPointer?) -> Void
        let function = unsafeBitCast(method, to: Signature.self)
        
        function(delegate, selector, caller, flag, self.contextInfo)
    }
}
