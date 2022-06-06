//
//  DefaultKeys.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import CoreGraphics

extension DefaultKeys {
    
    // General
    static let quitAlwaysKeepsWindows = DefaultKey<Bool>("NSQuitAlwaysKeepsWindows")
    static let noDocumentOnLaunchBehavior = RawRepresentableDefaultKey<NoDocumentOnLaunchBehavior>("noDocumentOnLaunchBehavior")
    static let enablesAutosaveInPlace = DefaultKey<Bool>("enablesAutosaveInPlace")
    static let documentConflictOption = RawRepresentableDefaultKey<DocumentConflictOption>("documentConflictOption")
    static let countLineEndingAsChar = DefaultKey<Bool>("countLineEndingAsChar")
    static let autoLinkDetection = DefaultKey<Bool>("autoLinkDetectionKey")
    static let checkSpellingAsType = DefaultKey<Bool>("checkSpellingAsType")
    static let highlightBraces = DefaultKey<Bool>("highlightBraces")
    static let highlightLtGt = DefaultKey<Bool>("highlightLtGt")
    static let highlightSelectionInstance = DefaultKey<Bool>("highlightSelectionInstance")
    static let selectionInstanceHighlightDelay = DefaultKey<Double>("selectionInstanceHighlightDelay")
    static let checksUpdatesForBeta = DefaultKey<Bool>("checksUpdatesForBeta")
    
    // Window
    static let windowTabbing = DefaultKey<Int>("windowTabbing")
    static let showNavigationBar = DefaultKey<Bool>("showNavigationBar")
    static let showLineNumbers = DefaultKey<Bool>("showLineNumbers")
    static let showPageGuide = DefaultKey<Bool>("showPageGuide")
    static let pageGuideColumn = DefaultKey<Int>("pageGuideColumn")
    static let writingDirection = RawRepresentableDefaultKey<WritingDirection>("writingDirection")
    static let overscrollRate = DefaultKey<CGFloat>("overscrollRate")
    static let showStatusBarLines = DefaultKey<Bool>("showStatusBarLines")
    static let showStatusBarChars = DefaultKey<Bool>("showStatusBarChars")
    static let showStatusBarWords = DefaultKey<Bool>("showStatusBarWords")
    static let showStatusBarLocation = DefaultKey<Bool>("showStatusBarLocation")
    static let showStatusBarLine = DefaultKey<Bool>("showStatusBarLine")
    static let showStatusBarColumn = DefaultKey<Bool>("showStatusBarColumn")
    static let showStatusBarFileSize = DefaultKey<Bool>("showStatusBarFileSize")
    static let windowWidth = DefaultKey<CGFloat>("windowWidth")
    static let windowHeight = DefaultKey<CGFloat>("windowHeight")
    static let splitViewVertical = DefaultKey<Bool>("splitViewVertical")
    static let windowAlpha = DefaultKey<CGFloat>("windowAlpha")
    
    // Appearance
    static let fontName = DefaultKey<String>("fontName")
    static let fontSize = DefaultKey<CGFloat>("fontSize")
    static let shouldAntialias = DefaultKey<Bool>("shouldAntialias")
    static let ligature = DefaultKey<Bool>("ligature")
    static let lineHeight = DefaultKey<CGFloat>("lineHeight")
    static let highlightCurrentLine = DefaultKey<Bool>("highlightCurrentLine")
    static let cursorType = RawRepresentableDefaultKey<CursorType>("cursorType")
    static let showInvisibles = DefaultKey<Bool>("showInvisibles")
    static let showInvisibleNewLine = DefaultKey<Bool>("showInvisibleNewLine")
    static let showInvisibleTab = DefaultKey<Bool>("showInvisibleTab")
    static let showInvisibleSpace = DefaultKey<Bool>("showInvisibleSpace")
    static let showInvisibleWhitespaces = DefaultKey<Bool>("showInvisibleWhitespaces")
    static let showInvisibleControl = DefaultKey<Bool>("showOtherInvisibleChars")
    static let showIndentGuides = DefaultKey<Bool>("showIndentGuides")
    static let documentAppearance = RawRepresentableDefaultKey<AppearanceMode>("appearance")
    static let theme = DefaultKey<String>("defaultTheme")
    
    // Edit
    static let smartInsertAndDelete = DefaultKey<Bool>("smartInsertAndDelete")
    static let balancesBrackets = DefaultKey<Bool>("balancesBrackets")
    static let swapYenAndBackSlash = DefaultKey<Bool>("swapYenAndBackSlashKey")
    static let enableSmartQuotes = DefaultKey<Bool>("enableSmartQuotes")
    static let enableSmartDashes = DefaultKey<Bool>("enableSmartDashes")
    static let autoTrimsTrailingWhitespace = DefaultKey<Bool>("autoTrimsTrailingWhitespace")
    static let trimsWhitespaceOnlyLines = DefaultKey<Bool>("trimsWhitespaceOnlyLines")
    static let autoIndent = DefaultKey<Bool>("autoIndent")
    static let tabWidth = DefaultKey<Int>("tabWidth")
    static let autoExpandTab = DefaultKey<Bool>("autoExpandTab")
    static let detectsIndentStyle = DefaultKey<Bool>("detectsIndentStyle")
    static let indentWithTabKey = DefaultKey<Bool>("indentWithTabKey")
    static let wrapLines = DefaultKey<Bool>("wrapLines")
    static let enablesHangingIndent = DefaultKey<Bool>("enableHangingIndent")
    static let hangingIndentWidth = DefaultKey<Int>("hangingIndentWidth")
    static let appendsCommentSpacer = DefaultKey<Bool>("appendsCommentSpacer")
    static let commentsAtLineHead = DefaultKey<Bool>("commentsAtLineHead")
    static let completesDocumentWords = DefaultKey<Bool>("completesDocumentWords")
    static let completesSyntaxWords = DefaultKey<Bool>("completesSyntaxWords")
    static let completesStandartWords = DefaultKey<Bool>("completesStandardWords")
    static let autoComplete = DefaultKey<Bool>("autoComplete")
    
    // Format
    static let lineEndCharCode = DefaultKey<Int>("defaultLineEndCharCode")
    static let encodingList = DefaultKey<[CFStringEncoding]>("encodingList")
    static let encodingInNew = DefaultKey<UInt>("encodingInNew")
    static let saveUTF8BOM = DefaultKey<Bool>("saveUTF8BOM")
    static let referToEncodingTag = DefaultKey<Bool>("referToEncodingTag")
    static let enableSyntaxHighlight = DefaultKey<Bool>("doSyntaxColoring")
    static let syntaxStyle = DefaultKey<String>("defaultColoringStyleName")
    
    // File Drop
    static let fileDropArray = DefaultKey<[[String: String]]>("fileDropArray")
    
    // Key Bindings
    static let insertCustomTextArray = DefaultKey<[String]>("insertCustomTextArray")
    
    // Print
    static let setPrintFont = DefaultKey<Bool>("setPrintFont")
    static let printFontName = DefaultKey<String>("printFontName")
    static let printFontSize = DefaultKey<CGFloat>("printFontSize")
    static let printColorIndex = DefaultKey<Int>("printColorIndex")
    static let printTheme = DefaultKey<String?>("printTheme")
    static let printBackground = DefaultKey<Bool>("printBackground")
    static let printLineNumIndex = RawRepresentableDefaultKey<PrintVisibilityMode>("printLineNumIndex")
    static let printInvisibleCharIndex = RawRepresentableDefaultKey<PrintVisibilityMode>("printInvisibleCharIndex")
    static let printHeader = DefaultKey<Bool>("printHeader")
    static let primaryHeaderContent = RawRepresentableDefaultKey<PrintInfoType>("headerOneStringIndex")
    static let primaryHeaderAlignment = RawRepresentableDefaultKey<AlignmentType>("headerOneAlignIndex")
    static let secondaryHeaderContent = RawRepresentableDefaultKey<PrintInfoType>("headerTwoStringIndex")
    static let secondaryHeaderAlignment = RawRepresentableDefaultKey<AlignmentType>("headerTwoAlignIndex")
    static let printFooter = DefaultKey<Bool>("printFooter")
    static let primaryFooterContent = RawRepresentableDefaultKey<PrintInfoType>("footerOneStringIndex")
    static let primaryFooterAlignment = RawRepresentableDefaultKey<AlignmentType>("footerOneAlignIndex")
    static let secondaryFooterContent = RawRepresentableDefaultKey<PrintInfoType>("footerTwoStringIndex")
    static let secondaryFooterAlignment = RawRepresentableDefaultKey<AlignmentType>("footerTwoAlignIndex")
    
    
    // find panel
    static let findHistory = DefaultKey<[String]>("findHistory")
    static let replaceHistory = DefaultKey<[String]>("replaceHistory")
    static let findUsesRegularExpression = DefaultKey<Bool>("findUsesRegularExpression")
    static let findIgnoresCase = DefaultKey<Bool>("findIgnoresCase")
    static let findInSelection = DefaultKey<Bool>("findInSelection")
    static let findIsWrap = DefaultKey<Bool>("findIsWrap")
    static let findMatchesFullWord = DefaultKey<Bool>("findMatchesFullWord")
    static let findNextAfterReplace = DefaultKey<Bool>("findsNextAfterReplace")
    static let findClosesIndicatorWhenDone = DefaultKey<Bool>("findClosesIndicatorWhenDone")
    
    static let findTextIsLiteralSearch = DefaultKey<Bool>("findTextIsLiteralSearch")
    static let findTextIgnoresDiacriticMarks = DefaultKey<Bool>("findTextIgnoresDiacriticMarks")
    static let findTextIgnoresWidth = DefaultKey<Bool>("findTextIgnoresWidth")
    static let findRegexIsSingleline = DefaultKey<Bool>("findRegexIsSingleline")
    static let findRegexIsMultiline = DefaultKey<Bool>("findRegexIsMultiline")
    static let findRegexUsesUnicodeBoundaries = DefaultKey<Bool>("regexUsesUnicodeBoundaries")
    static let findRegexUnescapesReplacementString = DefaultKey<Bool>("regexUnescapesReplacementString")
    
    // settings that are not in preferences
    static let pinsThemeAppearance = DefaultKey<Bool>("pinsThemeAppearance")
    static let lastPreferencesPaneIdentifier = DefaultKey<String?>("lastPreferencesPaneIdentifier")
    static let colorCodeType = DefaultKey<Int>("colorCodeType")
    static let sidebarWidth = DefaultKey<CGFloat>("sidebarWidth")
    static let recentStyleNames = DefaultKey<[String]>("recentStyleNames")
    static let showStatusBar = DefaultKey<Bool>("showStatusArea")
    static let selectedInspectorPaneIndex = DefaultKey<Int>("selectedInspectorPaneIndex")
    static let outlineViewFontSize = DefaultKey<CGFloat>("outlineViewFontSize")
    static let findResultViewFontSize = DefaultKey<CGFloat>("findResultViewFontSize")
    static let selectedMultipleReplacementSettingName = DefaultKey<String?>("selectedMultipleReplacementSettingName")
    static let beginCustomSurroundString = DefaultKey<String?>("beginCustomSurroundString")
    static let endCustomSurroundString = DefaultKey<String?>("endCustomSurroundString")
    static let unicodeHistory = DefaultKey<[String]>("unicodeHistory")
    
    // hidden settings
    static let headerFooterDateFormat = DefaultKey<String>("headerFooterDateFormat")
    static let headerFooterPathAbbreviatingWithTilde = DefaultKey<Bool>("headerFooterPathAbbreviatingWithTilde")
    static let autoCompletionDelay = DefaultKey<Double>("autoCompletionDelay")
    static let coloringRangeBufferLength = DefaultKey<Int>("coloringRangeBufferLength")
    static let largeFileAlertThreshold = DefaultKey<Int>("largeFileAlertThreshold")
    static let savesTextOrientation = DefaultKey<Bool>("savesTextOrientation")
    static let maximumRecentStyleCount = DefaultKey<Int>("maximumRecentStyleCount")
    static let maximumSelectionInstanceHighlightCount = DefaultKey<Int>("maximumSelectionInstanceHighlightCount")
    static let minimumLengthForNonContiguousLayout = DefaultKey<Int>("minimumLengthForNonContiguousLayout")
    
    static let lastVersion = DefaultKey<String?>("lastVersion")
    
}
