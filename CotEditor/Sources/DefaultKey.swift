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

enum DefaultKey: String {
    
    // General
    case createNewAtStartup = "createNewAtStartup"
    case reopenBlankWindow = "reopenBlankWindow"
    case enablesAutosaveInPlace = "enablesAutosaveInPlace"
    case trimsTrailingWhitespaceOnSave = "trimsTrailingWhitespaceOnSave"
    case documentConflictOption = "documentConflictOption"
    case syncFindPboard = "syncFindPboard"
    case inlineContextualScriptMenu = "inlineContextualScriptMenu"
    case countLineEndingAsChar = "countLineEndingAsChar"
    case autoLinkDetection = "autoLinkDetectionKey"
    case checkSpellingAsType = "checkSpellingAsType"
    case highlightBraces = "highlightBraces"
    case highlightLtGt = "highlightLtGt"
    case checksUpdatesForBeta = "checksUpdatesForBeta"
    
    // Window
    case showNavigationBar = "showNavigationBar"
    case showDocumentInspector = "showDocumentInspector"
    case showStatusBar = "showStatusArea"
    case showLineNumbers = "showLineNumbers"
    case showPageGuide = "showPageGuide"
    case pageGuideColumn = "pageGuideColumn"
    case showStatusBarLines = "showStatusBarLines"
    case showStatusBarChars = "showStatusBarChars"
    case showStatusBarLength = "showStatusBarLength"
    case showStatusBarWords = "showStatusBarWords"
    case showStatusBarLocation = "showStatusBarLocation"
    case showStatusBarLine = "showStatusBarLine"
    case showStatusBarColumn = "showStatusBarColumn"
    case showStatusBarEncoding = "showStatusBarEncoding"
    case showStatusBarLineEndings = "showStatusBarLineEndings"
    case showStatusBarFileSize = "showStatusBarFileSize"
    case splitViewVertical = "splitViewVertical"
    case windowWidth = "windowWidth"
    case windowHeight = "windowHeight"
    case windowAlpha = "windowAlpha"
    
    // Appearance
    case fontName = "fontName"
    case fontSize = "fontSize"
    case shouldAntialias = "shouldAntialias"
    case lineHeight = "lineHeight"
    case highlightCurrentLine = "highlightCurrentLine"
    case showInvisibles = "showInvisibles"
    case showInvisibleSpace = "showInvisibleSpace"
    case invisibleSpace = "invisibleSpace"
    case showInvisibleTab = "showInvisibleTab"
    case invisibleTab = "invisibleTab"
    case showInvisibleNewLine = "showInvisibleNewLine"
    case invisibleNewLine = "invisibleNewLine"
    case showInvisibleFullwidthSpace = "showInvisibleZenkakuSpace"
    case invisibleFullwidthSpace = "invisibleZenkakuSpace"
    case showOtherInvisibleChars = "showOtherInvisibleChars"
    case theme = "defaultTheme"
    
    // Edit
    case smartInsertAndDelete = "smartInsertAndDelete"
    case balancesBrackets = "balancesBrackets"
    case swapYenAndBackSlash = "swapYenAndBackSlashKey"
    case enableSmartQuotes = "enableSmartQuotes"
    case enableSmartDashes = "enableSmartDashes"
    case autoIndent = "autoIndent"
    case tabWidth = "tabWidth"
    case autoExpandTab = "autoExpandTab"
    case detectsIndentStyle = "detectsIndentStyle"
    case appendsCommentSpacer = "appendsCommentSpacer"
    case commentsAtLineHead = "commentsAtLineHead"
    case wrapLines = "wrapLines"
    case enablesHangingIndent = "enableHangingIndent"
    case hangingIndentWidth = "hangingIndentWidth"
    case completesDocumentWords = "completesDocumentWords"
    case completesSyntaxWords = "completesSyntaxWords"
    case completesStandartWords = "completesStandardWords"
    case autoComplete = "autoComplete"
    
    // Format
    case lineEndCharCode = "defaultLineEndCharCode"
    case encodingList = "encodingList"
    case encodingInNew = "encodingInNew"
    case encodingInOpen = "encodingInOpen"
    case saveUTF8BOM = "saveUTF8BOM"
    case referToEncodingTag = "referToEncodingTag"
    case enableSyntaxHighlight = "doSyntaxColoring"
    case syntaxStyle = "defaultColoringStyleName"
    
    // File Drop
    case fileDropArray = "fileDropArray"
    
    // Key Bindings
    case insertCustomTextArray = "insertCustomTextArray"
    
    // Print
    case setPrintFont = "setPrintFont"
    case printFontName = "printFontName"
    case printFontSize = "printFontSize"
    case printColorIndex = "printColorIndex"
    case printTheme = "printTheme"
    case printLineNumIndex = "printLineNumIndex"
    case printInvisibleCharIndex = "printInvisibleCharIndex"
    case printHeader = "printHeader"
    case primaryHeaderContent = "headerOneStringIndex"
    case primaryHeaderAlignment = "headerOneAlignIndex"
    case secondaryHeaderContent = "headerTwoStringIndex"
    case secondaryHeaderAlignment = "headerTwoAlignIndex"
    case printFooter = "printFooter"
    case primaryFooterContent = "footerOneStringIndex"
    case primaryFooterAlignment = "footerOneAlignIndex"
    case secondaryFooterContent = "footerTwoStringIndex"
    case secondaryFooterAlignment = "footerTwoAlignIndex"
    
    
    // find panel
    case findHistory = "findHistory"
    case replaceHistory = "replaceHistory"
    case findUsesRegularExpression = "findUsesRegularExpression"
    case findIgnoresCase = "findIgnoresCase"
    case findInSelection = "findInSelection"
    case findIsWrap = "findIsWrap"
    case findNextAfterReplace = "findsNextAfterReplace"
    case findClosesIndicatorWhenDone = "findClosesIndicatorWhenDone"
    
    case findTextIsLiteralSearch = "findTextIsLiteralSearch"
    case findTextIgnoresDiacriticMarks = "findTextIgnoresDiacriticMarks"
    case findTextIgnoresWidth = "findTextIgnoresWidth"
    case findRegexIsSingleline = "findRegexIsSingleline"
    case findRegexIsMultiline = "findRegexIsMultiline"
    case FindRegexUsesUnicodeBoundaries = "regexUsesUnicodeBoundaries"
    
    // settings that are not in preferences
    case colorCodeType = "colorCodeType"
    case sidebarWidth = "sidebarWidth"
    case recentStyleNames = "recentStyleNames"
    
    // hidden settings
    case usesTextFontForInvisibles = "usesTextFontForInvisibles"
    case headerFooterDateFormat = "headerFooterDateFormat"
    case headerFooterPathAbbreviatingWithTilde = "headerFooterPathAbbreviatingWithTilde"
    case autoCompletionDelay = "autoCompletionDelay"
    case infoUpdateInterval = "infoUpdateInterval"
    case outlineMenuInterval = "outlineMenuInterval"
    case showColoringIndicatorTextLength = "showColoringIndicatorTextLength"
    case coloringRangeBufferLength = "coloringRangeBufferLength"
    case largeFileAlertThreshold = "largeFileAlertThreshold"
    case autosavingDelay = "autosavingDelay"
    case savesTextOrientation = "savesTextOrientation"
    case layoutTextVertical = "layoutTextVertical"
    case enableSmartIndent = "enableSmartIndent"
    case maximumRecentStyleCount = "maximumRecentStyleCount"
    
    case lastVersion = "lastVersion"

}


// MARK: Default Values

enum DocumentConflictOption: Int {
    
    case ignore
    case notify
    case revert
}


enum PrintColorMode: Int {
    
    case blackWhite
    case sameAsDocument
}


enum PrintLineNmuberMode: Int {
    
    case no
    case sameAsDocument
    case yes
}


enum PrintInvisiblesMode: Int {
    
    case no
    case sameAsDocument
    case all
}


enum PrintInfoType: Int {
    
    case none
    case syntaxName
    case documentName
    case filePath
    case printDate
    case pageNumber
}


enum AlignmentType: Int {
    
    case left
    case center
    case right
}
