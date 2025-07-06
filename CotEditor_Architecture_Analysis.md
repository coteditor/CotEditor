# CotEditor Core Architecture Analysis for Note-Taking Integration

## Executive Summary

This analysis examines CotEditor's core architecture components to identify integration points for note-taking features, particularly wiki-style linking, cross-file search, and note organization. The codebase follows a clean MVC pattern with well-defined extension points that can be leveraged for adding note-taking capabilities.

## 1. EditorTextView.swift - Main Text Editing Component

### Class Structure and Inheritance
- **Base Class**: `NSTextView`
- **Protocols**: `CurrentLineHighlighting`, `MultiCursorEditing`, `TextFinderClient`
- **Key Features**: Multi-cursor editing, syntax highlighting integration, custom input handling

### Key Methods for Text Processing

#### Text Input and Modification
```swift
override func insertText(_ string: Any, replacementRange: NSRange)
override func insertNewline(_ sender: Any?)
override func deleteBackward(_ sender: Any?)
```

#### Text Selection and Navigation
```swift
override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting: Bool)
func wordRange(at location: Int) -> NSRange
override func selectionRange(forProposedRange: NSRange, granularity: NSSelectionGranularity) -> NSRange
```

### Extension Points for New Functionality

#### 1. Text Processing Pipeline
- **Integration Point**: `insertText(_:replacementRange:)` - Intercept wiki link syntax (`[[note]]`)
- **Pattern**: Use existing bracket balancing logic as template
- **Implementation**: Add wiki link detection to the symbol balancing system

#### 2. Custom Validation and Interaction
- **Integration Point**: `validateUserInterfaceItem(_:)` - Add wiki link navigation commands
- **Menu System**: Context menu in `menu(for:)` method can include "Follow Link" option

#### 3. Text Completion System
- **Integration Point**: Existing completion system in `completions(forPartialWordRange:indexOfSelectedItem:)`
- **Pattern**: Extend `completionWordTypes` enum to include `.notes`
- **Implementation**: Add note title completion when typing `[[`

### Syntax Highlighting Integration
- **Theme Support**: `var theme: Theme?` with `applyTheme()` method
- **Color System**: Uses temporary attributes via `LayoutManager`
- **Extension Pattern**: Wiki links can use similar highlighting as URLs

## 2. Document.swift - Document Model and Management

### Document Lifecycle and Properties

#### Core Properties
```swift
let textStorage = NSTextStorage()
let syntaxParser: SyntaxParser
private(set) var fileEncoding: FileEncoding
private(set) var lineEnding: LineEnding
```

#### Document State Management
- **Observable**: Uses `@Observable` and `@Published` properties
- **Persistence**: Custom `encodeRestorableState`/`restoreState` cycle
- **File Management**: Comprehensive file I/O with encoding detection

### Extension Points for Note Metadata

#### 1. Extended Attributes (xattr) System
```swift
private func additionalFileAttributes(for saveOperation: NSDocument.SaveOperationType) -> [String: any Sendable]
```
- **Current Usage**: Stores encoding, text orientation, line ending preferences
- **Extension Opportunity**: Add note metadata (tags, links, creation date)
- **Implementation**: Extend `FileExtendedAttributeName` enum

#### 2. Document Properties Extension
- **Pattern**: Follow existing `isVerticalText`, `isTransient` pattern
- **Add Properties**: 
  - `var noteId: UUID?` - Unique identifier for cross-references
  - `var noteTags: [String]` - Note categorization
  - `var backlinks: Set<URL>` - Reverse link tracking

#### 3. Custom File Type Support
```swift
override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String?
```
- **Extension Point**: Add `.note` file type support
- **Implementation**: Register custom UTType for note files

### Document Relationship Management
- **Current**: Single document focus
- **Extension Need**: Cross-document reference tracking
- **Implementation Strategy**: Use Document notifications for link updates

## 3. LayoutManager.swift - Text Layout and Syntax Highlighting

### Syntax Highlighting Architecture

#### Core Components
```swift
class LayoutManager: NSLayoutManager, InvisibleDrawing, ValidationIgnorable
var shownInvisibles: Set<Invisible>
var showsIndentGuides: Bool
```

#### Highlighting Pipeline
```swift
override func drawGlyphs(forGlyphRange: NSRange, at origin: NSPoint)
func layoutManager(_:shouldUseTemporaryAttributes:forDrawingToScreen:atCharacterIndex:effectiveRange:)
```

### Integration Points for Wiki Link Detection

#### 1. Custom Glyph Rendering
- **Method**: `drawGlyphs(forGlyphRange:at:)`
- **Pattern**: Similar to invisible character drawing
- **Implementation**: Add wiki link visual indicators (underlines, different colors)

#### 2. Text Attributes System
- **Current**: Uses temporary attributes for syntax highlighting
- **Extension**: Add `.wikiLink` attribute key
- **Method**: Integrate with `fillBackgroundRectArray` for link backgrounds

#### 3. Clickable Text Regions
- **Integration Point**: Mouse event handling in EditorTextView
- **Implementation**: Detect clicks on wiki link ranges, trigger navigation

### Visual Enhancement Patterns
- **Indent Guides**: Shows how to draw custom visual elements
- **Invisible Characters**: Pattern for special character visualization
- **Extension Strategy**: Wiki links can follow similar rendering patterns

## 4. TextFinder.swift - Search Functionality

### Search Architecture and Capabilities

#### Core Search Infrastructure
```swift
class TextFinder
enum Action: Int { case findAll, selectAll, highlight, etc. }
protocol TextFinderClient: AnyObject
```

#### Search Methods
```swift
private func find(forward: Bool, isIncremental: Bool = false) async throws
private func findAll(showsList: Bool, actionName: String) async
func prepareTextFind(presentsError: Bool = true) -> TextFind?
```

### Extension for Cross-File Search

#### 1. Multi-Document Search
- **Current Limitation**: Single document search
- **Extension Point**: `TextFinder.Action` enum can add `.findInAllNotes`
- **Implementation**: 
  - New action type for note-wide search
  - Extension of `findAll` to operate across document collection
  - Results aggregation from multiple documents

#### 2. Note-Specific Search Types
```swift
// Extend TextFinder.Action enum
case findBacklinks = 107
case findReferences = 108
case findUnlinkedMentions = 109
```

#### 3. Search Result Enhancement
```swift
struct TextFindAllResult {
    struct Match: Identifiable {
        var range: NSRange
        var documentURL: URL?  // Add document context
        var lineNumber: Int
    }
}
```

### Search Integration Strategy
- **Pattern**: Follow existing `findAll(showsList:actionName:)` pattern
- **UI Integration**: Extend find panel for note-specific searches
- **Performance**: Use existing async search infrastructure

## 5. FileBrowserViewController.swift - File Management

### File Organization Structure

#### Core Components
```swift
class FileBrowserViewController: NSViewController
let document: DirectoryDocument
@ViewLoading private(set) var outlineView: NSOutlineView
```

#### File Node Management
```swift
func didUpdateNode(at node: FileNode)
private func children(of node: FileNode?) -> [FileNode]?
private func filterNodes(_ nodes: [FileNode]) -> [FileNode]
```

### Enhancement for Note Organization

#### 1. Note-Specific Filtering
- **Current**: `showsHiddenFiles` filter
- **Extension**: Add note-specific filters
  - Filter by tags
  - Filter by link relationships
  - Filter by creation/modification date

#### 2. Visual Enhancements
```swift
func outlineView(_:viewFor:item:) -> NSView? {
    // Current: Basic file icon and name
    // Extension: Add note metadata visualization
    //   - Tag indicators
    //   - Link count badges
    //   - Note type icons
}
```

#### 3. Custom File Operations
```swift
// Extend existing actions
@IBAction func createNoteTemplate(_ sender: NSMenuItem)
@IBAction func linkToCurrentNote(_ sender: Any?)
@IBAction func showNoteReferences(_ sender: Any?)
```

### File Browser Integration Strategy
- **Tag Support**: Extend existing Finder tag system
- **Custom Context Menu**: Add note-specific operations
- **Visual Indicators**: Show note relationships and metadata

## Architecture Patterns and Conventions

### 1. Extension Pattern
CotEditor uses Swift extensions extensively for feature organization:
```
EditorTextView+LineProcessing.swift
EditorTextView+Commenting.swift
EditorTextView+TextReplacement.swift
```
**Apply to Note Features**:
```
EditorTextView+WikiLinks.swift
EditorTextView+NoteNavigation.swift
Document+NoteMetadata.swift
```

### 2. Protocol-Oriented Design
- **TextFinderClient**: Defines search integration interface
- **ValidationIgnorable**: Controls display update behavior
- **CurrentLineHighlighting**: Manages visual state
- **Pattern**: Create `WikiLinkHandling` protocol for note features

### 3. Action and Validation Pattern
```swift
@IBAction func actionMethod(_ sender: Any?)
func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool
```

### 4. Async Processing Pattern
- **Syntax Highlighting**: Uses `Task.detached` for background processing
- **File Operations**: Async/await for file system operations
- **Search**: Background search with progress indication
- **Apply to Notes**: Use same pattern for link resolution and indexing

### 5. Notification-Based Communication
```swift
static let didBecomeFirstResponderNotification = Notification.Name("TextViewDidBecomeFirstResponder")
static let didFindAllNotification = Notification.Name("didFindAllNotification")
```
**For Note Features**:
```swift
static let didUpdateNoteLinksNotification = Notification.Name("didUpdateNoteLinks")
static let didCreateNoteNotification = Notification.Name("didCreateNote")
```

## Integration Points Summary

### High-Priority Integration Points

1. **Wiki Link Detection**: 
   - `EditorTextView.insertText(_:replacementRange:)` for real-time parsing
   - `LayoutManager.drawGlyphs(forGlyphRange:at:)` for visual rendering

2. **Cross-File Search**:
   - `TextFinder.Action` enum extension
   - `TextFinder.findAll(showsList:actionName:)` enhancement

3. **Note Metadata**:
   - `Document.additionalFileAttributes(for:)` for persistence
   - Document property extensions for runtime state

4. **File Organization**:
   - `FileBrowserViewController` filtering and visualization
   - Context menu extensions for note operations

### Medium-Priority Integration Points

1. **Syntax Highlighting**: Extend syntax system for wiki link styling
2. **Auto-Completion**: Add note title completion to existing system
3. **Navigation**: Integrate with existing find/replace infrastructure

### Implementation Strategy

1. **Phase 1**: Core wiki link detection and rendering
2. **Phase 2**: Cross-file search and navigation
3. **Phase 3**: Advanced note organization and metadata
4. **Phase 4**: UI polish and performance optimization

The architecture provides excellent extension points while maintaining CotEditor's clean design principles. The existing patterns for text processing, file management, and search can be naturally extended to support comprehensive note-taking functionality.