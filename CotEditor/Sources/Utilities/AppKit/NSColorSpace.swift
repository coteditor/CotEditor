//
//  NSColorSpace.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-11-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

import AppKit.NSColorSpace

extension NSColorSpace.Model {
    
    /// The localized name.
    var localizedName: String? {
        
        switch self {
            case .unknown:
                nil
            case .gray:
                String(localized: "NSColorSpace.Model.gray", defaultValue: "Gray")
            case .rgb:
                String(localized: "NSColorSpace.Model.rgb", defaultValue: "RGB")
            case .cmyk:
                String(localized: "NSColorSpace.Model.cmyk", defaultValue: "CMYK")
            case .lab:
                String(localized: "NSColorSpace.Model.lab", defaultValue: "Lab")
            case .deviceN:
                String(localized: "NSColorSpace.Model.deviceN", defaultValue: "DeviceN",
                       comment: "refer kCGColorSpaceModelDeviceN")
            case .indexed:
                String(localized: "NSColorSpace.Model.indexed", defaultValue: "Indexed",
                       comment: "refer kCGColorSpaceModelIndexed")
            case .patterned:
                String(localized: "NSColorSpace.Model.patterned", defaultValue: "Pattern",
                       comment: "refer kCGColorSpaceModelPattern")
            @unknown default:
                nil
        }
    }
}
