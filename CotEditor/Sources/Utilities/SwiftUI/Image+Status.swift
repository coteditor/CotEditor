//
//  Image.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-25.
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

import SwiftUI
import AppKit.NSImage

extension Image {
    
    enum Status {
        
        case none
        case unavailable
        case partiallyAvailable
        case available
    }
    
    
    /// Creates a SwiftUI image with an AppKit status image instance.
    ///
    /// - Parameter status: The NSImage status to display.
    init(status: Status) {
        
        self.init(nsImage: NSImage(named: status.imageName)!)
    }
}


private extension Image.Status {
    
    var imageName: NSImage.Name {
        
        switch self {
            case .none:
                NSImage.statusNoneName
            case .unavailable:
                NSImage.statusUnavailableName
            case .partiallyAvailable:
                NSImage.statusPartiallyAvailableName
            case .available:
                NSImage.statusAvailableName
        }
    }
}


// MARK: - Preview

#Preview {
    VStack(alignment: .leading) {
        Label(title: { Text("none") }, icon: { Image(status: .none) })
        Label(title: { Text("available") }, icon: { Image(status: .available) })
        Label(title: { Text("partiallyAvailable") }, icon: { Image(status: .partiallyAvailable) })
        Label(title: { Text("unavailable") }, icon: { Image(status: .unavailable) })
    }.padding()
}
