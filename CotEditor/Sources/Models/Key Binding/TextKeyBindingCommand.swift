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

// cf. https://support.apple.com/102650

enum TextKeyBindingCommand: CaseIterable, Hashable, Identifiable {
    
    enum Category: CaseIterable {
        
        case movement
        case selection
        case deletion
        case editing
        case scrolling
        
        
        /// The commands in the category.
        var commands: [TextKeyBindingCommand] {
            
            TextKeyBindingCommand.allCases.filter { $0.category == self }
        }
    }
    
    
    case moveForward
    case moveBackward
    case moveUp
    case moveDown
    case moveWordForward
    case moveWordBackward
    case moveWordLeft
    case moveWordRight
    case moveToLeftEndOfLine
    case moveToRightEndOfLine
    case moveToBeginningOfParagraph
    case moveToEndOfParagraph
    case pageUp
    case pageDown
    case moveToBeginningOfDocument
    case moveToEndOfDocument
    
    case moveForwardAndModifySelection
    case moveBackwardAndModifySelection
    case moveLeftAndModifySelection
    case moveRightAndModifySelection
    case moveUpAndModifySelection
    case moveDownAndModifySelection
    case moveWordForwardAndModifySelection
    case moveWordBackwardAndModifySelection
    case moveWordLeftAndModifySelection
    case moveWordRightAndModifySelection
    case moveToLeftEndOfLineAndModifySelection
    case moveToRightEndOfLineAndModifySelection
    case moveToBeginningOfParagraphAndModifySelection
    case moveToEndOfParagraphAndModifySelection
    case moveParagraphBackwardAndModifySelection
    case moveParagraphForwardAndModifySelection
    case pageUpAndModifySelection
    case pageDownAndModifySelection
    case moveToBeginningOfDocumentAndModifySelection
    case moveToEndOfDocumentAndModifySelection
    
    case deleteWordBackward
    case deleteWordForward
    case deleteToBeginningOfLine
    case deleteToEndOfLine
    case deleteToBeginningOfParagraph
    case deleteToEndOfParagraph
    
    case transpose
    case yank
    
    case scrollLineUp
    case scrollLineDown
    case scrollPageUp
    case scrollPageDown
    case scrollToBeginningOfDocument
    case scrollToEndOfDocument
    
    var id: Self { self }
    
    
    /// The category to group the command.
    var category: Category {
        
        switch self {
            case .moveForward, .moveBackward, .moveUp, .moveDown,
                 .moveWordForward, .moveWordBackward, .moveWordLeft, .moveWordRight,
                 .moveToLeftEndOfLine, .moveToRightEndOfLine,
                 .moveToBeginningOfParagraph, .moveToEndOfParagraph,
                 .pageUp, .pageDown,
                 .moveToBeginningOfDocument, .moveToEndOfDocument:
                .movement
            case .moveForwardAndModifySelection, .moveBackwardAndModifySelection,
                 .moveLeftAndModifySelection, .moveRightAndModifySelection,
                 .moveUpAndModifySelection, .moveDownAndModifySelection,
                 .moveWordForwardAndModifySelection, .moveWordBackwardAndModifySelection,
                 .moveWordLeftAndModifySelection, .moveWordRightAndModifySelection,
                 .moveToLeftEndOfLineAndModifySelection, .moveToRightEndOfLineAndModifySelection,
                 .moveToBeginningOfParagraphAndModifySelection, .moveToEndOfParagraphAndModifySelection,
                 .moveParagraphBackwardAndModifySelection, .moveParagraphForwardAndModifySelection,
                 .pageUpAndModifySelection, .pageDownAndModifySelection,
                 .moveToBeginningOfDocumentAndModifySelection, .moveToEndOfDocumentAndModifySelection:
                .selection
            case .deleteWordBackward, .deleteWordForward,
                 .deleteToBeginningOfLine, .deleteToEndOfLine,
                 .deleteToBeginningOfParagraph, .deleteToEndOfParagraph:
                .deletion
            case .transpose, .yank:
                .editing
            case .scrollLineUp, .scrollLineDown,
                 .scrollPageUp, .scrollPageDown,
                 .scrollToBeginningOfDocument, .scrollToEndOfDocument:
                .scrolling
        }
    }
    
    
    /// The default shortcuts in their canonical key representations.
    var shortcuts: [Shortcut] {
        
        switch self {
            case .moveForward:
                [Shortcut("f", modifiers: .control)]
            case .moveBackward:
                [Shortcut("b", modifiers: .control)]
            case .moveUp:
                [Shortcut("p", modifiers: .control)]
            case .moveDown:
                [Shortcut("n", modifiers: .control)]
            case .moveWordForward:
                [Shortcut("f", modifiers: [.control, .option])]
            case .moveWordBackward:
                [Shortcut("b", modifiers: [.control, .option])]
            case .moveWordLeft:
                [Shortcut(.leftArrow, modifiers: .option)]
            case .moveWordRight:
                [Shortcut(.rightArrow, modifiers: .option)]
            case .moveToLeftEndOfLine:
                [Shortcut(.leftArrow, modifiers: .command),
                 Shortcut(.leftArrow, modifiers: .control)]
            case .moveToRightEndOfLine:
                [Shortcut(.rightArrow, modifiers: .command),
                 Shortcut(.rightArrow, modifiers: .control)]
            case .moveToBeginningOfParagraph:
                [Shortcut("a", modifiers: .control)]
            case .moveToEndOfParagraph:
                [Shortcut("e", modifiers: .control)]
            case .pageUp:
                [Shortcut(.pageUp, modifiers: .option)]
            case .pageDown:
                [Shortcut(.pageDown, modifiers: .option),
                 Shortcut("v", modifiers: .control)]
            case .moveToBeginningOfDocument:
                [Shortcut(.upArrow, modifiers: .command)]
            case .moveToEndOfDocument:
                [Shortcut(.downArrow, modifiers: .command)]
            case .moveForwardAndModifySelection:
                [Shortcut("f", modifiers: [.control, .shift])]
            case .moveBackwardAndModifySelection:
                [Shortcut("b", modifiers: [.control, .shift])]
            case .moveLeftAndModifySelection:
                [Shortcut(.leftArrow, modifiers: .shift)]
            case .moveRightAndModifySelection:
                [Shortcut(.rightArrow, modifiers: .shift)]
            case .moveUpAndModifySelection:
                [Shortcut(.upArrow, modifiers: .shift),
                 Shortcut("p", modifiers: [.control, .shift])]
            case .moveDownAndModifySelection:
                [Shortcut(.downArrow, modifiers: .shift),
                 Shortcut("n", modifiers: [.control, .shift])]
            case .moveWordForwardAndModifySelection:
                [Shortcut("f", modifiers: [.control, .option, .shift])]
            case .moveWordBackwardAndModifySelection:
                [Shortcut("b", modifiers: [.control, .option, .shift])]
            case .moveWordLeftAndModifySelection:
                [Shortcut(.leftArrow, modifiers: [.option, .shift])]
            case .moveWordRightAndModifySelection:
                [Shortcut(.rightArrow, modifiers: [.option, .shift])]
            case .moveToLeftEndOfLineAndModifySelection:
                [Shortcut(.leftArrow, modifiers: [.shift, .command]),
                 Shortcut(.leftArrow, modifiers: [.shift, .control])]
            case .moveToRightEndOfLineAndModifySelection:
                [Shortcut(.rightArrow, modifiers: [.shift, .command]),
                 Shortcut(.rightArrow, modifiers: [.shift, .control])]
            case .moveToBeginningOfParagraphAndModifySelection:
                [Shortcut("a", modifiers: [.control, .shift])]
            case .moveToEndOfParagraphAndModifySelection:
                [Shortcut("e", modifiers: [.control, .shift])]
            case .moveParagraphBackwardAndModifySelection:
                [Shortcut(.upArrow, modifiers: [.option, .shift])]
            case .moveParagraphForwardAndModifySelection:
                [Shortcut(.downArrow, modifiers: [.option, .shift])]
            case .pageUpAndModifySelection:
                [Shortcut(.pageUp, modifiers: .shift)]
            case .pageDownAndModifySelection:
                [Shortcut(.pageDown, modifiers: .shift),
                 Shortcut("v", modifiers: [.control, .shift])]
            case .moveToBeginningOfDocumentAndModifySelection:
                [Shortcut(.upArrow, modifiers: [.shift, .command]),
                 Shortcut(.home, modifiers: .shift)]
            case .moveToEndOfDocumentAndModifySelection:
                [Shortcut(.downArrow, modifiers: [.shift, .command]),
                 Shortcut(.end, modifiers: .shift)]
            case .deleteWordBackward:
                [Shortcut(.delete, modifiers: .option),
                 Shortcut(.delete, modifiers: [.option, .control])]
            case .deleteWordForward:
                [Shortcut(.deleteForward, modifiers: .option)]
            case .deleteToBeginningOfLine:
                [Shortcut(.delete, modifiers: .command)]
            case .deleteToEndOfLine:
                []
            case .deleteToBeginningOfParagraph:
                []
            case .deleteToEndOfParagraph:
                [Shortcut("k", modifiers: .control)]
            case .transpose:
                [Shortcut("t", modifiers: .control)]
            case .yank:
                [Shortcut("y", modifiers: .control)]
            case .scrollLineUp:
                []
            case .scrollLineDown:
                []
            case .scrollPageUp:
                [Shortcut(.pageUp, modifiers: []),
                 Shortcut(.upArrow, modifiers: .control)]
            case .scrollPageDown:
                [Shortcut(.pageDown, modifiers: []),
                 Shortcut(.downArrow, modifiers: .control)]
            case .scrollToBeginningOfDocument:
                [Shortcut(.home, modifiers: [])]
            case .scrollToEndOfDocument:
                [Shortcut(.end, modifiers: [])]
        }
    }
    
    
    /// The localized command name.
    var label: LocalizedStringResource {
        
        switch self {
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
            case .moveWordForward:
                .init("TextKeyBindingCommand.moveWordForward",
                      defaultValue: "Move Word Forward", table: "TextKeyBindingCommand")
            case .moveWordBackward:
                .init("TextKeyBindingCommand.moveWordBackward",
                      defaultValue: "Move Word Backward", table: "TextKeyBindingCommand")
            case .moveWordLeft:
                .init("TextKeyBindingCommand.moveWordLeft",
                      defaultValue: "Move Word Left", table: "TextKeyBindingCommand")
            case .moveWordRight:
                .init("TextKeyBindingCommand.moveWordRight",
                      defaultValue: "Move Word Right", table: "TextKeyBindingCommand")
            case .moveToLeftEndOfLine:
                .init("TextKeyBindingCommand.moveToLeftEndOfLine",
                      defaultValue: "Move to Left End of Line", table: "TextKeyBindingCommand")
            case .moveToRightEndOfLine:
                .init("TextKeyBindingCommand.moveToRightEndOfLine",
                      defaultValue: "Move to Right End of Line", table: "TextKeyBindingCommand")
            case .moveToBeginningOfParagraph:
                .init("TextKeyBindingCommand.moveToBeginningOfParagraph",
                      defaultValue: "Move to Beginning of Paragraph", table: "TextKeyBindingCommand")
            case .moveToEndOfParagraph:
                .init("TextKeyBindingCommand.moveToEndOfParagraph",
                      defaultValue: "Move to End of Paragraph", table: "TextKeyBindingCommand")
            case .pageUp:
                .init("TextKeyBindingCommand.pageUp",
                      defaultValue: "Move Page Up", table: "TextKeyBindingCommand")
            case .pageDown:
                .init("TextKeyBindingCommand.pageDown",
                      defaultValue: "Move Page Down", table: "TextKeyBindingCommand")
            case .moveToBeginningOfDocument:
                .init("TextKeyBindingCommand.moveToBeginningOfDocument",
                      defaultValue: "Move to Beginning of Document", table: "TextKeyBindingCommand")
            case .moveToEndOfDocument:
                .init("TextKeyBindingCommand.moveToEndOfDocument",
                      defaultValue: "Move to End of Document", table: "TextKeyBindingCommand")
            case .moveForwardAndModifySelection:
                .init("TextKeyBindingCommand.moveForwardAndModifySelection",
                      defaultValue: "Move Forward Extending Selection", table: "TextKeyBindingCommand")
            case .moveBackwardAndModifySelection:
                .init("TextKeyBindingCommand.moveBackwardAndModifySelection",
                      defaultValue: "Move Backward Extending Selection", table: "TextKeyBindingCommand")
            case .moveLeftAndModifySelection:
                .init("TextKeyBindingCommand.moveLeftAndModifySelection",
                      defaultValue: "Move Left Extending Selection", table: "TextKeyBindingCommand")
            case .moveRightAndModifySelection:
                .init("TextKeyBindingCommand.moveRightAndModifySelection",
                      defaultValue: "Move Right Extending Selection", table: "TextKeyBindingCommand")
            case .moveUpAndModifySelection:
                .init("TextKeyBindingCommand.moveUpAndModifySelection",
                      defaultValue: "Move Up Extending Selection", table: "TextKeyBindingCommand")
            case .moveDownAndModifySelection:
                .init("TextKeyBindingCommand.moveDownAndModifySelection",
                      defaultValue: "Move Down Extending Selection", table: "TextKeyBindingCommand")
            case .moveWordForwardAndModifySelection:
                .init("TextKeyBindingCommand.moveWordForwardAndModifySelection",
                      defaultValue: "Move Word Forward Extending Selection", table: "TextKeyBindingCommand")
            case .moveWordBackwardAndModifySelection:
                .init("TextKeyBindingCommand.moveWordBackwardAndModifySelection",
                      defaultValue: "Move Word Backward Extending Selection", table: "TextKeyBindingCommand")
            case .moveWordLeftAndModifySelection:
                .init("TextKeyBindingCommand.moveWordLeftAndModifySelection",
                      defaultValue: "Move Word Left Extending Selection", table: "TextKeyBindingCommand")
            case .moveWordRightAndModifySelection:
                .init("TextKeyBindingCommand.moveWordRightAndModifySelection",
                      defaultValue: "Move Word Right Extending Selection", table: "TextKeyBindingCommand")
            case .moveToLeftEndOfLineAndModifySelection:
                .init("TextKeyBindingCommand.moveToLeftEndOfLineAndModifySelection",
                      defaultValue: "Move to Left End of Line Extending Selection", table: "TextKeyBindingCommand")
            case .moveToRightEndOfLineAndModifySelection:
                .init("TextKeyBindingCommand.moveToRightEndOfLineAndModifySelection",
                      defaultValue: "Move to Right End of Line Extending Selection", table: "TextKeyBindingCommand")
            case .moveToBeginningOfParagraphAndModifySelection:
                .init("TextKeyBindingCommand.moveToBeginningOfParagraphAndModifySelection",
                      defaultValue: "Move to Beginning of Paragraph Extending Selection", table: "TextKeyBindingCommand")
            case .moveToEndOfParagraphAndModifySelection:
                .init("TextKeyBindingCommand.moveToEndOfParagraphAndModifySelection",
                      defaultValue: "Move to End of Paragraph Extending Selection", table: "TextKeyBindingCommand")
            case .moveParagraphBackwardAndModifySelection:
                .init("TextKeyBindingCommand.moveParagraphBackwardAndModifySelection",
                      defaultValue: "Move Paragraph Backward Extending Selection", table: "TextKeyBindingCommand")
            case .moveParagraphForwardAndModifySelection:
                .init("TextKeyBindingCommand.moveParagraphForwardAndModifySelection",
                      defaultValue: "Move Paragraph Forward Extending Selection", table: "TextKeyBindingCommand")
            case .pageUpAndModifySelection:
                .init("TextKeyBindingCommand.pageUpAndModifySelection",
                      defaultValue: "Move Page Up Extending Selection", table: "TextKeyBindingCommand")
            case .pageDownAndModifySelection:
                .init("TextKeyBindingCommand.pageDownAndModifySelection",
                      defaultValue: "Move Page Down Extending Selection", table: "TextKeyBindingCommand")
            case .moveToBeginningOfDocumentAndModifySelection:
                .init("TextKeyBindingCommand.moveToBeginningOfDocumentAndModifySelection",
                      defaultValue: "Move to Beginning of Document Extending Selection", table: "TextKeyBindingCommand")
            case .moveToEndOfDocumentAndModifySelection:
                .init("TextKeyBindingCommand.moveToEndOfDocumentAndModifySelection",
                      defaultValue: "Move to End of Document Extending Selection", table: "TextKeyBindingCommand")
            case .deleteWordBackward:
                .init("TextKeyBindingCommand.deleteWordBackward",
                      defaultValue: "Delete Word Backward", table: "TextKeyBindingCommand")
            case .deleteWordForward:
                .init("TextKeyBindingCommand.deleteWordForward",
                      defaultValue: "Delete Word Forward", table: "TextKeyBindingCommand")
            case .deleteToBeginningOfLine:
                .init("TextKeyBindingCommand.deleteToBeginningOfLine",
                      defaultValue: "Delete to Beginning of Line", table: "TextKeyBindingCommand")
            case .deleteToEndOfLine:
                .init("TextKeyBindingCommand.deleteToEndOfLine",
                      defaultValue: "Delete to End of Line", table: "TextKeyBindingCommand")
            case .deleteToBeginningOfParagraph:
                .init("TextKeyBindingCommand.deleteToBeginningOfParagraph",
                      defaultValue: "Delete to Beginning of Paragraph", table: "TextKeyBindingCommand")
            case .deleteToEndOfParagraph:
                .init("TextKeyBindingCommand.deleteToEndOfParagraph",
                      defaultValue: "Delete to End of Paragraph", table: "TextKeyBindingCommand")
            case .transpose:
                .init("TextKeyBindingCommand.transpose",
                      defaultValue: "Transpose", table: "TextKeyBindingCommand")
            case .yank:
                .init("TextKeyBindingCommand.yank",
                      defaultValue: "Yank", table: "TextKeyBindingCommand")
            case .scrollLineUp:
                .init("TextKeyBindingCommand.scrollLineUp",
                      defaultValue: "Scroll Line Up", table: "TextKeyBindingCommand")
            case .scrollLineDown:
                .init("TextKeyBindingCommand.scrollLineDown",
                      defaultValue: "Scroll Line Down", table: "TextKeyBindingCommand")
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
        }
    }
    
    
    /// The standard text editing action for the command.
    var action: Selector {
        
        switch self {
            case .moveForward:
                #selector((any NSStandardKeyBindingResponding).moveForward)
            case .moveBackward:
                #selector((any NSStandardKeyBindingResponding).moveBackward)
            case .moveUp:
                #selector((any NSStandardKeyBindingResponding).moveUp)
            case .moveDown:
                #selector((any NSStandardKeyBindingResponding).moveDown)
            case .moveWordForward:
                #selector((any NSStandardKeyBindingResponding).moveWordForward)
            case .moveWordBackward:
                #selector((any NSStandardKeyBindingResponding).moveWordBackward)
            case .moveWordLeft:
                #selector((any NSStandardKeyBindingResponding).moveWordLeft)
            case .moveWordRight:
                #selector((any NSStandardKeyBindingResponding).moveWordRight)
            case .moveToLeftEndOfLine:
                #selector((any NSStandardKeyBindingResponding).moveToLeftEndOfLine)
            case .moveToRightEndOfLine:
                #selector((any NSStandardKeyBindingResponding).moveToRightEndOfLine)
            case .moveToBeginningOfParagraph:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfParagraph)
            case .moveToEndOfParagraph:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfParagraph)
            case .pageUp:
                #selector((any NSStandardKeyBindingResponding).pageUp)
            case .pageDown:
                #selector((any NSStandardKeyBindingResponding).pageDown)
            case .moveToBeginningOfDocument:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfDocument)
            case .moveToEndOfDocument:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfDocument)
            case .moveForwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveForwardAndModifySelection)
            case .moveBackwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveBackwardAndModifySelection)
            case .moveLeftAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveLeftAndModifySelection)
            case .moveRightAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveRightAndModifySelection)
            case .moveUpAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveUpAndModifySelection)
            case .moveDownAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveDownAndModifySelection)
            case .moveWordForwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordForwardAndModifySelection)
            case .moveWordBackwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordBackwardAndModifySelection)
            case .moveWordLeftAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordLeftAndModifySelection)
            case .moveWordRightAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveWordRightAndModifySelection)
            case .moveToLeftEndOfLineAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToLeftEndOfLineAndModifySelection)
            case .moveToRightEndOfLineAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToRightEndOfLineAndModifySelection)
            case .moveToBeginningOfParagraphAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfParagraphAndModifySelection)
            case .moveToEndOfParagraphAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfParagraphAndModifySelection)
            case .moveParagraphBackwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveParagraphBackwardAndModifySelection)
            case .moveParagraphForwardAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveParagraphForwardAndModifySelection)
            case .pageUpAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).pageUpAndModifySelection)
            case .pageDownAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).pageDownAndModifySelection)
            case .moveToBeginningOfDocumentAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToBeginningOfDocumentAndModifySelection)
            case .moveToEndOfDocumentAndModifySelection:
                #selector((any NSStandardKeyBindingResponding).moveToEndOfDocumentAndModifySelection)
            case .deleteWordBackward:
                #selector((any NSStandardKeyBindingResponding).deleteWordBackward)
            case .deleteWordForward:
                #selector((any NSStandardKeyBindingResponding).deleteWordForward)
            case .deleteToBeginningOfLine:
                #selector((any NSStandardKeyBindingResponding).deleteToBeginningOfLine)
            case .deleteToEndOfLine:
                #selector((any NSStandardKeyBindingResponding).deleteToEndOfLine)
            case .deleteToBeginningOfParagraph:
                #selector((any NSStandardKeyBindingResponding).deleteToBeginningOfParagraph)
            case .deleteToEndOfParagraph:
                #selector((any NSStandardKeyBindingResponding).deleteToEndOfParagraph)
            case .transpose:
                #selector((any NSStandardKeyBindingResponding).transpose)
            case .yank:
                #selector((any NSStandardKeyBindingResponding).yank)
            case .scrollLineUp:
                #selector((any NSStandardKeyBindingResponding).scrollLineUp)
            case .scrollLineDown:
                #selector((any NSStandardKeyBindingResponding).scrollLineDown)
            case .scrollPageUp:
                #selector((any NSStandardKeyBindingResponding).scrollPageUp)
            case .scrollPageDown:
                #selector((any NSStandardKeyBindingResponding).scrollPageDown)
            case .scrollToBeginningOfDocument:
                #selector((any NSStandardKeyBindingResponding).scrollToBeginningOfDocument)
            case .scrollToEndOfDocument:
                #selector((any NSStandardKeyBindingResponding).scrollToEndOfDocument)
        }
    }
    
    
    /// The standard key binding actions that are not offered for customization.
    private static let unusedActions: [Selector] = [
        #selector((any NSStandardKeyBindingResponding).insertContainerBreak),
        #selector((any NSStandardKeyBindingResponding).insertDoubleQuoteIgnoringSubstitution),
        
        #selector((any NSStandardKeyBindingResponding).moveRight),
        #selector((any NSStandardKeyBindingResponding).moveLeft),
        #selector((any NSStandardKeyBindingResponding).moveToBeginningOfLine),
        #selector((any NSStandardKeyBindingResponding).moveToEndOfLine),
        #selector((any NSStandardKeyBindingResponding).centerSelectionInVisibleArea),
        
        #selector((any NSStandardKeyBindingResponding).moveToBeginningOfLineAndModifySelection),
        #selector((any NSStandardKeyBindingResponding).moveToEndOfLineAndModifySelection),
        
        #selector((any NSStandardKeyBindingResponding).transposeWords),
        
        #selector((any NSStandardKeyBindingResponding).deleteBackward),
        #selector((any NSStandardKeyBindingResponding).deleteForward),
        #selector((any NSStandardKeyBindingResponding).deleteBackwardByDecomposingPreviousCharacter),
    ]
}


extension TextKeyBindingCommand.Category {
    
    /// The localized category name.
    var label: LocalizedStringResource {
        
        switch self {
            case .movement:
                .init("TextKeyBindingCommand.Category.movement",
                      defaultValue: "Movement", table: "TextKeyBindingCommand")
            case .selection:
                .init("TextKeyBindingCommand.Category.selection",
                      defaultValue: "Selection", table: "TextKeyBindingCommand")
            case .deletion:
                .init("TextKeyBindingCommand.Category.deletion",
                      defaultValue: "Deletion", table: "TextKeyBindingCommand")
            case .editing:
                .init("TextKeyBindingCommand.Category.editing",
                      defaultValue: "Editing", table: "TextKeyBindingCommand")
            case .scrolling:
                .init("TextKeyBindingCommand.Category.scrolling",
                      defaultValue: "Scrolling", table: "TextKeyBindingCommand")
        }
    }
}
