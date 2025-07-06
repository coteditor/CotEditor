# CotEditor Architecture Integration Guide for Note-Taking Features

**Document**: Architecture Analysis Results  
**Created**: 2025-01-07  
**Status**: Foundational analysis complete  

## Executive Summary

CotEditor provides an excellent foundation for note-taking features through its clean MVC architecture, robust text processing engine, and extensible design patterns. This analysis identifies specific integration points and implementation strategies for adding wiki-style linking, cross-file search, tag management, and note organization without disrupting the core editor experience.

## Core Architecture Overview

### Design Principles
- **Document-based architecture** - Native macOS app patterns
- **Protocol-oriented design** - Clean abstractions and extensibility  
- **Extension-based organization** - Features organized in logical Swift extensions
- **Async processing** - Background operations don't block UI
- **Notification-driven communication** - Loose coupling between components

### Key Components Hierarchy
```
DocumentWindowController
├── WindowContentViewController
│   ├── DocumentViewController (main coordinator)
│   │   ├── EditorViewController
│   │   │   └── EditorTextViewController
│   │   │       └── EditorTextView (core text editing)
│   │   ├── FileBrowserViewController (file organization)
│   │   └── InspectorViewController (metadata panel)
│   └── StatusBar / NavigationBar
├── Document (file management & persistence)
├── TextFinder (search & text operations)
└── LayoutManager (text rendering & syntax highlighting)
```

## Component Analysis & Integration Points

### 1. EditorTextView.swift - Text Input & Processing Engine

**Location**: `CotEditor/Sources/Document Window/Text View/EditorTextView.swift`

#### Primary Responsibilities
- Text input handling and validation
- Selection management and multi-cursor editing
- Bracket pair completion and smart typing features
- Menu item validation and action coordination
- Integration with completion system

#### Key Methods for Note-Taking Integration
```swift
// Text input processing - ideal for wiki link detection
override func insertText(_ string: Any, replacementRange: NSRange)

// Completion system - for note title suggestions  
override func completions(forPartialWordRange charRange: NSRange, 
                         indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]?

// Menu actions - for "Follow Link" commands
@IBAction func followWikiLink(_ sender: Any?)
@IBAction func showBacklinks(_ sender: Any?)
```

#### Integration Strategy: Wiki Link Detection
- **Hook Point**: `insertText` method for real-time `[[note]]` detection
- **Pattern**: Extend existing bracket pair logic in `NSTextView+BracePair.swift`
- **Implementation**: Create `EditorTextView+WikiLinks.swift` extension

```swift
// Example integration pattern
extension EditorTextView {
    func detectWikiLinkInsertion(at range: NSRange) {
        // Detect [[note]] pattern completion
        // Trigger syntax highlighting update
        // Store link reference for navigation
    }
}
```

### 2. Document.swift - File Management & Metadata

**Location**: `CotEditor/Sources/Document/Document.swift`

#### Primary Responsibilities  
- File reading, writing, and encoding management
- Document properties and metadata storage
- Syntax and theme management per document
- File monitoring and external change handling

#### Key Properties for Extension
```swift
// Existing pattern for document properties
@objc dynamic var isVerticalText: Bool
@objc dynamic var hasVerticalText: Bool

// Note-taking extensions following same pattern
@objc dynamic var noteMetadata: NoteMetadata?
@objc dynamic var noteBacklinks: Set<String>
@objc dynamic var noteTags: Set<String>
```

#### Integration Strategy: Note Metadata
- **Storage**: Extend existing extended attributes (xattr) system
- **Pattern**: Follow `isVerticalText` property management approach
- **Implementation**: Create `Document+NoteMetadata.swift` extension

```swift
extension Document {
    var noteID: UUID? {
        get { /* Read from extended attributes */ }
        set { /* Write to extended attributes */ }
    }
    
    var noteTitle: String? {
        get { /* Extract from document content or filename */ }
    }
    
    func updateBacklinks() {
        // Scan document for [[note]] references
        // Update document backlink relationships
    }
}
```

### 3. LayoutManager.swift - Text Rendering & Visual Effects

**Location**: `CotEditor/Sources/Document Window/Text View/LayoutManager.swift`

#### Primary Responsibilities
- Custom text rendering and visual effects
- Invisible character visualization  
- Syntax highlighting coordination
- Mouse interaction for visual elements

#### Key Methods for Visual Integration
```swift
// Main rendering pipeline
override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint)

// Mouse interaction
override func willEnableFirstResponder(_ textView: NSTextView) -> Bool

// Temporary attributes for styling
func setTemporaryAttributes(_ attrs: [NSAttributedString.Key : Any]?, 
                           forCharacterRange charRange: NSRange)
```

#### Integration Strategy: Wiki Link Visualization
- **Rendering**: Use `drawGlyphs` for custom link styling (underlines, colors)
- **Interaction**: Extend mouse handling for clickable links
- **Pattern**: Follow invisible character rendering approach in `NSLayoutManager+InvisibleDrawing.swift`

```swift
extension LayoutManager {
    func drawWikiLinks(in glyphRange: NSRange, at origin: CGPoint) {
        // Detect [[note]] ranges in text
        // Apply custom visual styling
        // Handle hover and click interactions
    }
}
```

### 4. TextFinder.swift - Search & Text Operations

**Location**: `CotEditor/Sources/Text Finder/TextFinder.swift`

#### Primary Responsibilities
- Text search across documents with regex support
- Find and replace operations with async processing
- Search result highlighting and navigation
- Integration with find panel UI

#### Key Architecture for Extension
```swift
// Action system for different search types
enum Action: CaseIterable {
    case findAll, replace, replaceAll
    // Add: findNoteReferences, searchBacklinks
}

// Async search infrastructure
func findAll(showsList: Bool, actionName: String?) async
```

#### Integration Strategy: Cross-File Search
- **Extension**: Add note-specific search actions to `Action` enum
- **Implementation**: Leverage existing async search infrastructure
- **Pattern**: Create `TextFinder+NoteSearch.swift` extension

```swift
extension TextFinder {
    func findNoteReferences(noteTitle: String) async -> [SearchResult] {
        // Search all documents for [[noteTitle]] references
        // Return structured results with file locations
    }
    
    func searchNotesContaining(text: String) async -> [NoteSearchResult] {
        // Cross-file content search specific to notes
        // Group results by note with metadata
    }
}
```

### 5. FileBrowserViewController.swift - File Organization

**Location**: `CotEditor/Sources/Document Window/File Browser/FileBrowserViewController.swift`

#### Primary Responsibilities
- File tree display and navigation
- File filtering and organization
- Context menu operations
- Integration with document opening

#### Key Methods for Enhancement
```swift
// File filtering system
func updateFilter() {
    // Extend to filter by note types, tags, relationships
}

// Context menu customization
override func menu(for event: NSEvent) -> NSMenu? {
    // Add note-specific operations
}
```

#### Integration Strategy: Note Organization
- **Filtering**: Extend filtering system for note types and relationships
- **Visual Enhancement**: Add note metadata to file list display
- **Operations**: Add note-specific context menu items

```swift
extension FileBrowserViewController {
    func configureNoteDisplay() {
        // Show note metadata in file list
        // Filter by note relationships
        // Add visual indicators for linked notes
    }
}
```

## Implementation Strategy & Phases

### Phase 1: Core Wiki Link Infrastructure (Tasks 003-004)
**Focus**: Basic `[[note]]` detection and rendering
- `EditorTextView+WikiLinks.swift` - Text input processing
- `LayoutManager+WikiLinks.swift` - Visual rendering
- `Document+NoteMetadata.swift` - Basic metadata storage

### Phase 2: Navigation & Search (Tasks 005-006)  
**Focus**: Cross-file functionality
- `TextFinder+NoteSearch.swift` - Cross-file search capabilities
- Wiki link click-to-navigate functionality
- Note title autocompletion system

### Phase 3: Backlink System (Task 007)
**Focus**: Relationship tracking
- Backlink indexing and storage
- UI panel for backlink display
- Real-time relationship updates

### Phase 4: Enhanced Organization (Tasks 008-009)
**Focus**: File management and tagging
- File browser enhancements for notes
- Tag management system integration
- Advanced filtering and organization

## Architecture Conventions to Follow

### 1. Extension Organization Pattern
```swift
// File naming convention
EditorTextView+WikiLinks.swift
Document+NoteMetadata.swift  
TextFinder+NoteSearch.swift
FileBrowserViewController+NoteDisplay.swift
```

### 2. Property Management Pattern
```swift
// Follow existing document property patterns
@objc dynamic var noteProperty: Type {
    get { /* implementation */ }
    set { /* implementation with change notification */ }
}
```

### 3. Menu Integration Pattern
```swift
// Standard validation and action pattern
@IBAction func noteAction(_ sender: Any?) {
    // Implementation
}

override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    // Validation logic following existing patterns
}
```

### 4. Async Processing Pattern
```swift
// Background operations using existing patterns
Task.detached(priority: .utility) {
    // Background processing
    await MainActor.run {
        // UI updates
    }
}
```

### 5. Notification Communication Pattern
```swift
// Use existing notification system for cross-component communication
extension Notification.Name {
    static let noteLinksDidUpdate = Notification.Name("noteLinksDidUpdate")
    static let noteMetadataDidChange = Notification.Name("noteMetadataDidChange")
}
```

## Integration Benefits

### Seamless User Experience
- Note-taking features feel native to CotEditor
- Existing keyboard shortcuts and workflows preserved
- Progressive enhancement of familiar functionality

### Technical Advantages
- Leverage mature text processing engine
- Robust file management and encoding support
- Excellent performance with large documents
- Native macOS integration (Spotlight, Quick Look, etc.)

### Maintainability
- Clean separation of note-taking logic in extensions
- Minimal impact on core CotEditor functionality
- Easy to test and debug individual components
- Clear upgrade path for future CotEditor updates

## Risk Mitigation

### Compatibility Preservation
- All new functionality in separate Swift extensions
- Existing CotEditor features remain unchanged
- Graceful degradation when note features disabled

### Performance Considerations
- Async processing for file operations
- Efficient regex patterns for link detection
- Lazy loading of note metadata and relationships
- Background indexing for cross-file search

### Code Quality Standards
- Follow existing SwiftLint and code style rules
- Comprehensive unit tests for new functionality
- Documentation following existing patterns
- Integration tests with real document workflows

---

This architecture analysis provides the foundation for implementing robust note-taking features while preserving CotEditor's excellent design principles and user experience. The identified integration points enable systematic development of wiki-style linking, cross-file search, and note organization capabilities.

**Next Steps**: Proceed to Task 003 (Wiki Link Detection) with clear understanding of integration patterns and extension points.