/*
 
 DefaultKey.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

typealias DefaultKey = String
extension DefaultKey {
    
    // General
    static let createNewAtStartup = "createNewAtStartup"
    static let reopenBlankWindow = "reopenBlankWindow"
    static let enablesAutosaveInPlace = "enablesAutosaveInPlace"
    static let trimsTrailingWhitespaceOnSave = "trimsTrailingWhitespaceOnSave"
    static let documentConflictOption = "documentConflictOption"
    static let syncFindPboard = "syncFindPboard"
    static let inlineContextualScriptMenu = "inlineContextualScriptMenu"
    static let countLineEndingAsChar = "countLineEndingAsChar"
    static let autoLinkDetection = "autoLinkDetectionKey"
    static let checkSpellingAsType = "checkSpellingAsType"
    static let highlightBraces = "highlightBraces"
    static let highlightLtGt = "highlightLtGt"
    static let checksUpdatesForBeta = "checksUpdatesForBeta"
    
    // Window
    static let showNavigationBar = "showNavigationBar"
    static let showDocumentInspector = "showDocumentInspector"
    static let showStatusBar = "showStatusArea"
    static let showLineNumbers = "showLineNumbers"
    static let showPageGuide = "showPageGuide"
    static let pageGuideColumn = "pageGuideColumn"
    static let showStatusBarLines = "showStatusBarLines"
    static let showStatusBarChars = "showStatusBarChars"
    static let showStatusBarLength = "showStatusBarLength"
    static let showStatusBarWords = "showStatusBarWords"
    static let showStatusBarLocation = "showStatusBarLocation"
    static let showStatusBarLine = "showStatusBarLine"
    static let showStatusBarColumn = "showStatusBarColumn"
    static let showStatusBarEncoding = "showStatusBarEncoding"
    static let showStatusBarLineEndings = "showStatusBarLineEndings"
    static let showStatusBarFileSize = "showStatusBarFileSize"
    static let splitViewVertical = "splitViewVertical"
    static let windowWidth = "windowWidth"
    static let windowHeight = "windowHeight"
    static let windowAlpha = "windowAlpha"
    
    // Appearance
    static let fontName = "fontName"
    static let fontSize = "fontSize"
    static let shouldAntialias = "shouldAntialias"
    static let lineHeight = "lineHeight"
    static let highlightCurrentLine = "highlightCurrentLine"
    static let showInvisibles = "showInvisibles"
    static let showInvisibleSpace = "showInvisibleSpace"
    static let invisibleSpace = "invisibleSpace"
    static let showInvisibleTab = "showInvisibleTab"
    static let invisibleTab = "invisibleTab"
    static let showInvisibleNewLine = "showInvisibleNewLine"
    static let invisibleNewLine = "invisibleNewLine"
    static let showInvisibleFullwidthSpace = "showInvisibleZenkakuSpace"
    static let invisibleFullwidthSpace = "invisibleZenkakuSpace"
    static let showOtherInvisibleChars = "showOtherInvisibleChars"
    static let theme = "defaultTheme"
    
    // Edit
    static let smartInsertAndDelete = "smartInsertAndDelete"
    static let balancesBrackets = "balancesBrackets"
    static let swapYenAndBackSlash = "swapYenAndBackSlashKey"
    static let enableSmartQuotes = "enableSmartQuotes"
    static let enableSmartDashes = "enableSmartDashes"
    static let autoIndent = "autoIndent"
    static let tabWidth = "tabWidth"
    static let autoExpandTab = "autoExpandTab"
    static let detectsIndentStyle = "detectsIndentStyle"
    static let appendsCommentSpacer = "appendsCommentSpacer"
    static let commentsAtLineHead = "commentsAtLineHead"
    static let wrapLines = "wrapLines"
    static let enablesHangingIndent = "enableHangingIndent"
    static let hangingIndentWidth = "hangingIndentWidth"
    static let completesDocumentWords = "completesDocumentWords"
    static let completesSyntaxWords = "completesSyntaxWords"
    static let completesStandartWords = "completesStandardWords"
    static let autoComplete = "autoComplete"
    
    // Format
    static let lineEndCharCode = "defaultLineEndCharCode"
    static let encodingList = "encodingList"
    static let encodingInNew = "encodingInNew"
    static let encodingInOpen = "encodingInOpen"
    static let saveUTF8BOM = "saveUTF8BOM"
    static let referToEncodingTag = "referToEncodingTag"
    static let enableSyntaxHighlight = "doSyntaxColoring"
    static let syntaxStyle = "defaultColoringStyleName"
    
    // File Drop
    static let fileDropArray = "fileDropArray"
    
    // Key Bindings
    static let insertCustomTextArray = "insertCustomTextArray"
    
    // Print
    static let setPrintFont = "setPrintFont"
    static let printFontName = "printFontName"
    static let printFontSize = "printFontSize"
    static let printColorIndex = "printColorIndex"
    static let printTheme = "printTheme"
    static let printLineNumIndex = "printLineNumIndex"
    static let printInvisibleCharIndex = "printInvisibleCharIndex"
    static let printHeader = "printHeader"
    static let primaryHeaderContent = "headerOneStringIndex"
    static let primaryHeaderAlignment = "headerOneAlignIndex"
    static let secondaryHeaderContent = "headerTwoStringIndex"
    static let secondaryHeaderAlignment = "headerTwoAlignIndex"
    static let printFooter = "printFooter"
    static let primaryFooterContent = "footerOneStringIndex"
    static let primaryFooterAlignment = "footerOneAlignIndex"
    static let secondaryFooterContent = "footerTwoStringIndex"
    static let secondaryFooterAlignment = "footerTwoAlignIndex"
    
    
    // find panel
    static let findHistory = "findHistory"
    static let replaceHistory = "replaceHistory"
    static let findUsesRegularExpression = "findUsesRegularExpression"
    static let findIgnoresCase = "findIgnoresCase"
    static let findInSelection = "findInSelection"
    static let findIsWrap = "findIsWrap"
    static let findNextAfterReplace = "findsNextAfterReplace"
    static let findClosesIndicatorWhenDone = "findClosesIndicatorWhenDone"
    
    static let findTextIsLiteralSearch = "findTextIsLiteralSearch"
    static let findTextIgnoresDiacriticMarks = "findTextIgnoresDiacriticMarks"
    static let findTextIgnoresWidth = "findTextIgnoresWidth"
    static let findRegexIsSingleline = "findRegexIsSingleline"
    static let findRegexIsMultiline = "findRegexIsMultiline"
    static let findRegexUsesUnicodeBoundaries = "regexUsesUnicodeBoundaries"
    
    // settings that are not in preferences
    static let colorCodeType = "colorCodeType"
    static let sidebarWidth = "sidebarWidth"
    static let recentStyleNames = "recentStyleNames"
    
    // hidden settings
    static let usesTextFontForInvisibles = "usesTextFontForInvisibles"
    static let headerFooterDateFormat = "headerFooterDateFormat"
    static let headerFooterPathAbbreviatingWithTilde = "headerFooterPathAbbreviatingWithTilde"
    static let autoCompletionDelay = "autoCompletionDelay"
    static let infoUpdateInterval = "infoUpdateInterval"
    static let outlineMenuInterval = "outlineMenuInterval"
    static let showColoringIndicatorTextLength = "showColoringIndicatorTextLength"
    static let coloringRangeBufferLength = "coloringRangeBufferLength"
    static let largeFileAlertThreshold = "largeFileAlertThreshold"
    static let autosavingDelay = "autosavingDelay"
    static let savesTextOrientation = "savesTextOrientation"
    static let layoutTextVertical = "layoutTextVertical"
    static let enableSmartIndent = "enableSmartIndent"
    static let maximumRecentStyleCount = "maximumRecentStyleCount"
    
    static let lastVersion = "lastVersion"

}


// MARK: Default Values

enum DocumentConflictOption: Int {
    
    case ignore
    case notify
    case revert
}


@objc enum PrintColorMode: Int {
    
    case blackWhite
    case sameAsDocument
}


@objc enum PrintLineNmuberMode: Int {
    
    case no
    case sameAsDocument
    case yes
}


@objc enum PrintInvisiblesMode: Int {
    
    case no
    case sameAsDocument
    case all
}


@objc enum PrintInfoType: Int {
    
    case none
    case syntaxName
    case documentName
    case filePath
    case printDate
    case pageNumber
}


@objc enum AlignmentType: Int {
    
    case left
    case center
    case right
    
    
    var textAlignment: NSTextAlignment {
        
        switch self {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        }
    }
}
