//
//  DefaultKeys+Porting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-10-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

import Defaults

extension DefaultSettings {
    
    static let portableKeys: [DefaultKeys] = [
        // General
        .quitAlwaysKeepsWindows,
        .noDocumentOnLaunchOption,
        .enablesAutosaveInPlace,
        .documentConflictOption,
        .suppressesInconsistentLineEndingAlert,
        
        // Appearance
        .font,
        .shouldAntialias,
        .ligature,
        .monospacedFont,
        .monospacedShouldAntialias,
        .monospacedLigature,
        .lineHeight,
        .documentAppearance,
        .windowAlpha,
        .theme,
        .pinsThemeAppearance,
        
        // Window
        .windowTabbing,  // = Respect System Setting
        .showLineNumbers,
        .showLineNumberSeparator,
        .showInvisibles,
        .showInvisibleNewLine,
        .showInvisibleTab,
        .showInvisibleSpace,
        .showInvisibleWhitespaces,
        .showInvisibleControl,
        .showIndentGuides,
        .showPageGuide,
        .pageGuideColumn,
        .highlightCurrentLine,
        .wrapLines,
        .enablesHangingIndent,
        .hangingIndentWidth,
        .writingDirection,
        .overscrollRate,
        .showStatusBarLines,
        .showStatusBarChars,
        .showStatusBarWords,
        .showStatusBarLocation,
        .showStatusBarLine,
        .showStatusBarColumn,
        
        // Edit
        .autoExpandTab,
        .tabWidth,
        .detectsIndentStyle,
        .autoIndent,
        .indentWithTabKey,
        .autoTrimsTrailingWhitespace,
        .trimsWhitespaceOnlyLines,
        .insertsCommentDelimitersAfterIndent,
        .appendsCommentSpacer,
        .autoLinkDetection,
        .highlightBraces,
        .highlightSelectionInstance,
        .selectionInstanceHighlightDelay,
        
        // Mode
        .modes,
        
        // Format
        .lineEndCharCode,
        .encodingList,
        .encoding,
        .saveUTF8BOM,
        .referToEncodingTag,
        .syntax,
        
        // Snippet
        .fileDropArray,
    ]
}
