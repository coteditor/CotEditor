
Change Log
==========================

3.7.0-rc.3 (releasenotes)
--------------------------

### Improvements

- Delete sequential paces character by character when they are not located at the beginning of a line even if “Expand tabs to spaces” option is enabled.
- [beta] Support right-to-left and bidi text by moving multiple cursors.


### Fixes

- Fix an issue where lines did not wrap correctly with vertical text orientation.
- Fix an issue where “Replace All” could fail when the text to find is a combining character such as a diacritical mark.
- Fix an issue where the line wrap width of a split view could be set shorter than the actual view if scroller bars are set to be always visible.
- Fix an issue where the year in the print header or console prompt was displayed wrongly in specific days (Thanks to Frédéric Blondiau!).
- [beta] Fix detailed behaviors of `^⇧↑` and `^⇧↓`  shortcuts.
- [beta] Fix an issue the application crashed by performing `^⇧↑` or `^⇧↓` shortcut when RTL text is selected.
- [rc.2] Fix background color when editor was scrolled over a boundary.



3.7.0-rc.2 (333)
--------------------------

### Improvements

- [beta] Disable “Change Opacity” action while fullscreen mode.
- [beta] Move the position of the opacity control popover.
- [beta] Update help contents.
- [trivial] Improve toolbar color.
- [dev] Update Differ framework to 1.3.0.


### Fixes

- Fix an issue where closed windows remained on the memory.
- Address an issue where selected ranges were set wrongly after updating document due to an external modification.



3.7.0-rc (331)
--------------------------

### New Features

- Add “Surround Selection With” > “Square Brackets” menu item.


### Improvements

- Remember the last used custom characters for “Surround Selection With” > “Custom” action.
- [beta] Keep insertion points afeter cut.
- [beta] Localize newly added strings.



3.7.0-beta.5 (329)
--------------------------

### New Features

- Add “Opacity” toolbar item to change editor's opacity.


### Improvements

- Restore more UI state on window restoration.


### Fixes

- Fix an issue where the last syntax style was not applied when an unsaved document was restored from the last session.
- Fix an issue where auto-completion could cancel suddenly under a restricted condition.
- Fix a possible issue where word counting could be stuck.
- [beta] Fix multi-cursor behavior with `→` and `←` when something is selected.



3.7.0-beta.4 (327)
--------------------------

### Improvements

- [beta] Support snippet insertion in multi-cursor editing.
- [beta] Replace `^⇧↑` and `^⇧↓` shortcuts with `^⇧→` and `^⇧←` correspondingly when the text orientation is vertical.
- [beta] Fix and improve the behavior of `^⇧↑` and `^⇧↓` shortcuts.
- [beta] Merge changes in CotEditor 3.6.12.


### Fixes

- [beta] Fix selection after commenting-out.
- [beta] Suppress blinking Edit menu when performing `^⇧↑` or `^⇧↓` shortcut.
- [beta] Fix an issue where auto-inserted tab did not expand to spaces on auto indent level adjustment.



3.7.0-beta.3 (325)
--------------------------

### Improvements

- [beta] Support commenting-out/uncommenting in multi-cursor editing.
- [beta] Support `^T` and `fn+delete` (`^D`) shortcut in multi-cursor editing.


### Fixes

- [beta] Fix an issue where multiple cursors disappeared after (auto-)saving with “trim trailing whitespace on save” option.
- [beta] Fix an issue where the first cursor could disappear after some specific text editing.
- [beta] Fix an issue where auto-inserted tab did not expand to spaces on auto indent level adjustment.
- [beta] Fix multi-cursor behavior of deleting to the beginning of the visual line by `⌘⌫`.
- [beta] Fix multi-cursor movement when encountering a surrogate pair.
- [beta] Fix an issue where a selected range and an insertion point could overlap.
- [beta] Fix an issue where the application could rarely crash after moving cursors.



3.7.0-beta.2 (323)
--------------------------

### Improvements

- [beta] Exit muti-cursor mode by using `esc` key.
- [beta] Add `^⇧↑` and `^⇧↓` shortcuts to add an insertion point above/below.


### Fixes

- [beta] Fix a crash when moving multiple cursors with arrow keys.
- [beta] Fix the width of insertion points.
- [beta] Fix cursor behavior when moving multi-cursors among words with shortcut keys.



3.7.0-beta (321)
--------------------------

### New Features

- Multi-cursor editing.



3.6.12 (311)
--------------------------

### Improvements

- Update syntax style for “SVG”.
- Update `cot` command-line tool:
    - Fix an issue where stack trace displayed when using `--wait` option with some clients other than Terminal.app.
    - Fix an issue where `--column` could misplace the insertion point when a negative number was given.


### Fixes

- Fix an issue where the snippet insertion did not work.
- Fix an issue where theme change did not apply to opened documents under specific conditions.
- Fix an issue where user theme was not applied when windows restored on macOS 10.12.
- Fix an issue on macOS 10.12 where the initial theme editor was empty when the preferences window switches to Appearance pane.
- Improve stability.



3.6.11 (309)
--------------------------

### Improvements

- Live update selection highlight in line number views.


### Fixes

- Fix an issue where the application could crash when deleting the last character in a large document.



3.6.10 (307)
--------------------------

### New Features

- Add syntax style for “Kotlin”.


### Improvements

- Change counting method of the cursor location and column to 1-based (formerly 0-based).
- Optimize syntax highlight application so that the time displaying the rainbow cursor reduces significantly with a large document.
- Make editing multiple replacement definitions undoable.
- Syntax highlight regular expression patterns in the syntax style editor, multiple replacement definitions, and the custom sort dialog.
- Move focus to the editor when lines are selected by clicking line numbers.
- Apply update of “Line numbers”, “Page guide” and “invisible characters” visibility options in the preferences immediately to opened documents.
- Suppress the dialog asking if you want to keep the document when an unsaved empty document is about to close, and silently discard the auto-saved backup file.
- Change the label of the option “Count each line ending as one character” in General pane to “Ignore line endings when counting characters” (the value reversed).
- Enable the “Share” button in toolbar also in the Text Only mode.
- Display also mapping conflicts of interpreters in the syntax style file mapping conflict dialog.
- Make composition views for the Share feature document-modal also in macOS 10.12.
- Disable “Hide Toolbar” command for the preferences window.
- Improve general performance.
- Update German localization (Thanks to J-rg!).
- Update `cot` command-line tool:
    - Accept a negative value for `--column` option to count from the end of the line.
    - Change `--column` count from 0-based to 1-based.
    - Improve error message when failed.
    - Fix an issue where the last empty line was ignored when specifying the cursor position with `--line` option.
- [trivial] Make the minimum width of outline inspector wider.


### Fixes

- Fix an issue where the final number of the replacement in the progress dialog was occasionally underrated.
- Fix an issue where the cursor could not be set at the end of the document via AppleScript or `cot` command.
- Fix an issue where syntax highlight was not updated in specific condition when deleted.
- Fix an issue where line number views did not update when the editor is scrolled via script.
- Fix the preferences pane switching animation under macOS 10.13 and earlier.
- [trivial] Fix a potential issue where last empty line number could be drawn at the first line position under specific conditions.
- [trivial] Fix an issue where editor occasionally scrolled unintendedly when an arrow key is pressed.



3.6.9 (305)
--------------------------

### Improvements

- Optimize syntax highlighting.


### Fixes

- Fix an issue where the application crashed when splitting editors.
- Fix an issue where a part of line numbers disappeared when Japanese text is being inputted.
- Fix an issue where the context menu did not open under macOS 10.13 and earlier if the user has scripts.
- [tirivial] Fix font style of“Italic” button in the outline menu editor.



3.6.8 (303)
--------------------------

### New Features

- Add syntax style for “TOML”.


### Improvements

- Improve the performance of text replacement significantly.
- Improve the line number view fundamentally so that all unwanted behaviors after macOS Mojave disappear.
- Select the setting selected in the last session when opening the Multiple Replacement window.
- Enable the noncontiguous layout only with large documents.
    - This change may improve the editor's drawing and scrolling behaviors.
- Improve general performance and stability.
- [dev] Stop LineNumberView inheriting NSRulerView.


### Fixes

- Fix the cursor location by changing the selection with shortcut `⌘←`.
- Fix an issue where the rainbow cursor could appear when cancelling syntax highlight with a large document multiple times.



3.6.7 (301)
--------------------------

### Improvements

- Change not to highlight occurrences of the selection when there are more than 100.
- Update validation pane in the syntax style editor:
    - Now, validation is performed automatically when the pane switched to “Validation”.
- [trivial] Remove “Restore Defaults” button in the syntax style editor if the style has no defaults.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix an issue where `cot` command failed to open paths or stdin containing backslash character.
- Fix an issue on CotEditor 3.6.5 where right-click no longer opens the context menu under macOS 10.13 and earlier.
- Fix an issue where the thickness of the line numbers view did not grow enough with a large number of lines.
- Fix an issue where the syntax style validator ignored unbalanced block comment delimiters that should be an error.
- Fix the preferences pane switching animation under macOS 10.13 and earlier.
- Fix possible crashes.
- Fix minor issues in the syntax style editor.
- Fix some localized strings.



3.6.6 (299)
--------------------------

### Fixes

- Fix an issue on CotEditor 3.6.5 where the syntax highlight did not update while typing.
- Fix an issue where preferences panes could not change under macOS 10.12.
- Add missing localizations.



3.6.5 (297)
--------------------------

### New Features

- New option for cursor style (Customize the behavior in Appearances preference pane).


### Improvements

- Avoid drawing variant sequence as invisible control characters.
- Make line number view opaque if lines are unwrapped on macOS 10.14 to avoid drawing the editor's text over the line numbers.
- Revoke the line counting behavior change with VoiceOver in CotEditor 3.6.3.
- [tirivial] Draw vertical tabs as general invisible control characters.


### Fixes

- Fix an issue where the editor area could still tuck under the line number view.
- Fix an issue where the line number of the last empty line disappeared when lines are not wrapped and scrolled.
- [trivial] Fix a weird view expansion on the first transition to the General preferences pane.
- [trivial] Fix an issue on Mojave where the text selection highlight could remain between lines.



3.6.4 (294)
--------------------------

### New Features

- Add a command “Select Word” (`⌘D`) to Edit menu.


### Improvements

- [trivial] Display default setting values as the input field's placeholder for instance highlight delay option when empty.


### Fixes

- Fix an issue where editor area could be tuck under the line number view.
- Fix an issue where changing the selection by shortcut `⇧→` just after shortcut `⌘⇧←` expanded the selection to a wrong direction.
- Fix an issue where page guide did not update when font changed.



3.6.3 (292)
--------------------------

### Improvements

- Assign `⌘⇧[` shortcut to “Show Next Tab” command instead of “Surround Selection with Brackets” command.
- Treat a logical line, which is delimited by line ending characters, as one line in VoiceOver, instead of a visual (wrapped) line.
    - Thereby, users can now also know the current line number by pressing VoiceOver shortcut VO+F3.
- Improve the accessibility of user interface elements with VoiceOver.
- Avoid performing custom sort with an invalid parameter.
- Display default setting values as the input field's placeholder in preferences window when empty.
- [trivial] Move the focus to the target input field when the clear button in the find panel was pressed.


### Fixes

- Fix an issue where selected inspector pane was not stored.
- Fix an issue where initial display area shifted unwantedly if line numbers are displayed lines are unwrapped.
- Fix an issue where script name was not displayed in Console.
- Fix an issue where the writing direction (RtL) was not delivered to printing.
- Fix layout in some localized environment.



3.6.2 (290)
--------------------------

### New Features

- Let the input fields in the find panel accept pinch-zoom.


### Improvements

- Avoid selecting deleted spaces when undoing a soft tab deletion.
- Make the credits view in About panel dark in the Dark Mode.
- Add “.cxx” extension to “C++” syntax style.
- Adjust the width of line number views.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix an issue where the cursor position did not restore correctly after repeatedly undoing & redoing bracket insertion with the “Automatically insert closing brackets and quotes” option enabled.
- Fix an issue where editor scrolled unwantedly after pasting something at a latter half part of the document with “Link URLs in document” option enabled.
- Fix an issue where URL link ranges expanded even if non-URL-related lines is pasted just after an URL.
- Fix an issue where the application could rarely crash under specific conditions.



3.6.1 (288)
--------------------------

### New Features

- Add “Match only whole word” option to advanced find options (Default: off).
- Add syntax style for “Properties” (mainly for Java).


### Improvements

- [AppStore ver.] Enable the enhanced runtime protection on macOS 10.14 Mojave also by the MAS version.
- Make the i-beam cursor more legible in a dark background theme.
- Sync sidebar width among tabbed windows.


### Fixes

- Fix an issue where the initial window size could be easily forgotten.
- Fix an issue `cot` command failed if the client terminal is non-scriptable.
- Fix an issue where the application could rarely crash on reopening documents under specific conditions.
- Fix the tab window switching via a shortcut key in macOS 10.14.



3.6.0 (286)
--------------------------

### Fixes

- Fix an issue where theme was not applied to document print when the print theme setting is “Same as Document's Setting”.
- Fix an issue where “Copy as Rich Text” command lost the style information when paste to some specific applications, such as Pages.
- [beta] Fix an issue where theme color was not applied to document print.
- [beta] Fix an issue where the editable area in editors are ocasionally set wrong after zooming on macOS 10.14 Mojave.



3.6.0-beta.3 (279)
--------------------------

### Improvements

- [beta] Localize newly added strings in Portuguese.


### Fixes

- [beta] Fix an issue where the title bar color was not correctly updated when the system appearance is changed.



3.6.0-beta.2 (278)
--------------------------

### New Features

- Add an option to select the default writing direction among left-to-right, right-to-left, and vertical (Customize in Window preferences pane).


### Improvements

- Abandon the ancient ODB editor support.
- [beta] Localize newly added strings in Chinase, German, and Italian.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- [beta] Fix an issue the read-only icon in the status bar displayed opposite.
- [beta] Text view stacks under the line number view when zoomed.


### Known Issues

- [Mojave] The title bar color is not correctly updated when the system appearance is changed.
- [Mojave] The editable area in editors are ocasionally set wrong after zooming.



3.6.0-beta (276)
--------------------------

### New Features

- Support Dark Mode in macOS 10.14 Mojave.
- Add a new theme “Dendrobates (Dark)”.
- Add new commands to transform selections to snake case, camel case, or pascal case.
- Add “Emoji & Symbols” toolbar item.
- [non-AppStore] The non-AppStore application binary is now notarized by Apple.


### Improvements

- Change the system requirement to __macOS 10.12.2 Sierra and later__.
- Update `cot` command-line tool to return the focus to the client terminal window again after `--wait`.
- [trivial] Improve the high contrast mode support.
- [trivial] Optimize the performance of line number drawing.
- [dev] Update build environment to Xcode 10 (Swift 4.2, macOS 10.14 SDK).
- [non-AppStore ver.] Enable Enhanced Runtime protection for macOS Mojave and later.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix an issue where the current line highlight could blink while pinch zoom.


### Known Issues

- [Mojave] Text view stacks under the line number view when zoomed.
- [Mojave] The title bar color is not correctly updated when the system appearance is changed.



3.5.4 (275)
--------------------------

### Fixes

- Fix an issue where toolbar items did not reflect their state on macOS 10.12 or earier.
- Fix margin around the Tab toolbar icon on macOS 10.12 or earier.



3.5.3 (274)
--------------------------

### Fixes

- Fix an issue where the “Replace All” command didn't work on CotEditor 3.5.2.



3.5.2 (273)
--------------------------

### Improvements

- Avoid editor can be edited while a dialog covers it.
- Update YAML syntax style for more reliable highlight.
- Update Swift syntax style by fixing outline extraction.
- [trivial] Adjust initial document window size.


### Fixes

- Fix an issue where the multi replacement feature exported definitions without its file extension.
- Fix an issue where “Hide extension” checkbox in the setting export dialog was ignored.
- Fix an issue where an unhidable empty progress dialog was displayed if another dialog was displayed when the task started.
- Address an issue where the application could rarely crash during syntax highlighting.



3.5.1 (271)
--------------------------

### Improvements

- Change the find behavior of the simple Find/Replace command with “In selection” option to find a match only in the selection.


### Fixes

- Fix an issue where the initial window size could be easily forgotten.
- Fix an issue where the font button in the toolbar did not work.
- Fix an issue where the inputting text that is not finalized yet could be wrongly highlighted.
- Fix an issue where some Unicode block names were not displayed in character info popover.
- Address an issue where the application could rarely crash during syntax highlighting.




3.5.0 (268)
--------------------------

### Improvements

- Update Python syntax style for Python 3.7.
- Update Swift syntax style for Swift 4.2.
- [dev] Remove dependency on iculibcore.



3.5.0-rc (266)
--------------------------

### New Features

- Let the input fields in the find panel accept text scaling commands, such as “Bigger”, “Smaller” and “Reset to Default”.


### Improvements

- [beta] Apply overscrolling rate change immediately.
- [beta] Localize all text added in CotEditor 3.5.0.


### Fixes

- [beta] Fix an issue where the application crashed immediately on launch on OS X 10.11.



3.5.0-beta.2 (264)
--------------------------

### Improvements

- Keep the cursor position as possible after the editor content is updated to the latest version modified by another process.
- Optimize auto URL detection with paste to a large document.
- [beta] Update toolbar button images.
- [trivial] Update some Japanese localization.



3.5.0-beta (263)
--------------------------

### New Features

- New toolbar icons.
- Highlight the same substrings of the selection automatically (Customize the behavior in General preferences pane).
- New option to allow overscrolling (Customize the behavior in Window preference pane).
- Enable to change the tab width of a specific document to a desired number.


### Improvements

- Add command “Select All Find Matches” in Find menu.
- Improve the editor's scrolling behavior to scroll along the predominant axis.
- Add menu item to toggle the visibility of the sidebar inspector.
- Remove some setting options for windows such as window size and visibilities of document inspector and status bar from Window preferences pane.
    - From now on, the latest change to a window will be inherited to future windows just like other standard Cocoa applications.
- Remove “length” display in the status bar.
- Remove feature to change only the frontmost editor's opacity temporary.
    - From this, `view opacity` property on AppleScript is also deprecated.
- Display current user's system-wide setting for window tabbing in the menu on the Window pane.
- Optimize the performance of character counting.
- Improve general stability of the print operation.
- [trivial] Count progress of the Highlight command in Find menu match by match.
- [trivial] Update editor opacity sample tips.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix an unlocalized text.



3.4.4 (261)
--------------------------

### Fixes

- Address an issue where the application could rarely crash on syntax highlighting.
- Address an issue on Mojave where text view stacked under the line number view.
- Fix a typo in Italian localization.



3.4.3 (259)
--------------------------

### Fixes

- Fix an issue where the help button in the multiple replace window did not link to the suitable help page.
- Fix an issue where the current line highlight was opaque in split editors although the editor background is non-opaque.
- Fix an issue where unwanted debug log was printed in the Console.
- Fix an issue where “Show File Mapping Conflicts” menu item was always available even no conflict exists.
- Improve general stability.
- Fix an unlocalized label.



3.4.2 (257)
--------------------------

### Improvements

- [trivial] Let input fields in preferences support dark mode (hidden option on the current systems).
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix an issue under OS X 10.11 where the application crashed with the auto-completion.
- Fix an issue where some syntax keywords were not highlighted correctly.
- Improve general stability.
- [trivial] Fix drawing of capsules for variables in the insertion format setting field.



3.4.1 (253)
--------------------------

### Improvements

- Copy also the executability from the file permission of the original document when duplicating a document.
- [trivial] Improve drawing of capsules for variables in the insertion format setting field.
- [trivial] Adjust preferences panes layout.


### Fixes

- Fix an issue under OS X 10.11 where the application could crash when an item in the outline inspector is clicked.
- Fix an issue where the word completion of which word starts with double underscores (e.g. `__init__`) skipped the second underscore.
- Fix an issue where the application could rarely crash while typing.
- [AppStore ver.] Fix an issue where the options for the software updater for non-AppStore versions were wrongly displayed in the General preferences pane.



3.4.0 (251)
--------------------------

### Improvements

- [beta] Localize newly added strings in Italian.
- [beta] Link help buttons to the latest help pages.



3.4.0-rc (249)
--------------------------

### Improvements

- [beta] Rename “Set Replacement” feature to “Multiple Replacement.”
- [beta] Localize all text added in CotEditor 3.4.0.
- [beta] Add help page about the multiple replacement.


### Fixes

- [beta] Fix an issue the application could crash while typing.
- [tirivial] Fix an issue on macOS 10.12 and earlier where the Japanese label of the menu item toggling toolbar visibility did not reflect the current visibility state.



3.4.0-beta.4 (246)
--------------------------

### Fixes

- [beta.3] Fix an issue where application could crash on changing selection in editor view.



3.4.0-beta.3 (245)
--------------------------

### Improvements

- Optimize syntax highlighting performance.


### Fixes

- Fix an issue where the sidebar inspector did close inward when the pane was switched after opening the sidebar outward.
- Fix an issue where snippet keybindings could not be restored to the default correctly.
- Fix an issue where progress spinner for outline menu displayed unwantedly on document opening.
- [beta] Fix an issue where deletion of replacement set items was not saved.
- [beta] Fix a possible crash on window closing.
- [beta][non-AppStore ver.] Fix an issue where options for the application update check in General preferences pane disappeared.



3.4.0-beta.2 (243)
--------------------------

### Improvements

- Enable importing multiple syntax/theme setting files at once.
- Import syntax style files via drag and drop to the Installed Syntax Styles area.
- Avoid merging multiple separators next to each other in the navigation menu into a single separator.
- [beta] Synchronize the selection in the outline inspector with the current cursor position in the focused editor.
- [beta] Replace with a new one when the last replacement definition row was removed, instead of disabling the remove button.
- [beta] Disable the remove button in replacement set panel when nothing is selected.
- [beta][trivial] Adjust outline inspector layout.


### Fixes

- Fix an issue where the cursor position did not follow the line when Move Up command was performed at the end of the document.
- [trivial] Fix some UI text.



3.4.0-beta (241)
--------------------------

### New Features

- Replace matches with preset replacement definition (Find > Show Replacement Set).
- Add outline menu to side bar.
- Select tabbed window with `⌘+number`.
- Parse regular expression pattern in find string field in regular expression mode:
    - Syntax highlight.
    - Highlight matching brace by moving cursor.
    - Select the range surrounded by a brace pair by double-clicking a brace.
- Add a new theme “Resinifictrix”.


### Improvements

- Give haptic feedback on pinch zoom when the scale becomes 100%.
- Adjust background color for selected range in inactive editor to avoid unreadable text, especially by a dark theme.
- Make the current line highlight semi-transparent if editor opacity is not 100%.
- Ignore brackets escaped with `\\` on bracket pair highlight.
- Restore selected inspector pane on window restoration.
- Move “Get Info” and “Show Incompatible Characters” menu items into newly added View > Inspector submenu.
- Update highlight style of icons in the side inspector.
- Delete the feature alerting inconsistent encoding declaration in document on saving.
- Remove `⌘1` shortcut for Console from default key-binding settings.
- Avoid switching to inactive tabbed window only to show a syntax highlighting indicator.
- Remove the workaround for the issue of editor scrolling on early macOS High Sierra that was introduced on CotEditor 3.2.4.
- Update “Java” syntax style by adding term `var` (Thanks to Marc Prud'hommeaux!)
- [trivial] Use monospace digits where suitable.
- [trivial][non-AppStore ver.] Update Sparkle framework.
- [dev] Update build environment to Xcode 9.3 (Swift 4.1).


### Fixes

- Fix a possible crash with continuous find/replacement.
- Fix an issue where the font settings cannot be changed on macOS 10.12.
- Fix an issue where the find result in the input field of the find panel did not clear when a new find string was set from the find history menu.



3.3.5 (237)
--------------------------

### Improvements

- Update “Swift” syntax style for Swift 4.1.


### Fixes

- Fix an issue where application could rarely crash under specific environment on saving.
- Fix an issue where the domain part of URL was ignored when a favicon was dropped from Safari to editor.
- Update “YAML” syntax style to fix outline extraction with a specific case.



3.3.4 (234)
--------------------------

### Improvements

- When “Indent with Tab key” is on, reduce indent level of the current line with Shift+Tab even when nothing is selected.


### Fixes

- Fix an issue where lossy saving was failed.
- Fix an issue where `⌘←` was ignored when the cursor locates at the end of the document.
- Fix an issue where save dialog layout corrupted when toggling the visibility of the file browser.
- Fix an issue where no alert was raised on saving even when a document contains lossy yen signs.
- Fix an issue where document syntax was parsed twice on file open.
- Fix a possible crash on print.



3.3.3 (232)
--------------------------

### New Features

- Add an option “Indent with Tab key” to the Edit pane in preferences.


### Improvements

- Change the behavior of  `⌘←` so that the cursor moves first to the beginning of the visual lines, then to the column right after indentation, and finally to the beginning of the line.
- Remove “Open Hidden” command (Use “Show hidden files” option in the open dialog instead).
- Display an open dialog on launch if so set even when iCloud storage is disabled.
- Improve stability on text encoding change.
- Refine dialog messages on text encoding change.
- Change sidebar behavior to close inward when it was opened inward because of insufficient space.
- Avoid requiring high power GPU use.
- [trivial] Hide insertion point in shortcut input fields in the Key Binding pane.
- [trivial] Set a spoken name of CotEditor.
- [trivial] Add `enablesAsynchronousSaving` hidden default key that enables asynchronous saving.
- [non-AppStore ver.] Update Sparkle framework.


### Fixes

- Fix a long-standing issue where incompatible characters could not be detected when the length of converted document text is changed.
- Fix an issue where key-binding setting field sometimes ignored user input.
- Fix an issue where wrong file creation date and file permission could be displayed in the document inspector.
- Fix an issue where document files did not forget vertical orientation state when once set before.
- Fix an issue where the encoding selected in the open dialog last time was unwantedly applied to the newly opened document when a document opened with the open dialog previously had already opened.
- Fix an issue where menu item title for “Horizontal” (in Format > Writing Direction) was displayed as “Vertical” in Japanese localization.



3.3.2 (229)
--------------------------

### Fixes

- Fix an issue on CotEditor 3.3.1 where the application could crash on window close.
- Fix an issue where application crashed when performing “Find All” with the regular expression and without grouping (Thanks to @akimach!).



3.3.1 (228)
--------------------------

### Fixes

- Fix an issue where the application crashed on launch under specific conditions.
- Fix an issue where the iCloud storage was not enabled.
- Fix arrows in the navigation bar on the vertical text mode.



3.3.0 (224)
--------------------------

### Fixes

- [beta] Fix an issue where iCloud document storage was not created.
- [beta] Fix an issue where find result message in the find panel fields was not shown.



3.3.0-beta.3 (220)
--------------------------

### Improvements

- [beta] Adjust position of invisible line ending character on the RTL writing mode.
- [beta] Tweak the layout of the “Sort by Pattern” dialog.
- Update Help contents style.


### Fixes

- Fix an issue where invisible symbols for control characters were not drawn in input fields in find panel.
- Fix an issue where character inspector could expand vertically too much with some specific characters.
- [beta] Fix an issue where AppleScript (and JXA) could not communicate with some APIs.
- [beta] Fix an issue where the views containing an encoding menu could display nothing under a specific setting condition.
- [beta] Fix an issue where pasted URLs from specific applications missed the domain part.
- [beta] Fix an issue where the current line highlight started at a wrong place on the RTL writing mode.
- Fix some unwanted title case in the preferences.



3.3.0-beta.2 (218)
--------------------------

### Improvements

- Enable “shift right” and “shift left” commands to process multiple selections.
- [beta] Swap actions for “shift right” and “shift left” in the RTL writing mode so that the indentation direction matchs to the command name.
- [beta] Add “Keep the first line at the top” option to the pattern sort.
- [beta] Add toolbar item toggling writing direction.
- [beta] Update alignment icons in print pane.
- [beta] Adjust layout of preferences panes.


### Fixes

- [beta] Fix an issue where syntax style list became empty.
- [beta] Fix an issue where page guide was drawn at a wrong position if editor is scaled and the writing direction is RTL.
- [beta] Fix an issue where text did not changed to the RTL writing direction if lines are not wrapped.
- Fix scroll position in the help viewer on jumping to a help page from CotEditor.



3.3.0-beta (216)
--------------------------

### New Features

- iCloud document.
- Open a document in the existing Untitled window that was created automatically on an open/reopen event, if exists.
- New feature “Sort by pattern,” which enables sort selected lines by specific column or fully freely using the regular expression.
- Add new setting option “Reopen windows from the last session on launch” in General pane.
- Add new setting option “including whitespace-only lines” for “trim trailing whitespace” command in General pane.
- Introduce “Right to Left” writing direction by changing the direction from Format > Writing Direction menu.
- More integrated Share feature:
    - Share documents with other people through iCloud drive with “Add People” command in the File > Share menu.
    - Enable sharing a document that has not been saved yet.
    - Remove the feature that shares document content text from the File menu (You can still share selected text from the context menu).
    - Other small improvements.
- Add new commands “Half-width to Full-width” and “Full-width to Half-width” to Text > Transformations menu.
- Add Portuguese localization (thanks to BR Lingo!).
- Add the following encodings to the encoding list (To activate new encodings, restore default once in Preferences > Format > Edit List.):
    - Thai (Windows, DOS)
    - Thai (ISO 8859-11)


### Improvements

- Change the system requirement to __OS X 10.11 El Capitan and later__.
- Add clear button to the input fields in the find panel.
- Gather the “open a new document” “on launch” and “when CotEditor becomes active” options and create new “When nothing else is open:” option.
- Scroll console view after getting a new message to make it visible.
- Display sharing window within the target document window.
- Swap position of “View” with “Format” menu to conform to the Apple's Human Interface Guidelines.
- Move the menu item changing the text orientation into Format > Writing Direction.
- Display full encoding name in the status bar instead of the IANA charset name.
- Add tooltips to the Unicode normalization forms in Text menu.
- Append “Option-Command-T” shortcut to “Show/Hide Toolbar” menu item.
- Remove “Color Code Panel” command from the “Window” menu (use “Edit Color Code...” command in “Text” menu instead).
- Remove “share find text with other applications” option.
- Restore the last viewed preference pane when Preferences is opened.
- Add an input field for the editor opacity setting.
- Adjust scroll after toggling line wrap.
- Add scroll margin to the right side of find panel fields dynamically, so that entire inputs can be seen even when find/replacement result is shown.
- Update Python syntax style:
    - Fix highlight of string and bytes literals.
- Tweak acknowledgments window design.
- Some minor UI improvements and fixes.
- Update Japanese localization to conform with the modern macOS localization rules.
- Update the internal source code to Swift 4.
- [non-AppStore ver.] Now, the application updater (Sparkle) can download and update CotEditor automatically, as like before CotEditor was Sandboxed.
    - This feature can actually be used first updating CotEditor 3.3.0 to CotEditor 3.3.1 or later.


### Fixes

- Fix an issue where the word suggestion in the Touch Bar cannot insert a word starts with a symbol correctly, and, therefore, a workaround was added on CotEditor 3.2.3.
- Fix some unlocalized text.



3.2.8 (213)
--------------------------

### Fixes

- Fix an issue where CotEditor occasionally failed sending the standard input to a UNIX script launched from the Script menu.
- Fix an issue where the custom “Surround Selection With” command in Text menu did not use the last input when OK button is pressed.
- Fix an issue where the editing state dots in the installed style list was not updated after editing syntax style.



3.2.7 (212)
--------------------------

### Improvements

- Spread background drawing over paper width on printing.


### Fixes

- Fix an issue where the find panel was over expanded when performing “Find All” with a long find string.
- Fix an issue where the file size in the status bar was not updated after saving.
- Fix an issue where the find panel didn't select the previous field with Shift + Tab keys.
- Fix an issue where the application frozen by opening the File Mapping Conflicts list when filename conflict exists.



3.2.6 (210)
--------------------------

### Fixes

- Fix an issue where backslashes in replacement strings were not unescaped correctly.
- Fix an issue where items in the Script menu were not sorted by prefix numbers.
- Fix a possible crash on handling documents with an invalid shebang.
- Fix Japanese localization.



3.2.5 (208)
--------------------------

### Improvements

- Some minor UI improvements.


### Fixes

- Fix an issue where a vertical orientation document broke the layout on printing.
- Fix an issue where the syntax highlighting indicator could display twice.
- Fix an issue where the separator was selected meaninglessly in the Window pane if the window tabbing setting was set to “Manually”.
- Fix an issue where editor's text orientation was not cascaded to the print operation when the window was restored from the last session.
- Fix the line-wrapping behavior when a line contains a long unbreakable word.
- Fix some missing localized strings.
- Improve general stability.



3.2.4 (207)
--------------------------

### Improvements

- Keep showing the console when CotEditor becomes inactive.
- Make the Key-Bindings for “Bigger” and “Smaller” actions in Font menu customizable.
- Change to display the first line number even the document is empty.
- Rename “Incompatible Characters” toolbar item to “Incompatibles”.
- Some minor UI improvements and fixes.


### Fixes

- [High Sierra] Workaround a system issue where editor views could occasionally not scroll to the end of the document under specific environments on macOS 10.13 High Sierra.
    - [for advanced users] This workaround may affect rendering performance by large size documents, because the workaround disables non-contiguous layout on High Sierra (The non-contiguous layout are still used on lower versions). The workaroud will be removed in the future when the bug origin is resolved. You can forcibly enable non-contiguous layout support on High Sierra by setting the hidden default key `enableNonContiguousLayoutOnHighSierra` to `YES` in Terminal, although this key is actually for debug-use.
- Fix an issue where “Reset to Default” action in Font menu was ignored.
- Fix an issue where matching brace was highlighted unwontedly also by text finding.
- Fix an issue where the encoding and the line endings in the status bar were occasionally not displayed.
- Fix an issue where the application froze by getting the content of a large document via the Script menu.
- Fix an issue where the second value of the printed time in the console was not sexagesimal.
- Improve general stability.



3.2.3 (205)
--------------------------

### Improvements

- Disable toggling sidebar while the tab overview mode on High Sierra.
- Update “CSS” syntax style:
    - Fix an issue where keywords were highlighted incorrectly.
- Some minor improvements and fixes.


### Fixes

- Fix an issue where UNIX scripts could fail getting the content of the document.
- Fix an issue where font change in the preferences pane could be ignored.
- Fix a potential issue where syntax keywords could be highlighted incorrectly if whitespaces accidentally get into keywords definition.
- Workaround an issue where word suggestion in the Touch Bar cannot insert a word starts with a symbol correctly.
- Workaround an issue where the application could crash on document auto-saving.



3.2.2 (203)
--------------------------

### New Features

- Add new `NewDocument` option to `CotEditorXOutput` for UNIX Scripting to put output string to a newly created document.


### Improvements

- Improve Replace All action:
    - Avoid recoloring after Replace All if no text replaced.
    - Improve the progress indicator.
- Change to highlight matching braces just like Xcode.
    - No more beep for unbalanced braces.
- Update “JavaScript” syntax style:
    - Add “.pac” extension.
- Update build environment to Xcode 9 (SDK macOS 10.13).


### Fixes

- Fix an issue where the Key Binding setting tables were empty on macOS 10.13 High Sierra.
- Fix an issue where current line highlight was occasionally too wide when line height is 1.0.
- Fix an issue where text selection highlight could remain between lines.
- Fix an issue where the theme customization was not applied immediately.
- Fix an issue where the hanging-indent was not updated in specific cases.



3.2.1 (201)
--------------------------

### Improvements

- Adjust character inspector position for vertical tab.
- Update `cot` command-line tool:
    - Avoid creating an extra blank document if `cot` command creates a new window.
    - Fix an issue where launching the application with `--background` option didn't make CotEditor visible.
- Adjust line height calculation.
- [non-AppStore ver.] Update Sparkle framework to version 1.18.1.


### Fixes

- Fix an issue where the File Drop settings couldn't be saved.
- Fix an issue where the regular expression didn't handle `\v` metacharacter correctly.
- Fix an issue where the selection of encoding menu in toolbar didn't restore to the previous one when encoding reinterpretation was failed.
- Address an issue where the application could crash on document saving or text replacement.
- [AppStore ver.] Fix an issue where acknowledgement window was empty.



3.2.0 (196)
--------------------------

### Fixes

- [beta] Fix syntax color highlighting under specific comments and quotes conditions.



3.2.0-beta.2 (194)
--------------------------

### Improvements

- [beta] Update Italian localization.


### Fixes

- [beta] Fix application's code signing.
- [beta] Fix comment highlights.
- [beta] Fix a potential crash.
- [beta] Fix minor UI layout.



3.2.0-beta (193)
--------------------------

### New Features

- Improve File Drop feature:
    - Now, you can add a file drop setting only for a specific syntax style.
    - Add description field to the setting table.
    - Draw capsule for variables in the insertion format setting field.
    - Update the default file drop settings.
- Now, key binding snippets can set cursor position.
- Add “Surround Selection With” actions to “Text” menu.
- Add a new AppleScript/JXA command `write to console` so that users can insert own message to the CotEditor's console.
- Add syntax style for “Fortran”.


### Improvements

- Change syntax style detection behavior to set to “None” style if no appropriate style can be found on file opening.
- Significantly improve the performance of “Replace All” with a large document.
- Avoid hiding console panel when CotEditor becomes not the frontmost application.
- Reduce highlight parsing time with large size document.
- Improve performance of closing large size document.
- Improve drawing performance of a large size document with a non-opaque background (Not enough good as an opaque one but still better than before).
- Add hidden “Reload All Themes/Styles” menu item to theme/syntax style action menus in Preferences (visible with `Option` key).
- Enable changing text size with a single stroke by pressing and holding Touch Bar's Text Size button.
- Improve invisible character drawing on a non-opaque view.
- Improve auto-brackets/quotes insertion behavior with multiple selections.
- Improve the setting file naming rule for when the name overwraps with an existing setting.
- Improve condition to insert a closing quote automatically.
- Improve the encoding declaration detection.
- Update “Ruby” syntax style to fix commands highlight.
- Update “MATLAB” syntax style to fix strings highlight.
- Remove less useful “Inline script menu items into contextual menu” option.
- Update German localization (Thanks to J-rg!).
- And some minor improvements and fixes.


### Fixes

- Fix an issue where the application could hang up when lots of tabbed windows are about open.
- Fix an issue where the selections after “Replace All” in selection shifted one character.
- Fix an issue where the document syntax style could be back to the default if the current style was set manually and the document was modified by another process.
- Fix an issue where the status bar stopped updating after toggling the inspector sidebar.
- Fix an issue where the “Cancel” button in the dialog shown when changing the Auto Save setting in General pane didn't revert the actual setting state.
- Fix an issue where author of a theme was not shown in the Appearance pane.
- Fix an issue where width and height in the window size setting window were swapped.
- Fix an issue where current line highlight occasionally blinked unwontedly.
- Fix a possible crash on highlighting matching brace.
- Fix few memory leaks.



3.1.8 (191)
--------------------------

### Improvements

- Add “.swift” extension to file types treaded as CotEditor script.
- [non-AppStore ver.] Update Sparkle framework to version 1.17.0.


### Fixes

- Update cot command:
    - Fix an issue where files cannot be opened if the default Python on macOS is version 3.x.
    - Fix a possible hang under specific environments.



3.1.7 (188)
--------------------------

### Fixes

- Fix an issue on MacBook Pro with Touch Bar where the application crashed immediately after launch.



3.1.6 (186)
--------------------------

### Improvements

- Update Python syntax style for Python 3.6.
- Improve line number drawing.


### Fixes

- Fix an issue on OS X 10.11 where the application could crash on saving a document that contains incompatible characters.
- Fix an issue on OS X 10.11 where “No incompatible characters were found.” message in the incompatible characters pane didn't hide even when incompatible characters exist.
- Fix an issue where editor view didn't scroll by dragging on the line number view when the view is zoomed out.
- Fix an issue where a large amount of scrolling down didn't jump to the end of the target.
- Fix an issue with syntax style editor where a newly added row wasn't focused automatically.



3.1.5 (184)
--------------------------

### Fixes

- Fix an issue where the application could crash by auto-completion on OS X 10.10.



3.1.4 (182)
--------------------------

### New Features

- Update `cot` command-line tool.
    - Enable using wildcard for file path argument.


### Fixes

- Fix an issue where the application crashed by the Highlight command under the condition when the find string is a invalid regular expression pattern even the regular expression is turned off.
- Fix an issue where the application could crash on El Capitan when a side inspector is about to open.
- Fix an issue on the text search where the single text search couldn't find the word intersects with the current selection.
- Fix an issue where the metadata of a custom theme cannot be edited.
- Fix an issue where the background of the line number view was drawn with wrong color when entered to the fullscreen mode.
- Fix an issue on the regular expression Replace All with multiple selections where user cancellation didn't stop search immediately.



3.1.3 (180)
--------------------------

### New Features

- Now, AppleScript's script bundles can specify execution mode to enable running the script inside the application Sandbox (thanks to Kaito Udagawa!).


### Improvements

- Optimize script menu updating performance.
- Change behavior to avoid showing incompatible char list on undoing encoding change.
- Evaluate also the shebang to specify the syntax style on saving the document newly.
- Scale up character view in character inspector.
- Change drawing font for some invisible characters to draw them at a better position.
- Update “JavaScript” syntax style.
- Add more description about scripting in the help contents.
- Deprecate hidden settings for UI update interval.
- Update build environment to Xcode 8.2.1 (SDK macOS 10.12.2).
- [non-AppStore ver.] Update Sparkle framework to version 1.16.0.


### Fixes

- Fix an issue where the application could crash after lossy encoding change.
- Fix an issue where the find string was not synchronized with other applications.
- Fix an issue where the regular expression anchors `^` and `$` could match wrongly on the normal “Find Next/Previous” under specific conditions.
- Fix an issue where incompatible characters highlight could highlight wrong characters if line endings are CR/LF.
- Fix an issue on AppleScript where a single replacement with the regular expression didn't refer to the matches.
- Fix an issue where some touch bar icons were drawn wrongly.
- Fix an issue where the menu item “About Scripting” in Help > “CotEditor Scripting Manual” didn't work.
- Fix an issue where the zoomed character in the character inspector was flipped when the popover is detached.
- Fix an issue where `lossy` option in `convert` command by AppleScript scripting was ignored.
- Fix an issue on the AppleScript scripting where `range` property of `document` contents could be wrong if document line endings are not LF (thanks to Kaito Udagawa!).
- Fix an issue where the editor opacity couldn't be set via AppleScript.
- Fix minor typos.



3.1.2 (177)
--------------------------

### New Features

- Add Scripting hook feature for document opening/saving (thanks to Kaito Udagawa!).
    - See “Adding scripting hooks for CotEditor scripts” from the Help menu > “CotEditor Scripting Manual” > “About Scripting” for details.
- Support AppleScript's script bundle (.scptd) for scripting (thanks to Kaito Udagawa!).
- Add a new AppleScript property `expands tab` for document object (thanks to Kaito Udagawa!).


### Improvements

- Change the outline navigation arrows direction in the navigation bar if text orientation is vertical.
- Add tooltips to the line endings menu in the toolbar.
- Improve calculation of the vertical position of line numbers.
- Tweak the behavior of the incompatible character table and the find result table to highlight the correspondent range in the editor every time when clicking a row in the table.
- Update default settings about the visibility of invisible characters.
    - From this change, the invisible character settings can be reset. If so, please reset from the “Appearance” pane in the preferences.
- [non-AppStore ver.] Update Sparkle framework to version 1.15.1.


### Fixes

- Fix a possible crash on changing document's encoding lossy.
- Fix an issue where application crashed if syntax editor panel becomes too small.
- Fix an issue where the print icon in the toolbar didn't work.
- Fix an issue where editor views didn't update after changing the body font or the visibility of the other invisible characters.
- Fix an issue where no error message raised when a text encoding reinterpretation failed.
- Fix an issue where the current line highlight also highlights the last line when the cursor is in the second last line.
- Fix an issue where the title of the menu item toggling invisible character visibility didn't reflect the frontmost window state.
- Fix an issue where the text size slider in the Touch Bar didn't update if text size was updated excepting via Touch Bar while the slider is shown.
- Address an issue with drawing area of zoomed character view in character inspector popover.
- Fix a typo in the English menu.


### Misc.

- You can now find CotEditor scripts on [GitHub Wiki](https://github.com/coteditor/CotEditor/wiki/CotEditor-Scripts).



3.1.1 (174)
--------------------------

### Fixes

- Fix a critical issue on CotEditor 3.1.0 where documents can't be opened under some specific environments.



3.1.0 (172)
--------------------------

### New Features

- Improve window tabbing on macOS Sierra:
    - Add an option to set window tabbing behavior (in Window pane).
    - Open multiple files in a single window with tabs when the window tabbing behavior is set as “Automatically” (or “In Full Screen Only” in system-wide).
- Support Touch Bar on the new MacBook Pro.


### Improvements

- Display the number of replaced in the replacement string field after Replace All in the find panel.
- Display the IANA charset name conflict alert as a document-modal sheet.


### Fixes

- Fix an issue where the application could crash on a large amount of text change.
- Fix an issue where the application crashed when try to save a document with Non-lossy ASCII encoding.
- Fix an issue where some kind of files could not be opened via Service.
- Fix an issue where text fields in find panel cut off the end of long lines.
- Fix an issue where the alert about the conflict with IANA charset name was not displayed.
- Fix syntax highlight of quoted text of which quotation delimiter consists of multiple characters.
- Improve general stability.



3.0.5 (170)
--------------------------

### Fixes

- Fix an issue where scripts didn't put results on the document/console.
- Fix an issue where the editor area was occasionally stacked under the window toolbar on macOS 10.12.
- Fix an issue where MarsEdit via the App Store didn't update its contents after closing the document in CotEditor.
- Improve general stability.



3.0.4 (167)
--------------------------

### Improvements

- Update build environment to Xcode 8.1 (SDK macOS 10.12.1).


### Fixes

- Fix an issue where scripts didn't put results on the document/console.
- Fix an issue where find all results didn't open anymore under the specific conditions.
- Fix an issue where MarsEdit didn't update its contents after closing the document in CotEditor.
- Improve general stability.



3.0.3 (165)
--------------------------

### New Features

- Add the following encodings to the encoding list (To activate new encodings, restore default once in Preferences > Format > Edit List.):
    - Arabic (Windows)
    - Greek (Windows)
    - Hebrew (Windows)


### Improvements

- Adjust glyph size calculation.
- Improve performance of Find All and Replace All.
- Disable customizing key bindings for window tabbing actions (Because it's impossible to handle them correctly.)
- Update “Swift” syntax style to add some missing keywords.
- Improve error message on script error.


### Fixes

- Fix an issue where default syntax style didn't highlight document until the first save.
- Fix an issue where selection range after some text actions was wrong.
- Fix an issue where document icons were blurry in non-Retina display.
- Fix an issue where status bar layout collapsed if status line overflows.
- Fix an issue where document theme reloaded unnecessarily on the first time Appearances pane display.
- Fix an issue where the application could crash when a script was failed.
- Fix an issue where scrolling to the end of the document with `⌘`+`↓` shortcut didn't scroll to the end.
- Improve general stability.



3.0.2 (163)
--------------------------

### Fixes

- Fix an issue where the application could rarely freeze after replacing large document.
- Fix an issue where new syntax style couldn't be created.
- Fix an issue where new value of last edited text field in preferences was occasionally discarded.
- Fix an issue where replacement string was not registered to the replacement history.
- Fix an issue where horizontal scroll bars in the find panel fields were disappeared.
- Fix a possible crash on application termination.
- Fix a possible crash on opening document.
- Fix error message of syntax style validation.
- Improve general stability.



3.0.1 (161)
--------------------------

### Improvements

- Add “Complete” action to “Edit” menu.
- On macOS Sierra, the default shortcut for completion action was changed to `⌥⎋`.
- Move action items in the menu “Edit” > “Transformations” to “Text” > “Transformations”.
- Transform word contains the cursor if nothing is selected on transformation or Unicode normalization actions.


### Fixes

- Fix an issue where the application could crash while editing text on Yosemite.
- Fix an issue where the application could crash on split editors under the specific conditions.
- Fix an issue where the application could crash on running an AppleScript/JXA.
- Fix an issue where text completion list didn't occasionally display.
- Fix an issue where syntax highlighting progress indicator was always full.
- Fix an issue where sidebar couldn't be opened on Yosemite.
- Fix an issue where key bindings of recent documents were customizable.
- Fix an issue where the application crashed when a folder is dropped on the application icon.
- Fix an issue where find panel position was not saved.
- Fix an issue where no beep sound was made when there was no match on find/replace.
- Fix an issue where the application could freeze after replacing large document.
- Fix an issue where editable area didn't spread to the full width after changing text orientation when content is empty.
- Fix an issue where matched brackets in unfocused split editors were highlighted without the need while editing one of split editors.
- Improve general stability.



3.0.0 (154)
--------------------------

### Improvements

- Make text font, theme and tab width restorable from the last session.
- [beta] Make seek-bound for find text using regex more naturally.


### Fixes

- Fix an issue where page guide remained after toggling page guide visibility.
- [beta] Fix an issue where the application crashed after user turned the “Give execute permission” checkbox in the save panel on.
- [beta] Fix an issue where the application crashed when a file opens via Service.
- [beta] Fix an issue where toggling status bar visibility didn't work.
- [beta] Fix an issue where text layout orientation was not restored from the last session.
- [beta] Fix an issue where key binding modification in preferences could fail.
- [beta] Fix an issue where submenus in the Script menu displayed in the menu key bindings setting view.
- [beta] Fix an issue where invisible settings were not applied to editors immediately.
- [beta] Fix an issue where “Comment always from line head” option didn't reflect user state.
- [beta] Fix selection after uncommenting when “Append a space to comment delimiter” option is disabled.
- [beta] Fix text wrapping behavior with vertical orientation.
- [beta] Address an issue where the find panel was occasionally collapsed on the first load.
- [beta] And some trivial fixes.



3.0.0-rc.2 (150)
--------------------------

### Improvements

- Exclude file extension from the initial selection in the document save panel.


### Fixes

- [beta] Fix syntax highlight parsing range while editing.



3.0.0-rc (148)
--------------------------

### New Features

- Add Italian localization (thanks to Agostino Maiello!).


### Improvements

- Enable Autosave and Versions by default.
- [beta] Improve sideview behavior.
    - Open sideview outward also on Yosemite.
    - Sync states of sidebar among tabs in a window more correctly.
    - Fix some unwanted behavior around sidebar.
- [beta] Update help contents.


### Fixes

- [beta] Fix an issue where the application could crash on document file sync.
- [beta] Fix an issue where the application could crash on termination.
- [beta] Fix an issue where document could silently be updated by an external document file update even if user doesn't set to “Update to modified version”.
- [beta] Fix an issue where smart dashes substitution state could be set wrongly.
- [beta] Fix an issue where auto indent style detection didn't work.
- [beta] Fix an issue where files were treated as dropped-files instead of just inserting filenames when files are copied-and-pasted from Finder.
- [beta] Fix an issue where the find panel was occasionally collapsed.
- [beta] And some trivial fixes.



3.0.0-beta.3 (146)
--------------------------

### Fixes

- [beta] Fix an issue where the application froze when text search is wrapped.
- [beta] Fix an issue where initial window position was not stored.
- [beta] Fix another memory leaks.



3.0.0-beta.2 (144)
--------------------------

### Improvements

- Auto-sync Script menu with script folder.
    - Now, you don't need anymore to update script menu after script folder modification.
- Display “Not Found” in the find string field in the find panel also when “Find All” failed.
- [beta] Add option “Unescape replacement string” to find panel (On by default).
- [beta] Improve drawing of font fields in preferences.


### Fixes

- Fix an issue find string is not shared with other applications after quitting CotEditor.
- Address an issue with drawing area of zoomed character view in character inspector popover.
- [beta] Fix an issue where current line highlight was occasionally too wide when line height is 1.0.
- [beta] Fix an issue where the result view in the find panel expands wrong way on Yosemite.
- [beta] Fix an issue where divider in the find panel remains after closing result view.
- [beta] Fix an issue where smart indent didn't work.
- [beta] Fix an issue where syntax highlighting flicked while inputting Japanese text.
- [beta] Fix an issue where an input character with Unicode hex didn't work.
- [beta] Fix an issue where text view drawing remained in line number view when text view scaled up.
- [beta] Fix an issue where bottom window corners weren't rounded under the specific conditions.
- [beta] Fix an issue where some window states were not restored.
- [beta] Fix some memory leaks.



3.0.0-beta (142)
--------------------------

### New Features

- Support window tabbing on macOS Sierra.
    - Add “New Tab” action to File menu.
    - Sync sidebar visibility among tabs in a window.
- Display recent used syntax styles at the top of the toolbar syntax style popup list.
- Add individual “Block Comment”, “Inline Comment” and “Uncomment” actions in Text menu unlike the “Comment Selection” action changes its behavior intelligently.


### Improvements

- Support __macOS Sierra__ and drop support for __OS X Mountain Lion__ and __Mavericks__.
- Migrate all source code from Objective-C to Swift.
- Update application icon.
- Update find panel search algorithm:
    - Change the regular expression engine from Onigmo to the ICU library.
        - From this, the reference symbol of matches is changed from `\1` style to `$1`.
    - Update line-up of the search options.
- Inserting single surrogate character is no more valid.
- Update document window toolbar.
- Update preferences icons.
- Update key binding setting format.
    - Not compatible with previous key bindings setting. Please customize again in the preferences window.
- New acknowledgments window.
- Update “Swift” syntax style to Swift 3.0.
- Update “Coffee Script” syntax style for the block regular expression.
- Improve syntax highlighting algorithm with symbols.
- New “Go To Line” panel.
- Remove the following less important text actions:
    - Insert Encoding Name with “charset=”
    - Insert Encoding Name with “encoding=”
- Remove the following less important toolbar items:
    - Show / Hide Navigation Bar
    - Show / Hide Line Numbers
    - Show / Hide Status Bar
- Remove the feature that changes the line height of current document from the “Format” menu.
    - From this, `line spacing` property on AppleScript is also deprecated.
- Remove “Not writable” alert which displayed on file opening.
- Remove “Set as Default” button in the editor opacity panel.
- Change specification not to treat full-width spaces as indent.
- Open sidebar inward on Yosemite.
- Add help buttons to syntax style editor.
- Make indent deletion more naturally.
- Remove byte count display in document inspector.
- Display also an accurate file size in document inspector.
- Display dialogs for changing file encoding as a document-modal sheet.
- Display also an accurate file size in document inspector.
- Move scripting manual into help contents.
- Make window size setting window translucent.
- Avoid expanding status bar into side inspector.
- Improve line height calculation.
- Keep visible area after toggling text-wrapping.
- Improve scrolling with line number view drag.
- Better syntax highlighting while editing.
- Enable activate “Show Invisibles” action even if all of the invisible characters were set as not shown when the document was opened.
- Update build environment to macOS Sierra + Xcode 8 (SDK macOS 10.12).


### Fixes

- Fix an issue where some of script APIs returned always string with LF line endings.



2.5.7 (138)
--------------------------

### Fixes

- Fix German localization (Thanks to J-rg!).
- Fix “Markdown” and “Verilog” syntax styles.
- Fix update range of syntax highlight while editing.
- Fix key binding setting error message.
- Fix an issue where syntax validation result view was editable.
- Address an issue where editor's drawing area could become wrong after scaling font size by vertical text.



2.5.6 (135)
--------------------------

### New Features

- Add newly rewritten syntax styles for “C” and “C++”.
    - From this change, previous “C, C++, Objective-C” syntax style is deleted.
- Add syntax styles for “MATLAB” and “Verilog”.


### Improvements

- Update “Markdown” syntax style:
    - Support strikethrough with `~~` that is defined in the GitHub flavored Markdown.
    - Support emphasis with triple `*` and `_`.
- Focus back on the find panel after performing “Find All”, “Replace All” and “Highlight”.
- Change to use the body text color for line numbers on printing that was previously always black.
- Improve scroll behavior with arrow keys.
- Improve compatibility with macOS Sierra beta.
- And some other trivial improvements.


### Fixes

- Fix document counting as followings:
    - “Char Count” counts composite characters as well as CR/LF as single characters and omits counting line endings if “Count each line ending as one character” option is off.
    - “Length” counts bytes in UTF-16 literally and always counts line endings even if “Count each line ending as one character” option is off.
    - “Location” and “Column” count characters just like “Char Count”.
- Fix an issue where the selected marks of line height / tab width in the Format menu disappeared.
- Fix an issue where unselected last line number could be highlighted if the text orientation is vertical.
- Fix an issue where invisible characters were drawn off to the side if the text orientation is vertical.
- Fix an issue where tab width was reset to default when split editor.
- Fix an issue where documents were marked as “Edited” just after document duplication if line ending is not the default one.
- Fix an issue where detected indent style was applied not only on file opening but also every time when file reverted.
- Fix an issue where “Find All” result view did not open on OS X Mountain Lion.
- Fix an issue where incompatible character markup could break if undo/redo lossy encoding change continuously.
- Fix an issue where keybindings of some submenu containers were customizable.
- Fix an issue where tab width could be set as `0`.
- Fix an issue where tab width changing via AppleScript changes only the tab width in the focused editor rather than all split editors.
- Fix an issue where byte length display did not update after changing file encoding.



2.5.5 (130)
--------------------------

### New Features

- Add syntax style for “Git”.


### Improvements

- Update “Julia” and “Swift” syntax styles.
- Apply the change of line height/tab width to all split editors so that split editors not focused also can layout text correctly after the change.
- Optimize text rendering performance a bit.


### Fixes

- Fix an issue where editor area was not focused when document opens.
- Fix an issue where width of tab character could be wrong with specific fonts.
- Fix an issue where selection highlight remained between lines under specific conditions.
- Fix an issue where the current line highlight didn't update under the specific condition.
- Fix an issue where unwanted dirt was drawn if use the Google Japanese Input.
- Fix an issue where file path display in inspector was not updated when document file is moved.
- Fix an issue where wrong data were displayed in document inspector when a window of an unsaved document is resumed.
- Fix an issue where hanging indent was applied when document style is changed even it is turned off.
- Fix an issue where custom syntax style/theme couldn't be removed from the style list if the definition file is already deleted.
- Fix an issue where “Copy as Rich Text” was enabled even if no text is selected.
- Fix an issue where URL links were removed when editor is split.
- Fix an issue where line height broke if font whose editor is split is changed via font panel.
- Fix an issue where the first insertion was registered to the undo history on opening document with the selection in another application via Services.
- Fix an issue where the key binding for “Re-Color All” was forced to reset to the default `⌥⌘R` if syntax style list is updated.



2.5.4 (127)
--------------------------

### Fixes

- Fix an issue where the application didn't work on Mavericks and earlier.
- Fix an issue where syntax was occasionally parsed twice on window restoration.



2.5.3 (125)
--------------------------

### New Features

- Add new normalization form “Modified NFD” (unofficial normalization form adopted by HFS+) to the Unicode normalization action in Text menu (Thanks to DoraTeX!).


### Improvements

- Improve line-height handling with composite font:
    - Remove “Fix line height with composite font” option, and now, the height of lines is always uniform.
    - Update line-height calculation to fix that the line height by “Fix line height with composite font” option was a bit higher than actual line height of the used font.
        - From this change, the line height will get reduced than the previous versions. Please reset the line-height to your favorite number on the Appearance pane in the preferences.
    - Improve line-height calculation.
- Optimize performance to apply syntax highlight to document significantly.
- Now, the setting changes of status bar, appearance, tab and invisible chars are applied to documents immediately.
- Update “INI” syntax style.
- Remove spelling auto correction option.
- Remove “Delay coloring” option.
- Enable move between input fields in syntax style editor with Tab key.
- Apply font-face to font fields in preferences.
- Apply document line height on “Copy with Style”.
- Reflect the state of “Increase contrast” option in system Accessibility setting to custom UI.
- Adjust preferences layout.


### Fixes

- Fix an issue where word-wrap broke mid-word when a line is indented.
- Fix an issue where hanging indent reset if font is changed.
- Fix an issue where some highlight definitions in Comments, Strings or Characters types were ignored.
- Fix an issue where syntax was always highlighted even if syntax highlight is disabled.
- Fix an issue where the application crashed if empty character is input from the Unicode hex panel.
- Fix an issue where syntax highlight was rarely not updated when style definition is modified.
- Fix line numbers position when text scaled.



2.5.2 (123)
--------------------------

### Fixes

- Fix an issue where invisible characters could not be hide.
- Fix an issue where the application could crash if the “Replace All” button was clicked continuously.
- Fix an issue where the application crashed on closing default window size setting window.
- Fix line-wrapping behavior when the line contains a long unbreakable word.



2.5.1 (120)
--------------------------

### Improvements

- Change underline style of outline items.
- Update “JavaScript” syntax style:
    - Improve outline definitions to support the class syntax sugar introduced in ECMAScript 6.
    - Better coloring for “get” and “set”.


### Fixes

- Fix an issue where the application could crash on opening empty file.
- Fix an issue where `cot` command could fail creating new empty file.
- Fix an issue where selected line numbers were not drawn in bold font.



2.5.0 (117)
--------------------------

### Improvements

- [beta] On pinch-zoom, hold a bit at the actual scale.
- [beta] More optimize document opening performance with large file.
- Better error message on file opening.
- Tweak some label text in preferences.


### Fixes

- [beta] Fix an issue where wrapping text by scaled text size wrapped text at a wrong width.
- [beta] Fix an issue where actions of the action (gear) menu in the syntax setting could be failed.
- [beta] Fix an issue where line numbers were shifted a bit if the first character is not drawn with the specified font.



2.5.0-beta (113)
--------------------------

### New Features

- Add independent “Unicode (UTF-8) with BOM” encoding to encoding list.
    - Respect the existence of the UTF-8 BOM in opened files.
    - Enable switching the document encoding between with and without BOM from the toolbar popup button and the “Format” menu.
        - The “Unicode (UTF-8) with BOM” item will be automatically added to just after the normal “Unicode (UTF-8)”.
- Now, the execute permission can be given to the file to save from the save panel.
- Add spelling auto correction option (in “Edit” pane).
- Add a new theme “Lakritz”.


### Improvements

- Update `cot` command-line tool:
    - Create a new file if a non-existent file path is passed in with `--new` option.
- Revert “Highlight” and “Unhighlight” actions in “Find” menu.
- Improve font-size changing behavior:
    - Smoother pinch-zoom.
    - Now font-size change applies only to the focused editor.
    - Enable pinch-zoom to make font smaller than default font size.
    - Font size changing doesn't affect the actual font anymore but just scale characters visibly.
    - Fix an issue where font-size changing could remove hanging indent.
    - Fix an issue where layout of split editors will be broken if the font of one of the other split editors is changed.
- Separate the “Enable smart quotes and dashes” into “Enable smart quotes” and “Enable smart dashes” (in “Edit” pane).
- Apply the following text actions to the whole document if no text is selected:
    - Indentation > Convert Indentation to Tab / Spaces
    - Lines > Sort
    - Lines > Reverse
    - Lines > Delete Duplicates
- Optimize document opening performance with large file.
- Add “Copy as Rich Text” action to the contextual menu.
- Improve recovering status of unsaved documents on window resume.
- Improve line number view drawing with selection on vertical text mode.
- Improve invisibles drawing:
    - Optimize drawing performance (ca. 2x).
    - Better drawing if anti-aliasing is off.
- Display the following dialogs as a document-modal sheet:
    - The dialog asking encoding compatibility on saving.
    - The print progress panel.
- Avoid registering indentation conversion action to the undo history if no text was changed.
- Suppress trimming whitespace at the editing point on auto-saving when “Trim trailing whitespace on save” is on.


### Fixes

- Fix an issue where printing area could be cropped.
- Fix an issue where the background of navigation/status bars were not drawn under a specific condition.
- Fix an issue where the numbers in the line number view could be drawn in a wrong place if the editor is vertical text mode and unwrapped.
- Fix an issue where document could not be drawn until the end of the file on legacy OS if the file contains control characters.
- Fix an issue on Mavericks and earlier where the application hung up if tried to print line numbers by vertical text layout on printing.
- Fix an issue where line numbers could be drawn at a bit shifted position or even cropped on printing.
- Fix XML document icon.
- Fix some unlocalized text.



2.4.4 (111)
--------------------------

### New Features

- Add “Trim Trailing Whitespace” action to “Text” menu.
- Add option to trim trailing whitespace automatically on save (in “General” pane).


### Improvements

- Reimplement highlighting found string groups with different colors.
- Update BibTeX syntax style:
    - Add “.bibtex” extension.
    - Add some field names.
- Update Python syntax style:
    - Remove a duplicated term.
- Now, the change of the page guide column option is applied to opened documents immediately.
- Tweak text in preferences.
- Update help contents.
- [non-AppStore ver.] Update Sparkle framework to version 1.14.0.


### Fixes

- Fix an issue where “Delimit by whitespace” option on text find didn't work.
- Fix an issue where some document file information displayed wrong after saving.
- Fix an issue where line number view could count wrong if wrapped.
- Fix an issue where printing color theme couldn't be changed to “Black and White” on print panel.
- Fix an issue where print preview collapsed if paper size is changed on print panel.
- Fix an issue where “ignore case” option in syntax style definition didn't actually ignore case.
- Fix an issue where the current file extension was omitted from new suggested file name on “Save As…” operation.
- Fix some typos in German localization. (Thanks to Chris Eidhof!)



2.4.3 (108)
--------------------------

### Improvements

- Turn regular expression option off automatically by using selected text for search.
- Update `cot` command-line tool:
    - Add `--wait` (`-w`) option to wait until a newly opened window closes.
    - Optimize command performance.
    - Fix an issue where command cannot open file whose path includes non-ASCII character.
    - Fix an issue where `--line` option didn't work under specific environments.
    - Fix an issue where `--line` and `--column` options didn't move cursor to the desired location if file has blank lines at the end.
- Now, the change of “link URL” option is applied to opened documents immediately.


### Fix

- Fix an issue where documents were marked as “Edited” just after opening file if “link URL” option is enabled.
- Fix an issue where URL link was not applied to pasted text.
- Fix an issue where find-all highlight wasn't removed if find panel is closed before closing find result view.
- Fix an issue where toggling invisible visibility didn't work correctly.
- Fix an issue where the cursor located at the end of document after file opening.
- Fix an issue where thousands separators weren't inserted to document information under specific environments.
- Address an issue where paste was rarely failed under specific environments.



2.4.2 (105)
--------------------------

### Fixes

- Fix an issue on CotEditor 2.4.2 where document window couldn't be opened on Mountain Lion.



2.4.1 (103)
--------------------------

### Improvements

- Update JSON syntax style:
    - Fix float number highlight.
- Avoid displaying `NULL` on the status bar until the first calculation is finished.


### Fixes

- Fix an issue where the text finder's “ignore case” option in the text finder was ignored on CotEditor 2.4.0.
- Fix an issue where the current line number display was wrong if the cursor is in the last empty line.



2.4.0 (101)
--------------------------

### Improvements

- Increase the number of significant digits in file size display.
- Update Shell Script syntax style:
    - Fix variable highlight with `_`.
- [beta] Disable “Balance brackets and quotes” option by default.
- [beta] Don't insert closing bracket if already auto-typed.
- [beta] Update “General” pane layout.



2.4.0-beta (97)
--------------------------

### New Features

- New option balancing brackets and quotes (in “Edit” pane).
- New option making URL in document clickable link (in “General” pane).
- On El Capitan, hidden file visibility can be toggled via checkbox in the document open panel.
- Add the following encodings to the encoding list:
    - Arabic (ISO 8859-6)
    - Hebrew (ISO 8859-8)
    - Nordic (ISO Latin 6)
    - Baltic (ISO Latin 7)
    - Celtic (ISO Latin 8)
    - Western (ISO Latin 9)
    - Romanian (ISO Latin 10)


### Improvements

- Improve text finder:
    - Now, “Find All” action also highlights all matched strings in the editor, and thereby “Highlight” action is removed.
    - Change advanced find option setting from popup menu to popover.
    - On Yosemite and later, a visual feedback is shown when the search wrapped.
    - Keep selected range after “Replace All” with in-selection option.
    - Display a total number of found in find panel on simple find actions.
    - Now, “Find All” and “Replace All” actions are able to process multiple selections.
    - Add Python syntax to the regular expression syntax options.
    - Revert “Use selection for Replace” action to allow using an empty string.
    - Update layout and style.
- `cot` command now opens symbolic link target rather than the link itself.
- On El Capitan, make option control of the document open panel visible.
- Improve syntax highlighting for quoted strings and comment.
- Display alert if file to open seems to be a kind of a media (binary) file.
- Improve file encoding detection.
- Update default priority order of encoding detection.
- Improve character compatibility check.
- Better error message on file opening.
- Take a safety measure for in case the key binding setting file is corrupt.
- Truncate outline label in the navigation bar by appending ellipsis if it overflows.
- Move some options position within “General” pane and “Edit” pane in the preferences window.
- Rename the main text input area in window from “View” to “Editor”.


### Fixes

- Fix cursor location after moving lines with empty selection.
- Fix line-wrapping behavior when the line contains a long unbreakable word.
- Fix an issue where the application crashed by an invalid find regular expression option combination.
- Fix an issue where the application could crash just after starting dictation.
- Fix an issue where keybinding setting could fail.
- Fix an issue where the scroll bar style didn't change to light color on dark background theme.
- Fix an issue where the character inspector didn't show up on Mavericks and earlier.
- Fix an issue where split orientation setting wasn't applied.
- Fix an issue where “Jump to Selection” action didn't jump to selection in editor if another text box is focused.
- Fix an issue where some table cells didn't change their text color when selected.
- Fix tiny memory leaks.



2.3.4 (95)
--------------------------

### Improvements

- Improve line numbers view for multiple selections.
- Now, “Select Line” action works with multiple selections.
- Close character inspector when text selection was changed.
- Reproduce previous selection by undoing line actions.
- Improve syntax highlighting performance.


### Fixes

- Fix an issue where comment-out action didn't work on CotEditor 2.3.3.
- Fix an issue where window title bar was dyed in the editor's background color on El Capitan.
- Fix an issue where text selection after move multiple lines was broken.
- Fix an issue where `$` or `^` anchors in the regular expression via AppleScript didn't work with document that has non-LF line endings.
- Fix an issue where syntax highlighting indicator became occasionally unclosable under the specific condition on document opening.



2.3.3 (91)
--------------------------

### New Features

- Add “Share” menu to File menu.


### Improvements

- Now, you can force-disable window restoration from the last session if you hold Shift key while launch.
- Improve “Input Character in Unicode Hex” panel:
    - Display proposed character info.
    - Allow also taking a 1 to 3 digits point code.
    - Avoid auto-closing panel after entering character.
- Improve character inspector:
    - Display more comprehensible name for control characters (e.g. `<control-0000>` to `NULL`).
    - Display an alternate visible symbol in the zoomed character area for C0 control characters.
- Improve installed syntax style list in preferences:
    - Add dot mark to style names in the list to represent the state if the style is customized.
    - Enable restoring modified syntax style directly from the list without opening the style editor.
- Now, the current line number is drawn in bold font, and always drawn in vertical text mode.
- Select whole text wrapped with quotation marks by double-clicking one of the quotation marks if it is already syntax-highlighted.
- Keep text selection after inserting color code from the color code panel.
- Add “description” field also to outline setting in syntax style editor.
    - From this, update most of bundled syntax styles.
- Add jump to URL button to the style info in the syntax style editor.
- Improve drawing of “Other” invisible characters.
- Improve behavior on Replace/Replace All actions.
- Improve text encoding detection to redress the tendency: a binary file was interpreted as ISO-2022-JP.
- Revert style of popup menus in toolbar on Mavericks and earlier.
- Update line number font.
- Update default fonts.
- Tweak preferences layout.
- Tweak Chinese localization.
- Improve general stability.


### Fixes

- Fix an issue where the application tended to crash by trying opening binary file.
- Fix an issue where line breaks between paths of dropped files were missing.
- Fix an issue where the application crashed when a single character that is a part of surrogate pair is inspected.
- Fix an issue where snippet key bindings could not be customized on Mavericks and earlier.
- Fix an issue where syntax highlight was not updated after reinterpreting encoding.
- Fix an issue where panels could lose target document.
- Fix layout of character popup on Mavericks and earlier.
- Fix an issue where “Recolor All” action was always enabled even if syntax style is “None.”



2.3.2 (89)
--------------------------

### New Features

- Add “Convert Indentation to Spaces/Tabs” actions to Text > Indentation menu.
- Add syntax styles for “METAFONT” (Thanks to M.Daimon!), “AWK”, “Git Config” and “Git Ignore”.


### Improvements

- Improve character inspector:
    - Display also Unicode block if selected letter consists of one character.
    - Display Unicode names of each character if selected letter consists of multiple characters.
    - Fix drawing area of zoomed character view.
    - Fix some other trivial issues.
- Add option to suppress “not writable document” alert.
- Improve text selection by clicking line numbers view.
- Tweak style of popup menus in toolbar.
- Add “description” field that doesn't affect to highlighting but for commenting for each term to the syntax style and syntax style editor.
- Add Swipe to Delete action on El Capitan to tables in syntax style editor.
- Improve text encoding detection for UTF-32.
- Update Python syntax style:
    - Add several commands and variables that are in `__foo__` form.
    - Add `pyi` extension.
- Update Perl syntax style:
    - Add some terms.
- Update PHP syntax style:
    - Add terms added on PHP 5.6.
    - Highlight uppercase `TRUE`, `FALSE`, `AND` and `OR`.
- Update Haskell syntax style:
    - Add some keywords.
- Update DTD, Markdown, reStructuredText and Textile syntax styles to move comments to the description field.


### Fixes

- Fix an issue where text view drawing was distorted while resizing window.
- Fix an issue where line endings of a document that has a line ending character at the beginning of the file cannot be interpreted its line ending type correctly.
- Fix an issue where character inspector returned always `U+000A` (LF) for line ending even the actual line ending of the document is not LF.
- Fix character count with a single regional indicator symbol.
- Fix wrong undo action name on encoding conversion via script.



2.3.1 (85)
--------------------------

### New Features

- Add “Duplicate Line” action to Text > Lines menu.


### Improvements

- Update Python syntax style:
    - Add terms added in Python 3.5.
- Update R syntax style:
    - Fix boolean values were not highlighted correctly.
- Update Shell Script syntax style:
    - Add “command” to extension list.


### Fixes

- Fix an issue where some type of script file cannot be opened because of “unidentified developer” alert even it was made on CotEditor.
- Fix an issue where unwanted completion list was displayed by auto-completion when after typing a symbol character.
- Fix an issue where the application could crash if the width of line number view will change.



2.3.0 (82)
--------------------------

### New Features

- Add “Copy with Style” action to the Edit menu.


### Improvements

- Update “R” syntax style:
    - Add “Rscript” to interpreters.
- Bundle cot command to `CotEditor.app/Contents/SharedSupport/bin/` again.
- Tweak UI text.


### Fixes

- Fix an issue where the application could be launched on unsupported system versions.
- Fix an issue where the baseline of new line invisible characters was wrong if line is empty.
- Address an issue where syntax highlighted control character was sometimes not colored in the invisible color.
- [beta] Fix syntax highlighting issue with multiple lines.



2.3.0-beta (80)
--------------------------

### New Features

- Introduce Auto Save and Versions as an option (in General pane).
- Add new actions handling selected lines to the new Text menu > Lines.
    - They are also added to the AppleScript terms.
- Detect indent style on file opening and set tab expand automatically.
- Add “Spell Check” button to toolbar icon choices.
    - Customize toolbar to add it to your toolbar.
- Add syntax styles for “D”, “iCalendar” and “Rich Text Format”.


### Improvements

- Reconstitute main menu.
- Embed key bindings editor to Key Bindings pane.
- Update “Shell Script” syntax style:
    - Completely rewrite.
- Update “INI” syntax style:
    - Add “url” to extension list.
- Update “JavaScript” syntax style:
    - Add “z” to attributes.
- Temporarily hide the “Live Update” checkbox in the find panel since this feature by OgreKit framework has actually not worked correctly in the latest versions.
- Update Onigmo regular expression engine to 5.15.0.


### Fixes

- Fix an issue where no file path was inserted if file type of the dropped file was not registered to the file drop setting.
- Address syntax highlighting issue with multiple lines.
- Fix an issue where text view drawing was distorted while resizing window.
- Fix an issue where the application could crash on window restoration.
- Fix some typos in syntax styles “Julia” and “SQL”.



2.2.2 (78)
--------------------------

### New Features

- Add new normalization form “Modified NFD” (unofficial normalization form adopted by HFS+) to the Unicode normalization action in Utility menu (Thanks to doraTeX!)
    - cf. <http://tama-san.com/hfsplus_normalize/> (in Japanese)
    - It is also added to the AppleScript terms.


### Improvements

- Update “JSON” syntax style:
    - Add “geojson” to extension list.


### Fixes

- Fix an issue where the baseline of invisible characters was wrong by some fonts.
- Fix an issue where the application could crash after modifying theme name on El Capitan.
- Fix an issue where submenu disclosure arrows in the menu key binding editor did occasionally disappear.
- Fix timing to update search string to system-wide shared find string.
- Fix an issue under the specific conditions where the migration window showed up every time on launch.



2.2.1 (75)
--------------------------

### Fixes

- Fix an issue where the application could crash on typing Japanese text if hanging indentation is enabled.



2.2.0 (74)
--------------------------

### Fixes

- [non-AppStore ver.] Fix an issue where update check failed on El Capitan.



2.2.0-rc.2 (74b)
--------------------------

### New Features

- Add new themes “Anura” and “Note”.


### Improvements

- Remove bundled `cot` command-line tool, due to the Mac App Store guidelines.
    - To use `cot` command with CotEditor 2.2.0 and later, download it from <http://coteditor.com/cot> and install manually. You cannot use the previous one with CotEditor 2.2.0.
- Improve saving error dialog to display more detailed error reason.
- Avoid beeping on typing an unmatched `>` even if `<>` brace highlighting turned on.
- Update “Swift” syntax style:
    - Add new terms available in Swift 2.0.
- Improve contextual menu for theme/syntax style list on preferences.
- Tweak syntax style edit sheet layout.
- Remove sample scripts.
    - You can get them online on [Archives](http://coteditor.com/archives) page.
- Update documents.
- [beta] Improve side inspector switcher.


### Fixes

- Fix an issue where theme color was occasionally not applied to the preview in the print panel.
- Fix an issue on El Capitan where page guide was drawn at the wrong column.
- Fix an issue where the application crashed when typing a part of surrogate pair character.
- Fix an issue where invisibles which are a surrogate pair occasionally did not display.
- Fix an issue where the toolbar button state of the text orientation was not updated on window restoration.
- Fix help contents layout.
- [rc] Fix an issue where table headers had sometimes unwanted space around them on Yosemite and earlier.
- [rc] Fix an issue where calculation of hanging indent width was sometimes incorrect.
- [beta] Fix an issue where an unwanted migration window was displayed on the first launch even when there is nothing to be migrated.
- [beta] Fix an issue where the application could possibly crash on window restoration.
- [Non-AppStore ver.] Fix an issue where updater setting in the General pane did not display on OS X Mountain Lion and Mavericks.



2.2.0-rc (71)
--------------------------

### New Features

- Hanging indentation that enables inserting extra indent to wrapped lines.
    - You can change the behavior in Preferences > Edit.
- Add new normalization form “NFKC Casefold” to the Unicode normalization action in Utility menu (Thanks to doraTeX!)
    - It is also added to the AppleScript terms.
- Add German localization.


### Improvements

- Change the location where `cot` command-line tool is bundled from `CotEditor.app/Contents/MacOS/` to `CotEditor.app/Contents/SharedSupport/bin/`, due to Sandbox requirement.
    - Users who have already installed `cot` command need re-install it manually.
      You can re-install it running the command below on Terminal:

          unlink /usr/local/bin/cot; ln -s /Applications/CotEditor.app/Contents/SharedSupport/bin/cot /usr/local/bin/cot

      You may need to modify paths in this command depending on where you've installed CotEditor/cot.
- Improve Color Code Editor:
    - Add stylesheet keyword to color code type.
    - Add stylesheet keyword color list to editor panel.
    - Make editor panel resizable.
- Now syntax style is automatically set to “XML” on file opening if no appropriate style can be found but the file content starts with an XML declaration.
- Update word completion list setting in Edit pane in Preferences (The previous setting has been reset).
- Support “swipe to delete” for some tables in Preferences on El Capitan.
- Improve contextual menu for theme list on preferences.
- Adjust highlight color for find panel.
- Tweak some message terms.
- Update documents.
- Update build environment to OS X El Capitan + Xcode 7 (SDK 10.11).
- [non-AppStore ver.] Update Sparkle framework to version 1.11.0.
- [beta][non-AppStore ver.] Change to not check pre-release versions on default.
    - New pre-releases are always subject to the update check no matter the user setting if the current running CotEditor is a pre-release version.


### Fixes

- Fix an issue where the command-line tool could rarely not be installed from Integration pane.
- Fix an issue where the application could crash after when closing multiple split views.
- Fix an issue where the application crashed by clicking header of empty table in syntax editor sheet.
- Fix an issue where warning on Integration pane didn't disappear even after the problem resolved.
- Fix an issue where unwanted invisible character marks were drawn when tab drawing is turned off and other invisibles drawing is turned on.
- Add some missing localized strings in Japanese.
- [El Capitan] Fix an issue where color code view did not display on El Capitan.
- [beta] Fix an issue where the strings that were inserted via script or tools could be styled wrong.
- [beta] Fix an issue where no preferred extension was appended on the document save panel.
- [beta] Fix an issue where the bug report template was not syntax highlighted.
- [beta] Fix some trivial drawing issues on El Capitan.



2.2.0-beta
--------------------------

### New Features

- CotEditor is now __Sandboxed__.
- New setting option for the behavior on document modification by external process (in General pane).
- Share button in toolbar (Customize toolbar to use it).
- Save text orientation state to the file and restore it when the file is opened.
    - __for advanced users__: In this feature, CotEditor saves an *extended attribute* which named `com.coteditor.VerticalText` to the file *only when* the editor's text orientation is vertical. You can even disable the feature running the command `defaults write com.coteditor.CotEditor savesTextOrientation -bool NO` in Terminal.
- Line number view for vertical text orientation.
- Print with vertical text orientation.
- Add interpreter name list to the syntax style definition to determine syntax style from the shebang in the file content for in case when syntax style cannot be determined from the file name.
    - From this change, some of the bundled syntax styles are also updated.
- Add `encoding:` and `coding:` to the encoding declaration keywords which will be used on encoding auto-detection (interpreting priorities are: `charset=` > `encoding=` > `@charset` > `encoding:` > `coding:`).


### Improvements

- [non-AppStore ver.] Disable auto-update feature.
    - Since the Sparkle framework which is a software update framework we use doesn't support Sandboxed apps yet, the auto-update feature within CotEditor should be once disabled. The new behavior is: a notification window will be shown when a new release is available (as before), then you need to update CotEditor manually getting the new version from our web-site. Or, just migrate to the Mac App Store version when the stable CotEditor 2.2.0 is released.
- Deprecate the feature opening/saving files that user doesn't have the permission, due to Sandbox requirement.
- Improve side inspector UI.
- Improve syntax highlighting:
    - Optimize general syntax highlighting performance (ca. 1.8x).
    - Optimize syntax highlighting on file opening.
    - Better coloring parsing while editing.
    - Update all split editors while editing.
- Move scripts folder location from `~/Library/Application Support/CotEditor/ScriptMenu/` to `~/Library/Application Scripts/com.coteditor.CotEditor/` due of the Sandbox requirement.
    - Users need to migrate their script to the new folder manually since CotEditor doesn't have the write permission to the new location.
- Improve print document:
    - Update header/footer layout to conform to the standard system header/footer design.
    - Add page setup options to the print panel.
    - Print settings preset can be stored in the print panel.
- Better file encoding handling on revert action.
- Set access-group `com.coteditor.CotEditor.edit` to CotEditor's script definition.
- Change behavior to save `com.apple.TextEncoding` xattr on saving if the file had no content.
- Improve window restoration:
    - To restore also the last scroll position and cursor position.
    - To restore also the last syntax style mode of unsaved documents.
- Completely rewrite `cot` command-line tool:
    - Faster launch.
    - Make sure to launch CotEditor that invoked cot command includes.
- Optimize saving process.
- Improve compatibility with OS X 10.11 El Capitan.
- Change source code license from the GNU General Public License version 2 to the Apache License version 2.0.
- [non-AppStore ver.] Add option to check pre-release versions.


### Fixes

- Fix an issue where the full path display in the document inspector did not update after the document file moved.
- Fix an issue where the find panel could not find matched strings when the find string includes CR or CR/LF line endings.
- Fix an issue where line numbers were not drawn completely on OS X 10.8 when scroll bars are set as always shown.
- Fix an issue where some ligatured characters were drawn at a wrong position when the line height for composite font is fixed.
- Improve general stability.



2.1.6
--------------------------

### Fixes

- Improve stability on saving (Thanks to zom-san!).



2.1.5
--------------------------

### Fixes

- Fix an issue where auto-indent between curly brackets puts some spaces to a wrong place.



2.1.4
--------------------------

### New Features

- Importing theme files via drag-and-drop to theme list in preferences.


### Improvements

- Support displaying skin tone variations of Unicode 8.0 on the character inspector.
- Support Automatic Termination (Now, CotEditor can be terminated automatically if it has no window).
- Display invisible vertical tab (`U+000B`) with `␋` symbol if “Show other invisible characters” turns on.
- Add fancy animations to encoding list edit sheet in preferences.
- Add suppression button to the IANA charset name conflict alert.
- Improve word completion with words that exist in the document.
- Modify layout of “General” pane in Preferences.
- Add tooltip hint to controls in the find panel.
- Optimize image resources size.
- Update Sparkle framework to version 1.10.0.


### Fixes

- Address an issue where the application could hang up on document saving.
- Fix an issue where the autosaving could sometimes be disabled.
- Fix an issue where the layout of the text fields in the find panel could rarely be broken.
- Fix an issue where the auto-update notifier did not recognize a new stable version from specific beta version numbers.
- Fix an issue where some 3rd-party text editors for OS X cannot interpret files which were created by CotEditor.
- Fix an issue where an unwanted alert did show on the first save after reverting back.
- Fix an issue where selection after modifying sort of extension priority in syntax style edit sheet was wrong.
- Fix an issue where “Help” menu item duplicated in the menu bar on the second launch.
- Add some missing Localized strings in simplified Chinese. (Thanks to Wei Wang!)
- Improve general stability.



2.1.3
--------------------------

### Improvements

- Revert find panel behavior to select always whole text in find field when the panel is called.


### Fixes

- Fix line number drawing with large line numbers.
- Fix an issue where the external modification notification did not work.
- Improve general stability.



2.1.2
--------------------------

### Improvements

- Change place to create backup files (Now, backup files are always created in `~/Library/Autosave Information/`).
- Improve find panel:
    - Add scroll bars to the text fields.
    - Show invisible characters in text fields.
    - Now, “Swap Yen and backslash keys” option is also applied to the fields in the find panel.
    - Remove “Escape Character” option for regular expression search.
- Add “Cyrillic (Windows)” to the encoding list.
- Optimize launching speed of `cot` command-line tool.


### Fixes

- Fix an issue where the application could hang up on saving backup file.
- Fix an issue where unwanted find panel was shown when perform “Use Selection for Find” or “Use Selection for Replace” action.



2.1.1
--------------------------

### Fixes

- Fix an issue where octal file permission in the document inspector was wrong.
- Fix an issue where the application could hang up on text editing.
- Improve general stability.



2.1.0
--------------------------

### Improvements

- [beta] Add `--new` option to `cot` command-line tool.
- Update help contents.


### Fixes

- Fix an issue where some document icons were not applied under the specific environments.
- [rc.2] Fix an issue where syntax style was suddenly reset while editing on new document.
- [beta] Fix an issue where “Shift Left” action with whole text makes application hang up.
- [beta] Fix an issue where “Shift Right” action at blank line inserts unwanted indent to the next line.
- [beta] Fix an issue where split orientation setting was ignored.
- [beta] Fix an issue where text replacement could occasionally fail.
- [beta] Fix an issue where closed windows remained in memory.
- [beta] Fix an issue where the application hangs up on opening documents with the specific file name on Mountain Lion.
- [beta] Fix line number drawing with non-opaque view on Mountain Lion.



2.1.0-rc.2
--------------------------

### New Features

- Now your documents are automatically backed-up while editing and will be resumed at the next session, even after force quitting.
    - This feature doesn't modify your actual files. You still need to perform “Save” manually to apply changes to your files.


### Improvements

- [beta] add a missing localization in simplified Chinese. (Thanks to Wei Wang!)



2.1.0-rc
--------------------------

### Improvements

- Update Sparkle framework to version 1.9.0.
- [beta] close popover on clicking regex help button if it's already shown.


### Fixes

- Fix an issue where tab width on printing didn't reflect user indent setting.
- Fix an issue where tab width didn't update on font size change.
- [beta] Fix an issue where the application could crash on Mountain Lion.
- [beta] Fix an issue where `cot` command cannot be installed on Mavericks and earlier.
- [beta] Fix some layout issues on Mountain Lion.



2.1.0-beta.2
--------------------------

### Improvements

- Make key bindings for panel windows customizable.
- [beta] Enhance Find & Replace panel:
    - Revert “Highlight” button in find panel.
    - Remove “Replace & Find” button from find panel and add “Select Next Match after Replace” option.
    - Now, return with Shift key in find text field finds text backwards.
    - Always bring focus to the find text field when find panel is called.


### Fixes

- Fix an issue where the help button on Edit pane and Format pane didn't show correct help page.
- [beta] Fix an issue where `cot` command couldn't open relative path.
- [beta] Fix an issue where find panel could fail to set escape character.
- [beta] Fix an issue where find panel occasionally did not update setting of regex ability and syntax.



2.1.0-beta
--------------------------

### New Features

- `cot` command-line tool.
- New AppleScript property `tab width` for document object.
- Now, CotEditor script receives the absolute file path of the frontmost document as an argument if available.
- Add “New CotEditor Document with Selection” and “Open File in CotEditor” Services.
- Add syntax styles for “Erlang” and “Julia”.


### Improvements

- Drop support for __OS X Lion.__
- Migrate document drawer to sidebar style.
    - Add “show document inspector” option to preferences.
    - Improve document information display.
- Introduce brand-new find panel with more organized UI.
    - OniGmo is still be using for the regular expression engine as before.
    - Settings for find panel has been once reset. You can set them again from the gear button in the find panel.
- Enable to change multiple checkboxes in syntax style editor at once.
- Improve to display gear icon in menu bar while executing a script.
- Improve auto-outdent behavior with `}` input.
- Improve auto-tab-expand behavior with intent that tab characters and spaces are mixed.
- Add hidden “Reveal in Finder” menu item to syntax style action menu in Preferences (visible with `Option` key).
- Improve CotEditor Script to apply the result to the document that was frontmost when the script was launched.
- Close Preferences window with ESC key.
- Character inspector popover becomes detachable (on Yosemite and later).
- Update about Console Panel:
    - Rename “Script Error Panel” to “Console Panel.”
    - Change toolbar style.
    - Beautify output message style.
- Prefer using user custom syntax style if the file mapping conflicts with other bundled style.
- Change to save `com.apple.TextEncoding` xattr only if the file already has the encoding xattr or it's a new document.
- Move removed themes/styles to Trash instead delete them immediately.
- Now, Utility actions perform with multiple selections.
- Avoid showing not-writable alert on Resume again.
- Delay timing to save text key bindings setting.
- Localize document types.
- Improve text rendering with non-opaque view.
- Update “Markdown” syntax style:
    - Add horizontal rules to outline menu.
- Tweak text view drawing performance.


### Fixes

- Fix an issue that the preferred file encoding for encoding detection could be set wrong after running file open panel.
- Fix an issue that incompatible character markup positions were wrong by CR/LF line endings.
- Fix duplication check in key bindings editor.
- Fix “Restore Defaults” button ability on text key bindings edit sheet.
- Fix possible crashes on input.
- Fix an issue that application could crash after closing split view.
- Fix an issue that application could crash after switching theme in preferences.
- Fix an issue that application couldn't open file that is not Unicode, has more than 4,096 characters and consists only of 2-byte characters.
- Fix an issue that text font could occasionally change after pasting or inputting text from other application.
- Fix an issue that number of selected lines displayed less than actual count if last selected lines are blank.
- Fix an issue that Unicode character insertion was occasionally failed.
- Fix an issue that syntax highlights were removed after performing Unhighlight.
- Fix timing to display sheets on file open.
- Fix an issue that selection of line endings menu and encoding menu in toolbar did not update on undo/redo.
- Fix an issue where “Go To” dialog could duplicate and then most of the controls were disabled.
- Fix an issue that checkmark in line height menu was not displayed.
- Fix some missing localizations in simplified Chinese. (Thanks to Wei Wang!)
- Fix an issue that an alert message was not localized.
- And other trivial UI fixes and enhancements.



2.0.3
--------------------------

### New Features

- Add Chinese (Simplified) localization. (Thanks to Wei Wang!)
- Add feature to scale font size up by pinch gesture.


### Improvements

- Add “Traditional Chinese (Big 5 HKSCS)”, “Traditional Chinese (Big 5-E)” and “Traditional Chinese (Big 5)” to encoding list.
- Add “show invisible characters” option to set the visibility of all invisible character types at once.
    - From this, invisibles visibility of displayed windows can be toggled even all invisibles are hidden as default.
- Now, the popup menus in toolbar can be called directly even on “Text Only” mode without mode change.
- Now, window states will resume from the last session.
- Change default syntax style from “None” to “Plain Text”.
- Improve syntax highlighting performance.
- Remove delay when an AppleScript/JavaScript is run for the first time after application launch.
- Update “CSS” syntax style:
    - Add several keywords. (Thanks to Nathan Rutzky!)
- Update “JSON” syntax style:
    - Improve highlighting performance.
- Improve find panel behavior with Spaces.
- Disable rich text in find panel.


### Fixes

- Fix page guide position and tab width.
- Fix an issue that “Go” button in “Go To” sheet didn't work by clicking.
- Fix an issue that line endings menu in toolbar whose document had been newly created was always set to “LF”.
- Fix an issue that cancellation of syntax extracting didn't work immediately under the specific conditions.
- Fix an issue that selecting inside of brackets by double-clicking didn't work.
- Fix an issue that script execution with large size output could cause application hang up.
- Fix a possible issue that syntax highlighting while text editing could cause application crash.
- Fix an issue that application could hang up when no text font is found.
- Fix an issue that highlights weren't updated after “Replace All” under Japanese localization.
- Fix an issue that the Auto-Completion feature couldn't enable from the preferences under Japanese localization.



2.0.2
--------------------------

### Fixes

- Fix a critical issue that the application hang up if either file encoding or line endings is shown in status bar.



2.0.1
--------------------------

### New Features

- Introduce new AppleScript commands `comment out` and `uncomment` for selection object.
- Add “js“ extension to CotEditor script type.
    - __Hint__: Use `#!/usr/bin/osascript -l JavaScript` for shebang to run script as Yosemite's JavaScript for Automation.
- Add “Create Bug Report…” action to the Help menu.
- Add syntax style for “BibTeX”.


### Improvements

- Display an alert if the opening file is larger than 100 MB.
- Change the default value for “Comment always from line head” option to enable.
- Rename labels for line endings.
- Update “Python” syntax style:
    - Fix highlighting `print` command.
- Update “Ruby” syntax style:
    - Improve highlighting `%` literals.
- Update “R” syntax style:
    - Add file name `.Rprofile` to file mapping.
- Update “JavaScript” syntax style:
    - Highlight shebang as a comment.
- Update documents for scripting with AppleScript.
- Update sample scripts.
- Remove syntax style for “eRuby”.


### Fixes

- Fix an issue that new documents couldn't occasionally be saved with an extension that is automatically added from syntax definition.
- Fix an issue that the application could crash after closing split view.
- Fix an issue that some objects couldn't be handled via JavaScript for Automation on Yosemite.
- Fix an issue that syntax style validator didn't warn about keywords duplication that were newly added.
- Fix an issue that syntax style mapping conflict tables were always blank.
- Fix an issue that quoted texts and block comments at the end of document weren't highlighted.
- Fix an issue that text kerning was too narrow with non-antialiasing text (thanks to tsawada2-san).
- Fix an issue that text view scrolls to the opposite side when line number view is dragged.
- Fix an issue that `contents` of document property couldn't be set via AppleScript.
- Fix an issue that word selection didn't expand correctly under the specific conditions.
- Fix an issue that current line highlight didn't update after font size change.
- Fix an issue that navigation/status bars are shown for a moment on window creation even they are set as hidden.
- Fix an issue that newly added row in file drop setting occasionally disappear immediately.
- Fix some Japanese localizations.



2.0.0
--------------------------

### Improvements

- Rename “Spelling” menu item to “Spelling and Grammer” in Edit menu, and also add “Substitutions” and “Transformations” items
    - From this, remove “Uppercase”, “Lowercase” and “Capitalize” in “Utility” menu.
- Update “Apache” syntax style:
    - Indent outline items.
- Change not to include menu items that manage the script menu in the context menu.
- [beta] Change the line-up of substitute characters for full-width spaces.
- [beta] Add `public.text` to document types.
- [rc] And trivial aesthetic tweaks.


### Fixes

- Fix an issue that “Open a new document when CotEditor becomes active” option did not work correctly.
- Fix an issue that the encoding select in file open panel was ignored.
- [beta] Fix a possible issue that the Go To panel could open even no document window exists, and the application was going to hang after executing it.
- [beta] Fix an issue that disclosure icons in the menu key bindings editor disappeared rarely.
- [beta] Fix an issue that window objects were remain after closing windows.
- [beta] Fix an issue that text view expands/contracts occasionally on window resize.
- [beta] Fix an issue that the script icon in context menu was missing.
- [beta] Fix an issue that several UI in Japanese localization were displayed in Aqua Kana font.
- [rc] Fix an issue that line number view did occasionally not update after text editing.



2.0.0-rc
--------------------------

### New Features

- Add syntax styles for “Rust” and “Tcl”.


### Improvements

- Apply theme color to the line number view.
- Change the bundle identifier from `com.aynimac.CotEditor` to `com.coteditor.CotEditor`.
- Improve key bindings edit sheets.
- Update “YAML” syntax style:
    - Improve outline extracting rules.
- Deprecate “Drag selected text immediately” setting.
- Tweak result messages by syntax style validator and partially localized.
- Move version history from rich text format to one of the Help contents.
- Improve background drawing:
    - On Mountain Lion and later, scrolling performance on semi-transparent views has been improved.
    - On Mountain Lion and later, text view gets no drop-shadow by texts on semi-transparent.
- Avoid the move to previous outline item button to select the first “<Outilne Menu>” item.
- Deprecate text color setting for line number view which is hidden setting.
- Remove the output type keyword `Pasteboard puts` for CotEditor script, that was deprecated on CotEditor 0.7.2 and had remained for backwards compatibility.
- [beta] Display migration panel on the first launch.
- [beta] Improve launch speed.
- [beta] Tweak Japanese localization of preferences.
- [beta] Allow inputting non-roman characters on syntax style meta fields.
- [beta] Adjust layout of preferences.
- [beta] Adjust highlight color for incompatible chars.
- [beta] Adjust animation duration of toggling navigation bar and status bar.
- [beta] Brush up images.
- [beta] Update documents.


### Fixes

- Avoid horizontal scrollers on key bindings edit sheets.
- Fix help buttons on preferences panes.
- [beta] Fix an issue that semi-transparent text views flicked on scrolling on Yosemite.
- [beta] Avoid horizontal scrollers on syntax edit sheets in Japanese localization.
- [beta] Fix an issue that coloring label names were partially missing in syntax style validator.
- [beta] Fix syntax colorings of “Haskell”, “LaTeX” and “PHP” styles.
- [beta] Fill missing tooltips of some toolbar icons in the English localization.
- [beta] Fix a possible issue that syntax highlighting could not be updated after style edit.



2.0.0-beta.2
--------------------------

### Improvements

- Rename some labels in print setting.
- [beta] Update “AppleScript” syntax style:
    - Update commands that were changed on CotEditor 2.0.
- [beta] Tweak toolbar icons on preferences window.
- Tweak a label name in incompatible chars in Japanese.


### Fixes

- [beta] Fix an issue that some colors could not be edited in theme edit view under Japanese localization.
- [beta] Fix an issue that line wrap toggling behaves something strange if contents are short.
- [beta] Fix an issue that document info could not scroll.
- [beta] Fix an issue that contents of document info in drawer disappear on OS X Lion.



2.0.0-beta
--------------------------

### New Features

- Coloring theme feature.
- Comment toggling feature.
- Add “types”, “attributes” and “variables” to syntax highlighting colors.
- Now, syntax style can be determined not only from file extensions but also from filenames.
    - From this, rename “Extensions” in syntax edit sheet to “File Mapping”.
- Add metadata fields for syntax styles.
- Append a correspondent extension to the file name on saving.
    - The top extension in the extension list in the syntax style definition will be used.
    - From this, setting for “Append “txt” on saving” was deprecated.
        - If you want to keep using “txt” as default extension, set “Plain Text” syntax style as default style in Preferences > Format.
- Add “Toggle Text Orientation” icon to the toolbar.
- Add option to split views vertically.
- Select lines via clicking/dragging line numbers.
- Add “Select Line” command to “Edit” menu.
- Add syntax styles for “AppleScript”, “C#”, “Go”, “Lisp”, “Lua”, “R”, “Scheme”, “SQL”, “SVG” and “Swift”.
- Auto-complete feature (experimental implementation, turned off by default).


### Improvements

- Support OS X Yosemite.
- Update application icon with Yosemite style.
- New default coloring scheme.
- Improve performance drastically:
    - Extracting outline list on a background thread.
        - From this, non-response time till coloring indicator sheet has been shown reduced drastically.
        - Display message for outline extracting in navigation bar until the first extracting ends.
    - Perform extracting syntax highlights on a background thread.
    - Cache results of syntax highlighting, and use them as long as documents are not modified.
    - Improve cursor moving and file opening performance when the current line is highlighted.
    - Improve invisible chars drawing performance (4x faster).
    - Improve line number drawing performance (6x faster).
    - Improve scrolling on Mountain Lion and later.
    - For performance, change the range to scan encoding declaration up to 2,000 characters from the head of the document.
- Change syntax style file format from plist (XML) to YAML.
    - Legacy user styles will be migrated automatically on the first launch of CotEditor 2.0.
    - New user syntax style files are stored in `~/Library/Application Support/CotEditor/Syntaxes/`. The old styles are kept in `SyntaxColorings/`, since CotEditor 2.0 doesn’t use
- Now, IC (ignore case) can be set even RE (regular expression) is set in syntax style editing.
- Change regular expression engine to extract outlines from OniGmo (OgreKit) to ICU (NSRegularExpression).
    - Remove `$&` definition that represents a whole matched string (Use `$0` instead).
- Change tab width to 4 characters in the outline menu.
- Improve coloring indicator:
    - Improve to perform cancel button correctly.
    - On Mavericks and later, you can work with other documents while a coloring dialog is shown.
    - Display current task as a message in a sheet.
    - Change not to reset syntax style to “None” when the user cancels coloring.
    - Change not to remove current coloring when the user cancels coloring.
    - Cancel with ESC key.
- Define document types for CotEditor in more details and also add document icons for each.
- Scroll line by line with an arrow key.
- Adjust indent automatically on return just after `{` and `}` if Auto-Indent is on. (thanks to Naotaka-san).
- Update all of bundled syntax styles.
- Update “CSS” syntax style:
    - Support CSS level 3.
- Update “Perl” syntax style:
    - Add some keywords.
    - Add `=pod` and `=cut` to comment coloring.
    - Add “pm” to extensions.
- Update “JSON” syntax style:
    - Add “cottheme” to extensions.
- Update “LaTeX” syntax style:
    - Add “cls” and “sty” to extensions.
    - Update outline menu style.
- Update “YAML” syntax style:
    - Support YAML 1.2.
    - Some fixes.
- Update “Ruby” syntax style:
    - Support % notation.
    - Add special variables.
    - Improve number literals.
    - Support here document.
    - and some more fixes.
- Update “Java” syntax style:
    - Improve number literals.
    - Support annotation.
    - and some more fixes.
- Update “JavaScript” syntax style:
    - Completely rewrite.
- Update “Haskell” syntax style:
    - Improve number literals.
    - Add escape chars.
- Separate “DTD” (Document Type Declaration) syntax style from “XML”.
    - From this, coloring performance with “XML” syntax style was improved.
- Updates about scripting support:
    - Migrate AppleScript API definition file to sdef format.
    - Rename `unicode normalization` command to `normalize unicode`.
    - Update internal code for `range` property of `text selection` objects.
        - From this, your __compiled__ AppleScripts (.scpt) that contain `selection` handling need to be updated manually. See “Scripting with AppleScript” document in “Help” menu for details.
    - Update documents about scripting with AppleScript.
- Count characters by composed character sequence in the status bar and the info drawer.
        - The previous count was actually the length of the string in UTF-16 that is internal string expression on OS X (for example, a surrogate pair is counted previously as 2 and now as 1).
- Rename previous “Char Count” to “Char Length” and add another “Char Count” with the new count method for status bar items.
- Change key to display hidden menu items in “File” menu to “Option”.
- Add `.` and `:` to word separators that are used for selecting a word with a double click.
- Improve messages on character info inspector with surrogate pairs and variation selectors. (thanks to doraTeX-san)
- Disable alert asking for save when blank & unsaved document will be closed. (thanks to Naotaka-san)
- Brush up toolbar icons.
- Now, the font size of line numbers follows editor font size.
- Draw page guide in text color.
- Improve syntax editor sheet so as to edit documents even the sheet is shown. (on Mavericks and later)
- Improve application icon so as not to react with dropped folders.
- Improve cancellation behavior of word completion.
- Rename “Inspect Glyph” to “Inspect Character”.
- Delay timing to store user’s menu key bindings.
    - The user setting for menu key bindings on CotEditor 1.x will be reset on the first launch of v2.0.
- Change line hight value to line height based, that includes the hight of the line itself.
- Change the default line-height value to 1.3.
- Add thousand separators to values in document info.
- Change date format in document info drawer.
- Tweak status bar design.
- Add backquotes `\`` to quotation marks which are accommodated when color comments.
- Change Go To panel to a sheet.
- Add an animation when toggling the visibility of the navigation bar and the status bar.
- Fix used font for invisible characters.
- Update some of the alternative characters for full-width space char.
- Improve the appearance of the encoding list edit sheet.
- Improve window size setting fields in preferences to move fields with the tab key.
- Add hidden setting key `layoutTextVertical` (boolean) to set text orientation vertical as default.
- Deprecate font setting for navigation bar which is hidden setting.
- Update documents.
- Update Sparkle framework to 1.8.0.
- [dev] Update build environment to OS X Yosemite + Xcode 6.1 (SDK 10.10).


### Fixes

- Fix an issue that “Share find strings with other applications” option didn’t work.
- Fix an issue that comments weren’t highlighted correctly if another comment delimiter is contained in the string that is enclosed in quotes before the comment delimiter.
- Fix an issue that variation selectors, kind of invisible characters, disappeared occasionally.
- Fix an issue that encoding selection in toolbar was reset after changing of encoding list order.
- Fix over-wrapped text in the status bar to truncate with “…”.
- Fix an issue that unfocused windows performed also re-coloring after “Replace All”.
- Fix an issue that page guide was occasionally drawn at a wrong place if a fallback font is used.
- Fix to highlight current line only in focused view of split views.
- Fix an issue that text lines vibrated during moving caret if text orientation is vertical and line height is fixed.
- Fix an issue that line numbers in unfocused views were not updated.
- Fix an issue that lately added toolbar icons didn’t represent the state at the moment.
- Fix an issue that an error was output in the console if the blank area of incompatible chars table was clicked.
- Fix an issue that editors didn’t change to transparent if the opacity setting in preferences window was changed from 100%.
- Fix an issue that changes in the custom line height panel wasn’t applied immediately.
- Fix an issue that “Same as Document” selection for invisible chars in print panel didn’t work correctly.
- Fix an issue that line count got one more extra if the selection contains return at the end.
- Fix an issue that `range` property of `text selection` objects was displayed as wrong `character range` on AppleScript Editor.
- Fix some sample scripts which didn’t run correctly.
- Fix an issue that some settings did not display in Preferences on OS X Lion.
