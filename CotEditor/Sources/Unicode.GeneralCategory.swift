//
//  Unicode.GeneralCategory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

extension Unicode.GeneralCategory {
    
    /// The long value aliases for the category.
    var longName: String {
        
        switch self {
            case .uppercaseLetter:
                return "Uppercase Letter"
            case .lowercaseLetter:
                return "Lowercase Letter"
            case .titlecaseLetter:
                return "Titlecase Letter"
                
            case .modifierLetter:
                return "Modifier Letter"
            case .otherLetter:
                return "Other Letter"
                
            case .nonspacingMark:
                return "Nonspacing Mark"
            case .spacingMark:
                return "Spacing Mark"
            case .enclosingMark:
                return "Enclosing Mark"
                
            case .decimalNumber:
                return "Decimal Number"
            case .letterNumber:
                return "Letter Number"
            case .otherNumber:
                return "Other Number"
                
            case .connectorPunctuation:
                return "Connector Punctuation"
            case .dashPunctuation:
                return "Dash Punctuation"
            case .openPunctuation:
                return "Open Punctuation"
            case .closePunctuation:
                return "Close Punctuation"
            case .initialPunctuation:
                return "Initial Punctuation"
            case .finalPunctuation:
                return "Final Punctuation"
            case .otherPunctuation:
                return "Other Punctuation"
                
            case .mathSymbol:
                return "Math Symbol"
            case .currencySymbol:
                return "Currency Symbol"
            case .modifierSymbol:
                return "Modifier Symbol"
            case .otherSymbol:
                return "Other Symbol"
                
            case .spaceSeparator:
                return "Space Separator"
            case .lineSeparator:
                return "Line Separator"
            case .paragraphSeparator:
                return "Paragraph Separator"
                
            case .control:
                return "Control"
            case .format:
                return "Format"
            case .surrogate:
                return "Surrogate"
            case .privateUse:
                return "Private Use"
            case .unassigned:
                return "Unassigned"
                
            @unknown default:
                assertionFailure()
                return "(UNKNOWN)"
        }
    }
    
    
    /// The short, abbreviated property value aliases for the category.
    var shortName: String {
        
        switch self {
            case .uppercaseLetter:
                return "Lu"
            case .lowercaseLetter:
                return "Ll"
            case .titlecaseLetter:
                return "Lt"
                
            case .modifierLetter:
                return "Lm"
            case .otherLetter:
                return "Lo"
                
            case .nonspacingMark:
                return "Mn"
            case .spacingMark:
                return "Mc"
            case .enclosingMark:
                return "Me"
                
            case .decimalNumber:
                return "Nd"
            case .letterNumber:
                return "Nl"
            case .otherNumber:
                return "No"
                
            case .connectorPunctuation:
                return "Pc"
            case .dashPunctuation:
                return "Pd"
            case .openPunctuation:
                return "Ps"
            case .closePunctuation:
                return "Pe"
            case .initialPunctuation:
                return "Pi"
            case .finalPunctuation:
                return "Pf"
            case .otherPunctuation:
                return "Po"
                
            case .mathSymbol:
                return "Sm"
            case .currencySymbol:
                return "sc"
            case .modifierSymbol:
                return "Sk"
            case .otherSymbol:
                return "So"
                
            case .spaceSeparator:
                return "Zs"
            case .lineSeparator:
                return "Zl"
            case .paragraphSeparator:
                return "Zp"
                
            case .control:
                return "Cc"
            case .format:
                return "Cf"
            case .surrogate:
                return "Cs"
            case .privateUse:
                return "Co"
            case .unassigned:
                return "Cn"
                
            @unknown default:
                assertionFailure()
                return "?"
        }
    }
}
