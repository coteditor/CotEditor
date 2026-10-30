//
//  TextKeyBindingCommand.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

import AppKit
import Shortcut

// cf. https://support.apple.com/en-us/HT201236

enum TextKeyBindingCommand: CaseIterable, Hashable, Identifiable {
    
    case deleteWordBackward
    case deleteBackward
    case deleteForward
    case deleteToEndOfParagraph
    
    case scrollPageUp
    case scrollPageDown
    case scrollToBeginningOfDocument
    case scrollToEndOfDocument
    
    case moveToBeginningOfDocument
    case moveToEndOfDocument
    case moveToLeftEndOfLine
    case moveToRightEndOfLine
    case moveWordLeft
    case moveWordRight
    case moveToBeginningOfDocumentAndModifySelection
    case moveToEndOfDocumentAndModifySelection
    case moveToLeftEndOfLineAndModifySelection
    case moveToRightEndOfLineAndModifySelection
    case moveUpAndModifySelection
    case moveDownAndModifySelection
    case moveLeftAndModifySelection
    case moveRightAndModifySelection
    case moveParagraphBackwardAndModifySelection
    case moveParagraphForwardAndModifySelection
    case moveWordLeftAndModifySelection
    case moveWordRightAndModifySelection
    case moveToBeginningOfParagraph
    case moveToEndOfParagraph
    case moveForward
    case moveBackward
    case moveUp
    case moveDown
    
    case transpose
    
    var id: Self { self }
    
    
    /// The default shortcuts in their canonical key representations.
    var shortcuts: [Shortcut] {
        
        switch self {
            case .deleteWordBackward:
                [Shortcut(.delete, modifiers: .option)]
            case .deleteBackward:
                [Shortcut("h", modifiers: .control)]
            case .deleteForward:
                [Shortcut("d", modifiers: .control),
                 Shortcut(.deleteForward, modifiers: [])]
            case .deleteToEndOfParagraph:
                [Shortcut("k", modifiers: .control)]
            case .scrollPageUp:
                [Shortcut(.pageUp, modifiers: [])]
            case .scrollPageDown:
                [Shortcut(.pageDown, modifiers: [])]
            case .scrollToBeginningOfDocument:
                [Shortcut(.home, modifiers: [])]
            case .scrollToEndOfDocument:
                [Shortcut(.end, modifiers: [])]
            case .moveToBeginningOfDocument:
                [Shortcut(.upArrow, modifiers: .command)]
            case .moveToEndOfDocument:
                [Shortcut(.downArrow, modifiers: .command)]
            case .moveToLeftEndOfLine:
                [Shortcut(.leftArrow, modifiers: .command)]
            case .moveToRightEndOfLine:
                [Shortcut(.rightArrow, modifiers: .command)]
            case .moveWordLeft:
                [Shortcut(.leftArrow, modifiers: .option)]
            case .moveWordRight:
                [Shortcut(.rightArrow, modifiers: .option)]
            case .moveToBeginningOfDocumentAndModifySelection:
                [Shortcut(.upArrow, modifiers: [.shift, .command])]
            case .moveToEndOfDocumentAndModifySelection:
                [Shortcut(.downArrow, modifiers: [.shift, .command])]
            case .moveToLeftEndOfLineAndModifySelection:
                [Shortcut(.leftArrow, modifiers: [.shift, .command])]
            case .moveToRightEndOfLineAndModifySelection:
                [Shortcut(.rightArrow, modifiers: [.shift, .command])]
            case .moveUpAndModifySelection:
                [Shortcut(.upArrow, modifiers: .shift)]
            case .moveDownAndModifySelection:
                [Shortcut(.downArrow, modifiers: .shift)]
            case .moveLeftAndModifySelection:
                [Shortcut(.leftArrow, modifiers: .shift)]
            case .moveRightAndModifySelection:
                [Shortcut(.rightArrow, modifiers: .shift)]
            case .moveParagraphBackwardAndModifySelection:
                [Shortcut(.upArrow, modifiers: [.option, .shift])]
            case .moveParagraphForwardAndModifySelection:
                [Shortcut(.downArrow, modifiers: [.option, .shift])]
            case .moveWordLeftAndModifySelection:
                [Shortcut(.leftArrow, modifiers: [.option, .shift])]
            case .moveWordRightAndModifySelection:
                [Shortcut(.rightArrow, modifiers: [.option, .shift])]
            case .moveToBeginningOfParagraph:
                [Shortcut("a", modifiers: .control)]
            case .moveToEndOfParagraph:
                [Shortcut("e", modifiers: .control)]
            case .moveForward:
                [Shortcut("f", modifiers: .control)]
            case .moveBackward:
                [Shortcut("b", modifiers: .control)]
            case .moveUp:
                [Shortcut("p", modifiers: .control)]
            case .moveDown:
                [Shortcut("n", modifiers: .control)]
            case .transpose:
                [Shortcut("t", modifiers: .control)]
        }
    }
    
    
    /// The localized command name.
    var label: LocalizedStringResource {
        
        switch self {
            case .deleteWordBackward:
                .init("TextKeyBindingCommand.deleteWordBackward",
                      defaultValue: "Delete Word Backward", table: "TextKeyBindingCommand")
            case .deleteBackward:
                .init("TextKeyBindingCommand.deleteBackward",
                      defaultValue: "Delete Backward", table: "TextKeyBindingCommand")
            case .deleteForward:
                .init("TextKeyBindingCommand.deleteForward",
                      defaultValue: "Delete Forward", table: "TextKeyBindingCommand")
            case .deleteToEndOfParagraph:
                .init("TextKeyBindingCommand.deleteToEndOfParagraph",
                      defaultValue: "Delete to End of Paragraph", table: "TextKeyBindingCommand")
            case .scrollPageUp:
                .init("TextKeyBindingCommand.scrollPageUp",
                      defaultValue: "Scroll Page Up", table: "TextKeyBindingCommand")
            case .scrollPageDown:
                .init("TextKeyBindingCommand.scrollPageDown",
                      defaultValue: "Scroll Page Down", table: "TextKeyBindingCommand")
            case .scrollToBeginningOfDocument:
                .init("TextKeyBindingCommand.scrollToBeginningOfDocument",
                      defaultValue: "Scroll to Beginning of Document", table: "TextKeyBindingCommand")
            case .scrollToEndOfDocument:
                .init("TextKeyBindingCommand.scrollToEndOfDocument",
                      defaultValue: "Scroll to End of Document", table: "TextKeyBindingCommand")
            case .moveToBeginningOfDocument:
                .init("TextKeyBindingCommand.moveToBeginningOfDocument",
                      defaultValue: "Move to Beginning of Document", table: "TextKeyBindingCommand")
            case .moveToEndOfDocument:
                .init("TextKeyBindingCommand.moveToEndOfDocument",
                      defaultValue: "Move to End of Document", table: "TextKeyBindingCommand")
            case .moveToLeftEndOfLine:
                .init("TextKeyBindingCommand.moveToLeftEndOfLine",
                      defaultValue: "Move to Left End of Line", table: "TextKeyBindingCommand")
            case .moveToRightEndOfLine:
                .init("TextKeyBindingCommand.moveToRightEndOfLine",
                      defaultValue: "Move to Right End of Line", table: "TextKeyBindingCommand")
            case .moveWordLeft:
                .init("TextKeyBindingCommand.moveWordLeft",
                      defaultValue: "Move Word Left", table: "TextKeyBindingCommand")
            case .moveWordRight:
                .init("TextKeyBindingCommand.moveWordRight",
                      defaultValue: "Move Word Right", table: "TextKeyBindingCommand")
            case .moveToBeginningOfDocumentAndModifySelection:
                .init("TextKeyBindingCommand.moveToBeginningOfDocumentAndModifySelection",
                      defaultValue: "Move to Beginning of Document and Modify Selection", table: "TextKeyBindingCommand")
            case .moveToEndOfDocumentAndModifySelection:
                .init("TextKeyBindingCommand.moveToEndOfDocumentAndModifySelection",
                      defaultValue: "Move to End of Document and Modify Selection", table: "TextKeyBindingCommand")
            case .moveToLeftEndOfLineAndModifySelection:
                .init("TextKeyBindingCommand.moveToLeftEndOfLineAndModifySelection",
                      defaultValue: "Move to Left End of Line and Modify Selection", table: "TextKeyBindingCommand")
            case .moveToRightEndOfLineAndModifySelection:
                .init("TextKeyBindingCommand.moveToRightEndOfLineAndModifySelection",
                      defaultValue: "Move to Right End of Line and Modify Selection", table: "TextKeyBindingCommand")
            case .moveUpAndModifySelection:
                .init("TextKeyBindingCommand.moveUpAndModifySelection",
                      defaultValue: "Move Up and Modify Selection", table: "TextKeyBindingCommand")
            case .moveDownAndModifySelection:
                .init("TextKeyBindingCommand.moveDownAndModifySelection",
                      defaultValue: "Move Down and Modify Selection", table: "TextKeyBindingCommand")
            case .moveLeftAndModifySelection:
                .init("TextKeyBindingCommand.moveLeftAndModifySelection",
                      defaultValue: "Move Left and Modify Selection", table: "TextKeyBindingCommand")
            case .moveRightAndModifySelection:
                .init("TextKeyBindingCommand.moveRightAndModifySelection",
                      defaultValue: "Move Right and Modify Selection", table: "TextKeyBindingCommand")
            case .moveParagraphBackwardAndModifySelection:
                .init("TextKeyBindingCommand.moveParagraphBackwardAndModifySelection",
                      defaultValue: "Move Paragraph Backward and Modify Selection", table: "TextKeyBindingCommand")
            case .moveParagraphForwardAndModifySelection:
                .init("TextKeyBindingCommand.moveParagraphForwardAndModifySelection",
                      defaultValue: "Move Paragraph Forward and Modify Selection", table: "TextKeyBindingCommand")
            case .moveWordLeftAndModifySelection:
                .init("TextKeyBindingCommand.moveWordLeftAndModifySelection",
                      defaultValue: "Move Word Left and Modify Selection", table: "TextKeyBindingCommand")
            case .moveWordRightAndModifySelection:
                .init("TextKeyBindingCommand.moveWordRightAndModifySelection",
                      defaultValue: "Move Word Right and Modify Selection", table: "TextKeyBindingCommand")
            case .moveToBeginningOfParagraph:
                .init("TextKeyBindingCommand.moveToBeginningOfParagraph",
                      defaultValue: "Move to Beginning of Paragraph", table: "TextKeyBindingCommand")
            case .moveToEndOfParagraph:
                .init("TextKeyBindingCommand.moveToEndOfParagraph",
                      defaultValue: "Move to End of Paragraph", table: "TextKeyBindingCommand")
            case .moveForward:
                .init("TextKeyBindingCommand.moveForward",
                      defaultValue: "Move Forward", table: "TextKeyBindingCommand")
            case .moveBackward:
                .init("TextKeyBindingCommand.moveBackward",
                      defaultValue: "Move Backward", table: "TextKeyBindingCommand")
            case .moveUp:
                .init("TextKeyBindingCommand.moveUp",
                      defaultValue: "Move Up", table: "TextKeyBindingCommand")
            case .moveDown:
                .init("TextKeyBindingCommand.moveDown",
                      defaultValue: "Move Down", table: "TextKeyBindingCommand")
            case .transpose:
                .init("TextKeyBindingCommand.transpose",
                      defaultValue: "Transpose", table: "TextKeyBindingCommand")
        }
    }
    
    
    /// The standard text editing action for the command.
    var action: Selector {
        
        switch self {
            case .deleteWordBackward:
                #selector((any NSStandardKeyBindingResponding).deleteWordBackward)
            case .deleteBackward:
                #selector((any NSStandardKeyBindingResponding).deleteBackward)
            case .deleteForward:
                #selector((any NSStandardKeyBindingResponding).deleteForward)
            case .deleteToEndOfParagraph:
                #selector((any NSStandardKeyBindingResponding).deleteToEndOfParagraph)
            case .scrollPageUp:
                #selector((any NSStandardKeyBindingResponding).scrollPageUp)
            case .scrollPageDown:
                #selector((any NSStandardKeyBindingResponding).scrollPageDown)
            case .scrollToBeginningOfDocument:
                #selector((any NSStandardKeyBindingResponding).scrollToBeginningOfDocument)
            case .scrollToEndOfDocument:
                #selector((any NSStandardKeyBindingResponding).scrollToEndOfDocument)
            case .moveToBeginningOfDocument:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfDocument)
            case .moveToEndOfDocument:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfDocument)
            case .moveToLeftEndOfLine:
                #selector((any NSStandardKeyBindingResponding).moveToLeftEndOfLine)
            case .moveToRightEndOfLine:
                #selector((any NSStandardKeyBindingResponding).moveToRightEndOfLine)
            case .moveWordLeft:
                #selector((any NSStandardKeyBindingResponding).moveWordLeft)
            case .moveWordRight:
                #selector((any NSStandardKeyBindingResponding).moveWordRight)
            case .moveToBeginningOfDocumentAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfDocumentAndModifySelection)
            case .moveToEndOfDocumentAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfDocumentAndModifySelection)
            case .moveToLeftEndOfLineAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToLeftEndOfLineAndModifySelection)
            case .moveToRightEndOfLineAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToRightEndOfLineAndModifySelection)
            case .moveUpAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveUpAndModifySelection)
            case .moveDownAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveDownAndModifySelection)
            case .moveLeftAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveLeftAndModifySelection)
            case .moveRightAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveRightAndModifySelection)
            case .moveParagraphBackwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveParagraphBackwardAndModifySelection)
            case .moveParagraphForwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveParagraphForwardAndModifySelection)
            case .moveWordLeftAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordLeftAndModifySelection)
            case .moveWordRightAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordRightAndModifySelection)
            case .moveToBeginningOfParagraph:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfParagraph)
            case .moveToEndOfParagraph:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfParagraph)
            case .moveForward:
                #selector((any NSStandardKeyBindingResponding).moveForward)
            case .moveBackward:
                #selector((any NSStandardKeyBindingResponding).moveBackward)
            case .moveUp:
                #selector((any NSStandardKeyBindingResponding).moveUp)
            case .moveDown:
                #selector((any NSStandardKeyBindingResponding).moveDown)
            case .transpose:
                #selector((any NSStandardKeyBindingResponding).transpose)
        }
    }
    
    
    /// The standard key binding actions that are not offered for customization.
    private static let unusedActions: [Selector] = [
        #selector((any NSStandardKeyBindingResponding).insertContainerBreak),
        #selector((any NSStandardKeyBindingResponding).insertDoubleQuoteIgnoringSubstitution),
        
        #selector((any NSStandardKeyBindingResponding).moveRight),
        #selector((any NSStandardKeyBindingResponding).moveLeft),
        #selector((any NSStandardKeyBindingResponding).moveWordForward),
        #selector((any NSStandardKeyBindingResponding).moveWordBackward),
        #selector((any NSStandardKeyBindingResponding).moveToBeginningOfLine),
        #selector((any NSStandardKeyBindingResponding).moveToEndOfLine),
        #selector((any NSStandardKeyBindingResponding).pageDown),
        #selector((any NSStandardKeyBindingResponding).pageUp),
        #selector((any NSStandardKeyBindingResponding).centerSelectionInVisibleArea),
        
        #selector((any NSStandardKeyBindingResponding).moveBackwardAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveForwardAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveWordForwardAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveWordBackwardAndModifySelection),
        
        #selector((any NSStandardKeyBindingResponding).moveToBeginningOfLineAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveToEndOfLineAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveToBeginningOfParagraphAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveToEndOfParagraphAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).pageDownAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).pageUpAndModifySelection),
        
        #selector((any NSStandardKeyBindingResponding).scrollLineUp),
        #selector((any NSStandardKeyBindingResponding).scrollLineDown),
        
        #selector((any NSStandardKeyBindingResponding).transposeWords),
        
        #selector((any NSStandardKeyBindingResponding).deleteBackwardByDecomposingPreviousCharacter),
        #selector((any NSStandardKeyBindingResponding).deleteWordForward),
        #selector((any NSStandardKeyBindingResponding).deleteToBeginningOfLine),
        #selector((any NSStandardKeyBindingResponding).deleteToEndOfLine),
        #selector((any NSStandardKeyBindingResponding).deleteToBeginningOfParagraph),
        
        #selector((any NSStandardKeyBindingResponding).yank),
    ]
}
