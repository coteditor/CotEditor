//
//  DefaultOptions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

enum NoDocumentOnLaunchBehavior: Int {
    
    case none
    case untitledDocument
    case openPanel
}


enum DocumentConflictOption: Int {
    
    case ignore
    case notify
    case revert
}


enum WritingDirection: Int {
    
    case leftToRight
    case rightToLeft
    case vertical
}


enum FontPreference: Int {
    
    case automatic
    case monospaced
    case standard
}


enum AppearanceMode: Int {
    
    case `default`
    case light
    case dark
}


@objc enum PrintInfoType: Int, CaseIterable, DefaultInitializable {
    
    static let defaultValue: Self = .none
    
    case none
    case syntaxName
    case documentName
    case filePath
    case printDate
    case pageNumber
    case lastModifiedDate
    
    
    var label: String {
        
        switch self {
            case .none: String(localized: "None")
            case .syntaxName: String(localized: "Syntax Name")
            case .documentName: String(localized: "Document Name")
            case .filePath: String(localized: "File Path")
            case .printDate: String(localized: "Print Date")
            case .lastModifiedDate: String(localized: "Last Modified Date")
            case .pageNumber: String(localized: "Page Number")
        }
    }
}


@objc enum AlignmentType: Int, CaseIterable, DefaultInitializable {
    
    static let defaultValue: Self = .right
    
    case left
    case center
    case right
    
    
    var label: String {
        
        switch self {
            case .left:   String(localized: "Left")
            case .center: String(localized: "Center")
            case .right:  String(localized: "Right")
        }
    }
    
    
    var help: String {
        
        switch self {
            case .left:   String(localized: "Align Left")
            case .center: String(localized: "Center")
            case .right:  String(localized: "Align Right")
        }
    }
    
    
    var symbolName: String {
        
        switch self {
            case .left: "arrow.backward.to.line"
            case .center: "arrow.right.and.line.vertical.and.arrow.left"
            case .right: "arrow.forward.to.line"
        }
    }
}
