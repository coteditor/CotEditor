//
//  SymbolResource.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

import SwiftUI
import AppKit

enum SymbolResource {
    
    case resource(_ resource: ImageResource)
    case system(_ name: String)
}

    
extension SymbolResource {
    
    /// Returns a SwiftUI Image for the underlying resource or system symbol.
    var image: SwiftUI.Image {
        
        switch self {
            case .resource(let resource):
                Image(resource)
            case .system(let name):
                Image(systemName: name)
        }
    }
    
    
    /// Creates an `NSImage` for AppKit from the underlying resource or system symbol.
    ///
    /// - Parameters:
    ///   - variant: An optional SF Symbol variant suffix appended to the system name (e.g., ".fill").
    ///   - accessibilityDescription: A description for accessibility.
    /// - Returns: An `NSImage` instance, or `nil` if the system symbol cannot be created.
    func nsImage(variant: String = "", accessibilityDescription: String? = nil) -> NSImage! {
        
        switch self {
            case .resource(let resource):
                NSImage(resource: resource)
            case .system(let name):
                NSImage(systemSymbolName: name + variant, accessibilityDescription: accessibilityDescription)
        }
    }
}
