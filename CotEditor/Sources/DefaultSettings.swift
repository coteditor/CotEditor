//
//  DefaultSettings.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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

import AppKit.NSFont

struct DefaultSettings {
    
    static let defaults: [DefaultKeys: Any] = [
        .quitAlwaysKeepsWindows: true,
        .noDocumentOnLaunchBehavior: NoDocumentOnLaunchBehavior.untitledDocument.rawValue,
        .enablesAutosaveInPlace: true,
        .documentConflictOption: DocumentConflictOption.revert.rawValue,
        .countLineEndingAsChar: true,
        .autoLinkDetection: false,
        .checkSpellingAsType: false,
        .highlightBraces: true,
        .highlightLtGt: false,
        .highlightSelectionInstance: true,
        .selectionInstanceHighlightDelay: 0.5,
        .checksUpdatesForBeta: false,
        
        .windowTabbing: -1,  // = Respect System Setting
        .showNavigationBar: true,
        .showLineNumbers: true,
        .showPageGuide: false,
        .pageGuideColumn: 80,
        .writingDirection: 0,
        .overscrollRate: 0,
        .showStatusBarLines: true,
        .showStatusBarChars: true,
        .showStatusBarWords: false,
        .showStatusBarLocation: true,
        .showStatusBarLine: true,
        .showStatusBarColumn: false,
        .showStatusBarFileSize: true,
//        .windowWidth: 600.0,
//        .windowHeight: 620.0,
        .splitViewVertical: false,
        .windowAlpha: 1.0,
        
        .fontName: (NSFont.userFont(ofSize: 0) ?? NSFont.systemFont(ofSize: 0)).fontName,
        .fontSize: NSFont.systemFontSize,
        .shouldAntialias: true,
        .ligature: true,
        .lineHeight: 1.2,
        .highlightCurrentLine: false,
        .cursorType: CursorType.bar.rawValue,
        .showInvisibles: false,
        .showInvisibleNewLine: true,
        .showInvisibleTab: true,
        .showInvisibleSpace: false,
        .showInvisibleWhitespaces: true,
        .showInvisibleControl: false,
        .showIndentGuides: false,
        .documentAppearance: AppearanceMode.default.rawValue,
        .theme: "Anura",
        
        .smartInsertAndDelete: false,
        .balancesBrackets: false,
        .swapYenAndBackSlash: false,
        .enableSmartQuotes: false,
        .enableSmartDashes: false,
        .autoTrimsTrailingWhitespace: false,
        .trimsWhitespaceOnlyLines: false,
        .autoIndent: true,
        .tabWidth: 4,
        .autoExpandTab: false,
        .detectsIndentStyle: true,
        .indentWithTabKey: false,
        .wrapLines: true,
        .enablesHangingIndent: true,
        .hangingIndentWidth: 0,
        .appendsCommentSpacer: true,
        .commentsAtLineHead: true,
        .completesDocumentWords: true,
        .completesSyntaxWords: true,
        .completesStandartWords: false,
        .autoComplete: false,
        
        .lineEndCharCode: 0,
        .encodingList: DefaultSettings.encodings.map { UInt($0) },
        .encodingInNew: String.Encoding.utf8.rawValue,
        .saveUTF8BOM: false,
        .referToEncodingTag: true,
        .syntaxStyle: "Plain Text",
        
        .fileDropArray: [
            FileDropItem(format: "![<<<FILENAME-NOSUFFIX>>>](<<<RELATIVE-PATH>>>)",
                         extensions: ["jpg", "jpeg", "gif", "png"],
                         scope: "Markdown"),
            FileDropItem(format: "[<<<FILENAME-NOSUFFIX>>>](<<<RELATIVE-PATH>>>)",
                         scope: "Markdown"),
            FileDropItem(format: "<img src=\"<<<RELATIVE-PATH>>>\" alt=\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />",
                         extensions: ["jpg", "jpeg", "gif", "png"],
                         scope: "HTML"),
            FileDropItem(format: "<script type=\"text/javascript\" src=\"<<<RELATIVE-PATH>>>\"></script>",
                         extensions: ["js"],
                         scope: "HTML"),
            FileDropItem(format: "<a href=\"<<<RELATIVE-PATH>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\"></a>",
                         extensions: ["html", "htm", "php"],
                         scope: "HTML"),
            FileDropItem(format: "url(\"<<<RELATIVE-PATH>>>\")",
                         scope: "CSS"),
        ].map(\.dictionary),
        
        .insertCustomTextArray: ["", "", "", "", "", "", "", "", "", "", "",
                                 "", "", "", "", "", "", "", "", "", "",
                                 "", "", "", "", "", "", "", "", "", ""],
        
        .setPrintFont: false,
        .printFontName: (NSFont.userFont(ofSize: 0) ?? NSFont.systemFont(ofSize: 0)).fontName,
        .printFontSize: NSFont.systemFontSize,
        .printColorIndex: PrintColorMode.blackAndWhite.rawValue,
        .printBackground: false,
        .printLineNumIndex: PrintVisibilityMode.no.rawValue,
        .printInvisibleCharIndex: PrintVisibilityMode.no.rawValue,
        .printHeader: true,
        .primaryHeaderContent: PrintInfoType.filePath.rawValue,
        .primaryHeaderAlignment: AlignmentType.left.rawValue,
        .secondaryHeaderContent: PrintInfoType.printDate.rawValue,
        .secondaryHeaderAlignment: AlignmentType.right.rawValue,
        .printFooter: true,
        .primaryFooterContent: PrintInfoType.none.rawValue,
        .primaryFooterAlignment: AlignmentType.center.rawValue,
        .secondaryFooterContent: PrintInfoType.pageNumber.rawValue,
        .secondaryFooterAlignment: AlignmentType.center.rawValue,
        
        // ------ text finder ------
        .findHistory: [],
        .replaceHistory: [],
        .findUsesRegularExpression: false,
        .findInSelection: false,
        .findIsWrap: true,
        .findMatchesFullWord: false,
        .findNextAfterReplace: true,
        .findClosesIndicatorWhenDone: true,
        .findIgnoresCase: false,
        .findTextIsLiteralSearch: false,
        .findTextIgnoresDiacriticMarks: false,
        .findTextIgnoresWidth: false,
        .findRegexIsSingleline: false,
        .findRegexIsMultiline: true,
        .findRegexUsesUnicodeBoundaries: false,
        .findRegexUnescapesReplacementString: true,
        
        // ------ settings not in preferences window ------
        .pinsThemeAppearance: false,
        .colorCodeType: 1,
        .sidebarWidth: 220,
        .recentStyleNames: [],
        .showStatusBar: true,
        .selectedInspectorPaneIndex: 0,
        .outlineViewFontSize: NSFont.smallSystemFontSize,
        .findResultViewFontSize: NSFont.smallSystemFontSize,
        
        // ------ hidden settings ------
        .headerFooterDateFormat: "yyyy-MM-dd HH:mm",
        .headerFooterPathAbbreviatingWithTilde: true,
        .autoCompletionDelay: 0.25,
        .coloringRangeBufferLength: 5000,
        .largeFileAlertThreshold: 50 * pow(1024, 2),  // 50 MB
        .savesTextOrientation: true,
        .maximumRecentStyleCount: 6,
        .maximumSelectionInstanceHighlightCount: 100,
        .minimumLengthForNonContiguousLayout: 5_000_000,
    ]
    
    
    private init() { }
    
}
