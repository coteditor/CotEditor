//
//  LineEnding+Localization.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-11-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

public extension LineEnding {
    
    var description: String {
        
        switch self {
            case .lf:
                String(localized: "LineEnding.lf.description",
                       defaultValue: "macOS / Unix",
                       bundle: .module)
            case .cr:
                String(localized: "LineEnding.cr.description",
                       defaultValue: "Classic Mac OS",
                       bundle: .module)
            case .crlf:
                String(localized: "LineEnding.crlf.description",
                       defaultValue: "Windows",
                       bundle: .module)
            case .nel:
                String(localized: "LineEnding.nel.description",
                       defaultValue: "Unix Next Line",
                       bundle: .module,
                       comment: "Since this is a technical term, it should be left as-is.")
            case .lineSeparator:
                String(localized: "LineEnding.lineSeparator.description",
                       defaultValue: "Unix Line Separator",
                       bundle: .module,
                       comment: "Since this is a technical term, it should be left as-is.")
            case .paragraphSeparator:
                String(localized: "LineEnding.paragraphSeparator.description",
                       defaultValue: "Unix Paragraph Separator",
                       bundle: .module,
                       comment: "Since this is a technical term, it should be left as-is.")
        }
    }
}
