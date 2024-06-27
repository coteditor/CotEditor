//
//  Unicode.GeneralCategory+Name.swift
//  CharacterInfo
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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

public extension Unicode.GeneralCategory {
    
    /// The long value aliases for the category.
    var longName: String {
        
        switch self {
            case .uppercaseLetter: "Uppercase Letter"
            case .lowercaseLetter: "Lowercase Letter"
            case .titlecaseLetter: "Titlecase Letter"
                
            case .modifierLetter: "Modifier Letter"
            case .otherLetter: "Other Letter"
                
            case .nonspacingMark: "Nonspacing Mark"
            case .spacingMark: "Spacing Mark"
            case .enclosingMark: "Enclosing Mark"
                
            case .decimalNumber: "Decimal Number"
            case .letterNumber: "Letter Number"
            case .otherNumber: "Other Number"
                
            case .connectorPunctuation: "Connector Punctuation"
            case .dashPunctuation: "Dash Punctuation"
            case .openPunctuation: "Open Punctuation"
            case .closePunctuation: "Close Punctuation"
            case .initialPunctuation: "Initial Punctuation"
            case .finalPunctuation: "Final Punctuation"
            case .otherPunctuation: "Other Punctuation"
                
            case .mathSymbol: "Math Symbol"
            case .currencySymbol: "Currency Symbol"
            case .modifierSymbol: "Modifier Symbol"
            case .otherSymbol: "Other Symbol"
                
            case .spaceSeparator: "Space Separator"
            case .lineSeparator: "Line Separator"
            case .paragraphSeparator: "Paragraph Separator"
                
            case .control: "Control"
            case .format: "Format"
            case .surrogate: "Surrogate"
            case .privateUse: "Private Use"
            case .unassigned: "Unassigned"
                
            @unknown default: "(UNKNOWN)"
        }
    }
    
    
    /// The short, abbreviated property value aliases for the category.
    var shortName: String {
        
        switch self {
            case .uppercaseLetter: "Lu"
            case .lowercaseLetter: "Ll"
            case .titlecaseLetter: "Lt"
                
            case .modifierLetter: "Lm"
            case .otherLetter: "Lo"
                
            case .nonspacingMark: "Mn"
            case .spacingMark: "Mc"
            case .enclosingMark: "Me"
                
            case .decimalNumber: "Nd"
            case .letterNumber: "Nl"
            case .otherNumber: "No"
                
            case .connectorPunctuation: "Pc"
            case .dashPunctuation: "Pd"
            case .openPunctuation: "Ps"
            case .closePunctuation: "Pe"
            case .initialPunctuation: "Pi"
            case .finalPunctuation: "Pf"
            case .otherPunctuation: "Po"
                
            case .mathSymbol: "Sm"
            case .currencySymbol: "sc"
            case .modifierSymbol: "Sk"
            case .otherSymbol: "So"
                
            case .spaceSeparator: "Zs"
            case .lineSeparator: "Zl"
            case .paragraphSeparator: "Zp"
                
            case .control: "Cc"
            case .format: "Cf"
            case .surrogate: "Cs"
            case .privateUse: "Co"
            case .unassigned: "Cn"
                
            @unknown default: "?"
        }
    }
}
