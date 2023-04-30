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
        case particallyAvailable
        case available
    }
    
    
    /// Create a SwiftUI image with an AppKit status image instance.
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
                return NSImage.statusNoneName
            case .unavailable:
                return NSImage.statusUnavailableName
            case .particallyAvailable:
                return NSImage.statusPartiallyAvailableName
            case .available:
                return NSImage.statusAvailableName
        }
    }
}


// MARK: - Preview

struct StatusImage_Previews: PreviewProvider {
    
    static var previews: some View {
        
        VStack(alignment: .leading) {
            Label(title: { Text(verbatim: "none") }, icon: { Image(status: .none) })
            Label(title: { Text(verbatim: "available") }, icon: { Image(status: .available) })
            Label(title: { Text(verbatim: "particallyAvailable") }, icon: { Image(status: .particallyAvailable) })
            Label(title: { Text(verbatim: "unavailable") }, icon: { Image(status: .unavailable) })
        }.padding()
    }
}
