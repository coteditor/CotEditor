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

import AppKit.NSFont
import Defaults
import StringUtils
import Syntax

struct DefaultSettings {
    
    static var defaults: [DefaultKeys: Any?] {
        
        [
            // General
            .quitAlwaysKeepsWindows: true,
            .noDocumentOnLaunchOption: NoDocumentOnLaunchOption.untitledDocument.rawValue,
            .enablesAutosaveInPlace: true,
            .documentConflictOption: DocumentConflictOption.revert.rawValue,
            .suppressesInconsistentLineEndingAlert: false,
            .checksUpdatesForBeta: false,
            
            // Appearance
            .font: try? FontType.standard.systemFont().archivedData,
            .shouldAntialias: true,
            .ligature: true,
            .monospacedFont: try? FontType.monospaced.systemFont().archivedData,
            .monospacedShouldAntialias: true,
            .monospacedLigature: false,
            .lineHeight: 1.3,
            .documentAppearance: AppearanceMode.default.rawValue,
            .windowAlpha: 1.0,
            .theme: "Anura",
            .pinsThemeAppearance: false,
            
            // Window
            .windowTabbing: -1,  // = Respect System Setting
            .showLineNumbers: true,
            .showLineNumberSeparator: false,
            .showInvisibles: false,
            .showInvisibleNewLine: true,
            .showInvisibleTab: true,
            .showInvisibleSpace: false,
            .showInvisibleWhitespaces: true,
            .showInvisibleControl: true,
            .showIndentGuides: false,
            .showPageGuide: false,
            .pageGuideColumn: 80,
            .highlightCurrentLine: false,
            .wrapLines: true,
            .enablesHangingIndent: true,
            .hangingIndentWidth: 0,
            .writingDirection: 0,
            .overscrollRate: 0,
            .showStatusBarLines: true,
            .showStatusBarChars: true,
            .showStatusBarWords: false,
            .showStatusBarLocation: true,
            .showStatusBarLine: true,
            .showStatusBarColumn: false,
            
            // Edit
            .autoExpandTab: false,
            .tabWidth: 4,
            .detectsIndentStyle: true,
            .autoIndent: true,
            .indentWithTabKey: false,
            .autoTrimsTrailingWhitespace: false,
            .trimsWhitespaceOnlyLines: false,
            .insertsCommentDelimitersAfterIndent: true,
            .appendsCommentSpacer: true,
            .autoLinkDetection: false,
            .highlightBraces: true,
            .highlightSelectionInstance: true,
            .selectionInstanceHighlightDelay: 0.5,
            
            // Mode
            .modes: [:],
            
            // Format
            .lineEndCharCode: 0,
            .encodingList: DefaultSettings.encodings.map(UInt.init),
            .encoding: String.Encoding.utf8.rawValue,
            .saveUTF8BOM: false,
            .referToEncodingTag: true,
            .syntax: "Plain Text",
            
            // Snippets
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
            
            // Donation
            .donationBadgeType: BadgeType.mug.rawValue,
            
            // print
            .printFontSize: NSFont.systemFontSize,
            .printBackground: false,
            .printHeaderAndFooter: true,
            .primaryHeaderContent: PrintInfoType.filePath.rawValue,
            .primaryHeaderAlignment: AlignmentType.left.rawValue,
            .secondaryHeaderContent: PrintInfoType.printDate.rawValue,
            .secondaryHeaderAlignment: AlignmentType.right.rawValue,
            .primaryFooterContent: PrintInfoType.none.rawValue,
            .primaryFooterAlignment: AlignmentType.center.rawValue,
            .secondaryFooterContent: PrintInfoType.pageNumber.rawValue,
            .secondaryFooterAlignment: AlignmentType.center.rawValue,
            
            // text finder
            .findHistory: [String](),
            .replaceHistory: [String](),
            .findUsesRegularExpression: false,
            .findInSelection: false,
            .findIsWrap: true,
            .findMatchesFullWord: false,
            .findSearchesIncrementally: true,
            .findIgnoresCase: false,
            .findTextIsLiteralSearch: false,
            .findTextIgnoresDiacriticMarks: false,
            .findTextIgnoresWidth: false,
            .findRegexIsSingleline: false,
            .findRegexIsMultiline: true,
            .findRegexUsesUnicodeBoundaries: false,
            .findRegexUnescapesReplacementString: true,
            
            // Advanced Character Count
            .countUnit: CharacterCountOptions.CharacterUnit.graphemeCluster.rawValue,
            .countNormalizationForm: UnicodeNormalizationForm.nfc.rawValue,
            .countNormalizes: false,
            .countIgnoresNewlines: false,
            .countIgnoresWhitespaces: false,
            .countTreatsConsecutiveWhitespaceAsSingle: false,
            .countEncoding: String.Encoding.utf8.rawValue,
            
            // file browser
            .fileBrowserShowsHiddenFiles: false,
            
            // settings not in the Settings window
            .selectedInspectorPaneIndex: 0,
            .colorCodeType: 1,
            .recentSyntaxNames: [String](),
            .showStatusBar: true,
            .showNavigationBar: true,
            .splitViewVertical: false,
            .consoleFontSize: NSFont.smallSystemFontSize,
            .outlineViewFontSize: NSFont.smallSystemFontSize,
            .findResultViewFontSize: NSFont.smallSystemFontSize,
            
            // hidden settings
            .largeFileAlertThreshold: 200 * pow(1024, 2),  // 200 MB
            .savesTextOrientation: true,
            .maximumRecentSyntaxCount: 6,
        ]
    }
    
    
    private init() { }
}
