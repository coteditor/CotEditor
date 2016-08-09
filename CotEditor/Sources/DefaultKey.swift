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

import AppKit

let Defaults = UserDefaults.standard

class DefaultKeys: RawRepresentable, Hashable, CustomStringConvertible {
    
    let rawValue: String
    
    
    required init(rawValue: String) {
        
        self.rawValue = rawValue
    }
    
    
    init(_ key: String) {
        
        self.rawValue = key
    }
    
    
    var hashValue: Int {
        
        return self.rawValue.hashValue
    }
    
    
    var description: String {
        
         return self.rawValue
    }
    
}

class DefaultKey<T>: DefaultKeys { }



extension UserDefaults {
    
    subscript(key: DefaultKey<Bool>) -> Bool {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.bool(forKey: key.rawValue) }
    }
    
    subscript(key: DefaultKey<Int>) -> Int {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.integer(forKey: key.rawValue) }
    }
    
    subscript(key: DefaultKey<UInt>) -> UInt {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return UInt(self.integer(forKey: key.rawValue)) }
    }
    
    subscript(key: DefaultKey<Double>) -> Double {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.double(forKey: key.rawValue) }
    }
    
    subscript(key: DefaultKey<CGFloat>) -> CGFloat {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return CGFloat(self.double(forKey: key.rawValue)) }
    }
    
    subscript(key: DefaultKey<String>) -> String? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.string(forKey: key.rawValue) }
    }
    
    subscript(key: DefaultKey<[String]>) -> [String]? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.stringArray(forKey: key.rawValue) }
    }
    
    subscript(key: DefaultKey<[NSNumber]>) -> [NSNumber] {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.array(forKey: key.rawValue) as? [NSNumber] ?? [] }
    }
    
    subscript(key: DefaultKey<[AnyObject]>) -> [AnyObject]? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.array(forKey: key.rawValue) }
    }
    
}



extension DefaultKeys {
    
    // General
    static let createNewAtStartup = DefaultKey<Bool>("createNewAtStartup")
    static let reopenBlankWindow = DefaultKey<Bool>("reopenBlankWindow")
    static let enablesAutosaveInPlace = DefaultKey<Bool>("enablesAutosaveInPlace")
    static let trimsTrailingWhitespaceOnSave = DefaultKey<Bool>("trimsTrailingWhitespaceOnSave")
    static let documentConflictOption = DefaultKey<Int>("documentConflictOption")
    static let syncFindPboard = DefaultKey<Bool>("syncFindPboard")
    static let inlineContextualScriptMenu = DefaultKey<Bool>("inlineContextualScriptMenu")
    static let countLineEndingAsChar = DefaultKey<Bool>("countLineEndingAsChar")
    static let autoLinkDetection = DefaultKey<Bool>("autoLinkDetectionKey")
    static let checkSpellingAsType = DefaultKey<Bool>("checkSpellingAsType")
    static let highlightBraces = DefaultKey<Bool>("highlightBraces")
    static let highlightLtGt = DefaultKey<Bool>("highlightLtGt")
    static let checksUpdatesForBeta = DefaultKey<Bool>("checksUpdatesForBeta")
    
    // Window
    static let showNavigationBar = DefaultKey<Bool>("showNavigationBar")
    static let showDocumentInspector = DefaultKey<Bool>("showDocumentInspector")
    static let showStatusBar = DefaultKey<Bool>("showStatusArea")
    static let showLineNumbers = DefaultKey<Bool>("showLineNumbers")
    static let showPageGuide = DefaultKey<Bool>("showPageGuide")
    static let pageGuideColumn = DefaultKey<Int>("pageGuideColumn")
    static let showStatusBarLines = DefaultKey<Bool>("showStatusBarLines")
    static let showStatusBarChars = DefaultKey<Bool>("showStatusBarChars")
    static let showStatusBarLength = DefaultKey<Bool>("showStatusBarLength")
    static let showStatusBarWords = DefaultKey<Bool>("showStatusBarWords")
    static let showStatusBarLocation = DefaultKey<Bool>("showStatusBarLocation")
    static let showStatusBarLine = DefaultKey<Bool>("showStatusBarLine")
    static let showStatusBarColumn = DefaultKey<Bool>("showStatusBarColumn")
    static let showStatusBarEncoding = DefaultKey<Bool>("showStatusBarEncoding")
    static let showStatusBarLineEndings = DefaultKey<Bool>("showStatusBarLineEndings")
    static let showStatusBarFileSize = DefaultKey<Bool>("showStatusBarFileSize")
    static let splitViewVertical = DefaultKey<Bool>("splitViewVertical")
    static let windowWidth = DefaultKey<CGFloat>("windowWidth")
    static let windowHeight = DefaultKey<CGFloat>("windowHeight")
    static let windowAlpha = DefaultKey<CGFloat>("windowAlpha")
    
    // Appearance
    static let fontName = DefaultKey<String>("fontName")
    static let fontSize = DefaultKey<CGFloat>("fontSize")
    static let shouldAntialias = DefaultKey<Bool>("shouldAntialias")
    static let lineHeight = DefaultKey<CGFloat>("lineHeight")
    static let highlightCurrentLine = DefaultKey<Bool>("highlightCurrentLine")
    static let showInvisibles = DefaultKey<Bool>("showInvisibles")
    static let showInvisibleSpace = DefaultKey<Bool>("showInvisibleSpace")
    static let invisibleSpace = DefaultKey<Int>("invisibleSpace")
    static let showInvisibleTab = DefaultKey<Bool>("showInvisibleTab")
    static let invisibleTab = DefaultKey<Int>("invisibleTab")
    static let showInvisibleNewLine = DefaultKey<Bool>("showInvisibleNewLine")
    static let invisibleNewLine = DefaultKey<Int>("invisibleNewLine")
    static let showInvisibleFullwidthSpace = DefaultKey<Bool>("showInvisibleZenkakuSpace")
    static let invisibleFullwidthSpace = DefaultKey<Int>("invisibleZenkakuSpace")
    static let showOtherInvisibleChars = DefaultKey<Bool>("showOtherInvisibleChars")
    static let theme = DefaultKey<String>("defaultTheme")
    
    // Edit
    static let smartInsertAndDelete = DefaultKey<Bool>("smartInsertAndDelete")
    static let balancesBrackets = DefaultKey<Bool>("balancesBrackets")
    static let swapYenAndBackSlash = DefaultKey<Bool>("swapYenAndBackSlashKey")
    static let enableSmartQuotes = DefaultKey<Bool>("enableSmartQuotes")
    static let enableSmartDashes = DefaultKey<Bool>("enableSmartDashes")
    static let autoIndent = DefaultKey<Bool>("autoIndent")
    static let tabWidth = DefaultKey<Int>("tabWidth")
    static let autoExpandTab = DefaultKey<Bool>("autoExpandTab")
    static let detectsIndentStyle = DefaultKey<Bool>("detectsIndentStyle")
    static let appendsCommentSpacer = DefaultKey<Bool>("appendsCommentSpacer")
    static let commentsAtLineHead = DefaultKey<Bool>("commentsAtLineHead")
    static let wrapLines = DefaultKey<Bool>("wrapLines")
    static let enablesHangingIndent = DefaultKey<Bool>("enableHangingIndent")
    static let hangingIndentWidth = DefaultKey<Int>("hangingIndentWidth")
    static let completesDocumentWords = DefaultKey<Bool>("completesDocumentWords")
    static let completesSyntaxWords = DefaultKey<Bool>("completesSyntaxWords")
    static let completesStandartWords = DefaultKey<Bool>("completesStandardWords")
    static let autoComplete = DefaultKey<Bool>("autoComplete")
    
    // Format
    static let lineEndCharCode = DefaultKey<Int>("defaultLineEndCharCode")
    static let encodingList = DefaultKey<[NSNumber]>("encodingList")
    static let encodingInNew = DefaultKey<UInt>("encodingInNew")
    static let encodingInOpen = DefaultKey<UInt>("encodingInOpen")
    static let saveUTF8BOM = DefaultKey<Bool>("saveUTF8BOM")
    static let referToEncodingTag = DefaultKey<Bool>("referToEncodingTag")
    static let enableSyntaxHighlight = DefaultKey<Bool>("doSyntaxColoring")
    static let syntaxStyle = DefaultKey<String>("defaultColoringStyleName")
    
    // File Drop
    static let fileDropArray = DefaultKey<[AnyObject]>("fileDropArray")
    
    // Key Bindings
    static let insertCustomTextArray = DefaultKey<[String]>("insertCustomTextArray")
    
    // Print
    static let setPrintFont = DefaultKey<Int>("setPrintFont")
    static let printFontName = DefaultKey<String>("printFontName")
    static let printFontSize = DefaultKey<CGFloat>("printFontSize")
    static let printColorIndex = DefaultKey<Int>("printColorIndex")
    static let printTheme = DefaultKey<String>("printTheme")
    static let printLineNumIndex = DefaultKey<Int>("printLineNumIndex")
    static let printInvisibleCharIndex = DefaultKey<Int>("printInvisibleCharIndex")
    static let printHeader = DefaultKey<Bool>("printHeader")
    static let primaryHeaderContent = DefaultKey<Int>("headerOneStringIndex")
    static let primaryHeaderAlignment = DefaultKey<Int>("headerOneAlignIndex")
    static let secondaryHeaderContent = DefaultKey<Int>("headerTwoStringIndex")
    static let secondaryHeaderAlignment = DefaultKey<Int>("headerTwoAlignIndex")
    static let printFooter = DefaultKey<Bool>("printFooter")
    static let primaryFooterContent = DefaultKey<Int>("footerOneStringIndex")
    static let primaryFooterAlignment = DefaultKey<Int>("footerOneAlignIndex")
    static let secondaryFooterContent = DefaultKey<Int>("footerTwoStringIndex")
    static let secondaryFooterAlignment = DefaultKey<Int>("footerTwoAlignIndex")
    
    
    // find panel
    static let findHistory = DefaultKey<[String]>("findHistory")
    static let replaceHistory = DefaultKey<[String]>("replaceHistory")
    static let findUsesRegularExpression = DefaultKey<Bool>("findUsesRegularExpression")
    static let findIgnoresCase = DefaultKey<Bool>("findIgnoresCase")
    static let findInSelection = DefaultKey<Bool>("findInSelection")
    static let findIsWrap = DefaultKey<Bool>("findIsWrap")
    static let findNextAfterReplace = DefaultKey<Bool>("findsNextAfterReplace")
    static let findClosesIndicatorWhenDone = DefaultKey<Bool>("findClosesIndicatorWhenDone")
    
    static let findTextIsLiteralSearch = DefaultKey<Bool>("findTextIsLiteralSearch")
    static let findTextIgnoresDiacriticMarks = DefaultKey<Bool>("findTextIgnoresDiacriticMarks")
    static let findTextIgnoresWidth = DefaultKey<Bool>("findTextIgnoresWidth")
    static let findRegexIsSingleline = DefaultKey<Bool>("findRegexIsSingleline")
    static let findRegexIsMultiline = DefaultKey<Bool>("findRegexIsMultiline")
    static let findRegexUsesUnicodeBoundaries = DefaultKey<Bool>("regexUsesUnicodeBoundaries")
    
    // settings that are not in preferences
    static let colorCodeType = DefaultKey<Int>("colorCodeType")
    static let sidebarWidth = DefaultKey<CGFloat>("sidebarWidth")
    static let recentStyleNames = DefaultKey<[String]>("recentStyleNames")
    
    // hidden settings
    static let usesTextFontForInvisibles = DefaultKey<Bool>("usesTextFontForInvisibles")
    static let headerFooterDateFormat = DefaultKey<String>("headerFooterDateFormat")
    static let headerFooterPathAbbreviatingWithTilde = DefaultKey<Bool>("headerFooterPathAbbreviatingWithTilde")
    static let autoCompletionDelay = DefaultKey<Double>("autoCompletionDelay")
    static let infoUpdateInterval = DefaultKey<Double>("infoUpdateInterval")
    static let outlineMenuInterval = DefaultKey<Double>("outlineMenuInterval")
    static let showColoringIndicatorTextLength = DefaultKey<Int>("showColoringIndicatorTextLength")
    static let coloringRangeBufferLength = DefaultKey<Int>("coloringRangeBufferLength")
    static let largeFileAlertThreshold = DefaultKey<Int>("largeFileAlertThreshold")
    static let autosavingDelay = DefaultKey<Double>("autosavingDelay")
    static let savesTextOrientation = DefaultKey<Bool>("savesTextOrientation")
    static let layoutTextVertical = DefaultKey<Bool>("layoutTextVertical")
    static let enableSmartIndent = DefaultKey<Bool>("enableSmartIndent")
    static let maximumRecentStyleCount = DefaultKey<Int>("maximumRecentStyleCount")
    
    static let lastVersion = DefaultKey<String>("lastVersion")
    
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
