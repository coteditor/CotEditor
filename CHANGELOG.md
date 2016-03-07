
Change Log
==========================

develop
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


### Fixes

- Fix an issue where “Delimit by whitespace” option on text find didn't work.
- Fix an issue where some document file information displayed wrong after saving.
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
    - Fix an issue where command cannot open file whose path includes non-ascii character.
    - Fix an issue where `--line` option didn't work under specific environments.
    - Fix an issue where `--line` and `--column` options didn't move cursor to the desired location if file has blank lines at the end.
- Now, the change of “link URL” option is applied to opened documents immediately.


### Fix

- Fix an issue where documents were marked as “Edited” just after opening file if “link URL” option is enabled.
- Fix an issue where URL link was not applied to pasted text.
- Fix an issue where find-all highlight wasn't removed if find panel is closed before closing find result view.
- Fix an issue where toggling invisible visibility didn't work correctly.
- Fix an issue where the cursor located at the end of document after file opening.
- Fix an issue where thousands separators weren't inserted to document information under specific enviroments.
- Address an issue where paste was rarely failed under specific enviroments.



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
    - Display total number of found in find panel on simple find actions.
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
- Move some options position within “General” pane and “Edit” pane in preferences window.
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
- Fix an issue where “Jump to Selection” action didn't jump to selection in editor if other text box is focused.
- Fix an issue where some table cells didn't change their text color when selected.
- Fix tiny memory leaks.



2.3.4 (95)
--------------------------

### Improvements

- Improve line numbers view for multiple selections.
- Now, “Select Line” action works with multiple selections.
- Close character inspector when text selection was changed.
- Reprocude previous selection by undoing line actions.
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
    - Avoid auto-closing panel after enter character.
- Improve character inspector:
    - Display more comprehensible name for control characters (e.g. `<control-0000>` to `NULL`).
    - Display a alternate visible symbol in the zoomed character area for C0 control characters.
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
- Revert style of popup menus in toolbar on Marvericks and earlier.
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
- Fix an issue where panels could lost target document.
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
    - Display unicode names of each character if selected letter consist of multiple characters.
    - Fix drawing area of zoomed character view.
    - Fix some other trivial issues.
- Add option to suppress “not writable document” alert.
- Improve text selection by clicking line numbers view.
- Tweak style of popup menus in toolbar.
- Add “description” field that doesn't affect to highlighting but for commenting for each term to the syntax style and syntax style editor.
- Add Swite to Delete action on El Capitan to tables in syntax style editor.
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
- Fix an issue where application could crash if the width of line number view will change.



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

- Fix an issue where application could be launched on unsupported system versions.
- Fix an issue where the baseline of new line invisible characters was wrong if line is empty.
- Address an issue where syntax highlighted control character was sometime not colored in the invisible color.
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
- Temporary hide the “Live Update” checkbox in the find panel since this feature by OgreKit framework has actually not worked correctly in the latest versions.
- Update Onigmo regular expression engine to 5.15.0.


### Fixes

- Fix an issue where no file path was inserted if file type of the dropped file was not registered to the file drop setting.
- Address syntax highlighting issue with multiple lines.
- Fix an issue where text view drawing was distorted while resizing window.
- Fix an issue where application could crash on window restoration.
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

- Fix an issue where the baseline of invisible characters were wrong by some fonts.
- Fix an issue where application could crash after modifying theme name on El Capitan.
- Fix an issue where submenu disclosure arrows in the menu key binding editor did occasionally disappear.
- Fix timing to update search string to system-wide shared find string.
- Fix an issue under the specific conditions where the migration window showed up every time on launch.



2.2.1 (75)
--------------------------

### Fixes

- Fix an issue where application could crash on typing Japanese text if hanging indentation is enabled.



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
    - To use `cot` command with CotEditor 2.2.0 and later, download it from <http://coteditor.com/cot> and install manually. You cannnot use the previous one with CotEditor 2.2.0.
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
- Fix an issue where application crashed when type a part of surrogate pair character.
- Fix an issue where invisibles which are a surrogate pair occasionally did not display.
- Fix an issue where the toolbar button state of the text orientation was not updated on window restoration.
- Fix help contents layout.
- [rc] Fix an issue where table headers had sometime unwanted space around them on Yosemite and ealier.
- [rc] Fix an issue where calculation of hanging indent width was sometime incorrect.
- [beta] Fix an issue where an unwanted migration window was displayed on the first launch even when there is nothing to be migrated.
- [beta] Fix an issue where application could possibly crash on window restoration.
- [Non-AppStore ver.] Fix an issue where updater setting in the General pane did not displayed on OS X Mountain Lion and Mavericks.



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
- Now syntax style is automatically set to “XML” on file opening if no appropriate style can be found but the file content starts with a XML declaration.
- Update word completion list setting in Edit pane in Preferences (The previous setting has been reset).
- Support “swipe to delete” for some tables in Preferences on El Capitan.
- Improve contextual menu for theme list on preferences.
- Adjust highlight color for find panel.
- Tweak some message terms.
- Update documents.
- Update build environment to OS X El Capitan +  Xcode 7 (SDK 10.11).
- [non-AppStore ver.] Update Sparkle framework to version 1.11.0.
- [beta][non-AppStore ver.] Change to not check pre-release versions on default.
    - New pre-releases are always subject of the update check no matter the user setting if the current running CotEditor is a pre-release version.


### Fixes

- Fix an issue where the command-line tool could rarely not be installed from Integration pane.
- Fix an issue where application could crash after when closing multiple split views.
- Fix an issue where application crashed by clicking header of empty table in syntax editor sheet.
- Fix an issue where warning on Integration pane didn't disappear even after the problem resolved.
- Fix an issue where unwanted invisible character mark were drawn when tab drawing is turned off and other invisibles drawing is truned on. 
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
    - Since the Sparkle framework which is a software update framework we use doesn't support Sandboxed apps yet, the auto-update feature within CotEditor should be once disabled. The new behavior is: a nofitication window will be shown when a new release is available (as before), then you need to update CotEditor manually getting the new version from our web-site. Or, just migrate to the Mac App Store version when the stable CotEditor 2.2.0 is released.
- Deprecate the feature opening/saving files that user doesn't have the permission, due to Sandbox requirement.
- Improve side inspector UI.
- Improve syntax highlighting:
    - Optimize general syntax highlighting performance (ca. 1.8x).
    - Optimize syntax highlighting on file opening.
    - Better coloring parsing while editing.
    - Update all split editors while editing.
- Move scripts folder location from `~/Library/Application Support/CotEditor/ScriptMenu/` to `~/Library/Application Scripts/com.coteditor.CotEditor/` due of the Sandbox requirement.
    - Users need to migrate their script to the new folder manually, since CotEditor doesn't have the write permission to the new location.
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
- Fix an issue where the autosaving could sometime be disabled.
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

- Fix an issue where application could hang up on saving backup file.
- Fix an issue where unwanted find panel was shown when perform “Use Selection for Find” or “Use Selection for Replace” action.



2.1.1
--------------------------

### Fixes

- Fix an issue where octal file permission in the document inspector was wrong.
- Fix an issue where application could hang up on text editing.
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
- [beta] Fix an issue where application hang up on opening documents with specific file name on Mountain Lion.
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
- [beta] Fix an issue where `cot` command cannot be insalled on Mavericks and earlier.
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
- [beta] Fix an issue where find panel occasionally did not update setting of regex enability and syntax.



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
- Close Preferences window with esc key.
- Character inspector popover becomes detachable (on Yosemite and later).
- Update about Console Panel:
    - Rename “Script Error Panel” to “Console Panel.”
    - Change toolbar style.
    - Beautify output message style.
- Prefer using user custom syntax style if the file mapping conflicts with other bundled style.
- Change to save `com.apple.TextEncoding` xattr only if the file already has the encoding xattr or it's a new document.
- Move removed themes/styles to Trash instead delete them immediately.
- Now, Utility actions perform with multiple selection.
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
- Fix “Restore Defaults” button enability on text key bindings edit sheet.
- Fix possible crashes on input.
- Fix an issue that application could crash after closing split view.
- Fix an issue that application could crash after switching theme in preferences.
- Fix an issue that application couldn't open file that is not Unicode, has more than 4,096 characters and consists only of 2 byte characters.
- Fix an issue that text font could occasionally change after pasting or inputting text from other application.
- Fix an issue that number of selected lines displayed less than actual count if last selected lines are blank.
- Fix an issue that Unicode character insertion was occasionally failed.
- Fix an issue that syntax highlights were removed after perform Unhighlight.
- Fix timing to display sheets on file open.
- Fix an issue that selection of line endings menu and encoding menu in toolbar did not update on undo/redo.
- Fix an issue where “Go To” dialog could duplicate and then most of controls were disabled.
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
- Add “show invisible characters” option to set visibility of all invisible character types at once.
    - From this, invisibles visibility of displayed windows can be toggled even all invisibles are hidden as default.
- Now, the popup menus in toolbar can be called directly even on “Text Only” mode without mode change.
- Now, window states will resume from the last session.
- Change default syntax style from “None” to “Plain Text”.
- Improve syntax highlighting performance.
- Remove delay when a AppleScript/JavaScript is run for the first time after application launch.
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
- Fix an issue that cancelation of syntax extracting didn't work immediately under the specific conditions.
- Fix an issue that selecting inside of brackets by double-clicking didn't work.
- Fix an issue that script execution with large size output could cause application hang up.
- Fix a possible issue that syntax highlighting while text editing chould cause application crash.
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
- Change default value for “Comment always from line head” option to enable.
- Rename labels for line endings.
- Update “Python” syntax style:
    - Fix highlighting `print` command.
- Update “Ruby” syntax style:
    - Improve highlighting `%` literals.
- Update “R” syntax style:
    - Add file name `.Rprofile` to file mapping.
- Update “JavaScript” syntax style:
    - Highlight shebang as comment.
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
- Fix an issue that `contents` of document property could’t be set via AppleScript.
- Fix an issue that word selection didn't expand correctly under the specific conditions.
- Fix an issue that current line highlight didn't update after font size change.
- Fix an issue that navigation/status bars are shown for a moment on window creation even they are set as hidden.
- Fix an issue that new added row in file drop setting occasionally disappear immediately.
- Fix some Japanese localizations.



2.0.0
--------------------------

### Improvements

- 「編集」メニューの項目「スペル」を「スペルと文法」に変更し、さらに「自動変換」と「変換」機能を追加
    - これにともない、「ユーティリティ」メニュー内の「大文字に」、「小文字に」、「先頭の文字を大文字に」を削除
- “Apache” シンタックス定義の更新
    - アウトラインをインデントで階層化
- コンテキストメニューのスクリプトメニューにはスクリプト管理のための項目を含めないように変更
- [beta] 全角空白の不可視文字代替文字を一部変更
- [beta] 書類タイプに public.text を追加
- [rc] ほか、見た目の微調整


### Fixes

- 「CotEditor がアクティブになるとき新規書類を開く」オプションが正しく機能していなかった不具合を修正
- ファイルオープンパネルでのエンコーディング選択が無視されていた不具合を修正
- [beta] ウインドウがない状態で「移動」パネルが開けることがあり、実行すると以降ほかのコマンドを受け付けなくなる不具合を修正
- [beta] メニューキーバインド編集のアウトライン展開アイコンが表示されないことがある不具合を修正
- [beta] ウインドウが閉じたあともウインドウオブジェクトが残っていた不具合を修正
- [beta] ビューが不透明のとき、ウインドウリサイズ時にテキストビューが伸び縮みすることがある不具合を修正
- [beta] コンテキストメニュー内のスクリプトメニューのスクリプトアイコンが表示されていなかった不具合を修正
- [beta] 日本語環境で一部 UI のフォントが Aqua カナになっていた不具合を修正
- [rc] テキスト編集時に行番号ビューが更新されないことがある不具合を修正



2.0.0-rc
--------------------------

### New Features

- “Rust”, “Tcl” シンタックス定義を追加


### Improvements

- 行番号ビューの色がテーマカラーを反映したものになるように改良
- アプリケーション識別子 (bundle identifier) を `com.aynimac.CotEditor` から `com.coteditor.CotEditor` へ変更
- キーバインディングの編集方法と解説を変更
- “YAML” シンタックス定義の更新
    - アウトラインの抽出ルールを変更
- 設定項目 “選択テキストをすぐにドラッグ開始” を廃止
- シンタックススタイルの検証結果メッセージを調整し、一部日本語化
- バージョン履歴をリッチテキストファイルからヘルプ内へ移動
- 背景色の描画方法を変更:
    - Mountain Lion 以降で背景半透明時のスクロールのもたつきを改善
    - Mountain Lion 以降で背景半透明時に文字のドロップシャドウが落ちないように変更
- アウトラインの前後移動ボタンで最初の “<アウトラインメニュー>” 項目には遡らないように変更
- 隠し設定である行番号ビューの文字色設定を廃止
- CotEditor 0.7.2 で廃止され後方互換性のために残されていた、CotEditor スクリプトの出力タイプ指定キーワード `Pasteboard puts` を正式に廃止
- [beta] 2.0 初回起動時に移行ウインドウを表示
- [beta] 起動スピードの改善
- [beta] 環境設定の「つねに行頭からコメントアウト」する設定項目のラベルを変更
- [beta] シンタックス定義のメタデータ入力欄でローマ字以外の IM での入力を許可
- [beta] 環境設定のウインドウ透明度のスライダに注意事項を追加
- [beta] エンコーディング編集シートのレイアウトを調整
- [beta] 非互換文字のハイライトカラーを調整
- [beta] カラーリングインジケータが出る条件を調整
- [beta] ナビゲーションバー／ステータスバーの表示切り替え時のアニメーション時間を調整
- [beta] 画像の調整
- [beta] ドキュメントの更新


### Fixes

- キーバインド編集シートで横スクロールの発生を抑止
- 環境設定ウインドウのヘルプボタンから該当するヘルプページが開かなかった不具合を修正
- [beta] Yosemite 上でビューを半透明にした時にスクロール時に背景がチラつく不具合を修正
- [beta] 日本語環境でのシンタックススタイル編集シートで横スクロールの発生を抑止
- [beta] シンタックス定義の検証でカラーリング名の後半が欠落する不具合を修正
- [beta] “Haskell”, “LaTeX”, “PHP” シンタックス定義のカラーリングを修正
- [beta] 英語環境で書類ウインドウのツールバーアイコンのツールチップが一部なかった不具合を修正
- [beta] シンタックス定義を編集した後、すでに開いている書類のカラーリングが更新されないことがある不具合を修正



2.0.0-beta.2
--------------------------

### Improvements

- プリント設定のラベルを一部変更
- [beta] “AppleScript” シンタックス定義の更新
    - CotEditor 2.0 で変更になった CotEditor コマンドを更新
- [beta] 環境設定のツールバーアイコンを調整
- 非互換文字リストのラベル文字列を変更


### Fixes

- [beta] 日本語環境でテーマの一部の色が編集できなかった不具合を修正
- [beta] 特定の条件下で折り返しの切り替えをするとレイアウトが崩れる不具合を修正
- [beta] ドロワー内の書類情報に隠れている部分があるときにスクロールできない不具合を修正
- [beta] OS X Lion においてドロワー内の文書情報が表示されない不具合を修正



2.0.0-beta
--------------------------

### New Features

- テーマ機能
- コメントアウト/コメント解除機能
- シンタックス定義に新しい色 “タイプ”, “属性”, “変数” を追加
- シンタックス定義にファイル名の設定を追加
    - これにともない、シンタックス編集シートでの表記を「拡張子」(Extensions) から「ファイル関連付け」(File Mapping) に変更
- シンタックス定義にスタイル情報欄を追加
- ファイル保存時にシンタックスに応じた拡張子を追加
    - シンタックス定義内の拡張子リストの最上位にある拡張子が使用されます。
    - これにともない、以前まであった「ファイル保存時に拡張子“txt”をつける」オプションは廃止になりました。
        - 引き続き拡張子 “txt” を自動的に追加したい場合は、環境設定 > フォーマットのデフォルトシンタックススタイルを“Plain Text”にすることで同様の効果を得られます。
- 横書き／縦書き切り替えボタンをツールバーに追加
- エディタを縦に分割するオプション
- 行番号をクリック／ドラッグして行を選択
- 「編集」に「行を選択」コマンドを追加
- “AppleScript”, “C#”, “Go”, “Lisp”, “Lua”, “R”, “Scheme”, “SQL”, “SVG”, “Swift” シンタックス定義を追加
- 自動補完機能を追加（実験的実装, デフォルトはオフ）


### Improvements

- OS X Yosemite に対応
- Yosemite スタイルの新しいアプリケーションアイコン
- 新しいデフォルトシンタックスカラーリング配色
- パフォーマンスの大幅な改善
    - アウトラインの抽出をバックグラウンドスレッドで行うように変更
        - これにより、巨大なファイルをオープンした際のカラーリングインジケータダイアログが出るまでのアプリケーション無反応時間を大幅に削減
        - 初回の抽出が終わるまではナビゲーションバーにスピンインジケータと抽出中である旨のメッセージを表示するようにした (2回目以降の更新時は表示をしない)
    - シンタックスカラーリングの抽出をバックグラウンドスレッドで行うように変更
    - シンタックスカラーリング抽出結果をキャッシュし、文書内容に変更がない場合は再カラーリング時にキャッシュを用いるよう変更
    - 現在行をハイライトしているときのファイルオープンおよびカーソル移動のパフォーマンスを大幅に改善
    - 不可視文字描画のパフォーマンスを大幅に改善 (約4倍)
    - 行番号表示のパフォーマンスを大幅に改善 (約6倍)
    - Mountain Lion 以降のビュー不透明時および、Yosemite 以降でスクロールのもたつきを改善 
    - ファイルオープンの高速化のため、エンコーディング宣言の走査を文書前方2,000文字のみに制限
- シンタックス定義ファイルのフォーマットを plist (XML) から YAML に変更
    - ユーザのカスタム定義の移行は、初回 CotEditor 2.0 起動時に自動で行なわれます。
    - 新しい形式の定義ファイルは `~/Library/Application Support/CotEditor/Syntaxes/` に保存されます。以前の plist 形式の定義ファイルは `SyntaxColorings/` ファイルに残されたままになりますが CotEditor 2.0 はこれを使用しないので、必要なければ削除しても構いません。 
- シンタックス定義で RE (正規表現) を無効にしていても IC (大文字小文字を無視) を有効にできるように変更
- アウトライン抽出に用いる正規表現ライブラリを OniGmo (OgreKit) から ICU (NSRegularExpression) に変更
    - マッチした文字列全体を表す `$&` 定義の削除（代わりに `$0` を使ってください）
- アウトラインメニューでのタブ幅をスペース4個分に変更
- カラーリングインジケータダイアログの改良：
    - キャンセルボタンが正しく反応するように改善
    - Mavericks 以降ではダイアログ表示中でも他ファイルの操作ができるように改善
    - ダイアログに現在行なっている作業を表示するように改善
    - 途中でキャンセルした際に書類のシンタックス設定が「なし」にならないように変更
    - 途中でキャンセルした際に現在のカラーリングを破棄しないように変更
    - esc キーでもカラーリングをキャンセルできるように変更
- 文書定義と書類アイコンを追加し、CotEditorと関連づけられた書類のアイコンと種類がよりファイルを反映したものになるようにした
- エディタ内で矢印キーでカーソル移動をしたときのスクロール幅を1行ずつに変更
- 自動インデントが有効なときは、 `{` または `}` 直後の改行でインデントの対応を取るように改善 (Naotaka さんに感謝！)
- シンタックス定義フォーマットの変更に対応するための、すべてのバンドル版シンタックス定義の更新
- “CSS” シンタックス定義の更新
    - CSS3 に対応
- “Perl” シンタックス定義の更新
    - いくつかのキーワードを追加
    - `=pod`, `=cut` をコメントカラーリングに追加
    - 拡張子に “pm” を追加
- “JSON” シンタックス定義の更新
    - 拡張子に “cottheme” を追加
- “LaTeX” シンタックス定義の更新
    - 拡張子に “cls”, “sty” を追加
    - アウトラインメニューの階層表示スタイルを変更
- “YAML” シンタックス定義の更新
    - YAML 1.2 に対応
    - ほか、いくつかの修正
- “Ruby” シンタックス定義の更新
    - %記法に対応
    - 特殊変数を追加
    - 数値の抽出条件を改良
    - ヒアドキュメントに対応
    - ほか、いくつかの修正
- “Java” シンタックス定義の更新
    - 数値の抽出条件を改良
    - アノテーションに対応
    - ほか、いくつかの修正
- “JavaScript” シンタックス定義の更新
    - リライト
- “Haskell” シンタックス定義の更新
    - 数値の抽出条件を改良
    - エスケープ文字を追加
- “DTD” (文書型定義) シンタックス定義 を “XML” シンタックス定義から分離
    - これにより、“XML” シンタックス定義のカラーリングパフォーマンスを改善
- AppleScript 対応に関する変更：
    - AppleScript コマンドの定義ファイルを sdef 形式に移行
    - コマンド `unicode normalization` を `normalize unicode` に変更
    - `selection` オブジェクトの `range` プロパティのための内部コードを変更
        - これにともない、selection の操作が含まれかつ __コンパイルされている__ AppleScript (.scpt) は、修正が必要となります。詳しくはヘルプメニュー内の「AppleScript でのスクリプト作成」をご覧下さい。
    - AppleScript に関わるドキュメントの更新
- ステータスバーおよび情報ドロワーの文字数カウントを composed character 単位に変更
    - 従来の文字数カウントは愚直にUTF-16 (= OS Xでの文字列内部表現) での length を表示するのに対して、新しいカウント法は表示される文字単位でカウントを行なう（例えば、絵文字などのサロゲートペアは文字数:1, 文字長:2となる）
    - 過去の「文字数」については「文字長」という名前に改名し「文字数」とは別に項目を設けた
- 「ファイル」メニューの隠しメニュー「非表示ファイルを開く…」と「すべてを閉じる」を表示するキーを Option に変更
- ダブルクリックでの単語選択時の区切り文字に `.` と `:` を追加
- 文字情報ポップアップでのサロゲートペアおよび Variation Selector の扱いを改善 (doraTeX さんに感謝！)
- 未保存で空のドキュメントを閉じるときに保存するかを問うアラートを出さないように変更 (Naotaka さんに感謝！)
- ツールバーアイコンを改良
- 行番号の文字サイズがエディタの文字サイズに追従するように変更
- ページガイド線の生成方法を変更し、線は設定したテキストカラーと同色で描画
- シンタックススタイル編集シートを表示中でも書類の編集ができるように変更 (Mavericks 以降)
- アプリケーションアイコンがフォルダのドラッグ&ドロップに反応しないように変更
- 入力補完キャンセル時の挙動を改善
- 「グリフ情報を表示」を「文字情報を表示」に改名
- メニューキーバインドのユーザ設定を保存するタイミングを設定を変更したときまで遅延し、カスタマイズしていないときは常にアプリケーションの最新のデフォルト値を用いるように変更
    - CotEditot 1.x での設定は一度リセットされます。
- 行間設定を行の高さ（行そのものを含む値）ベースに変更
- 行の高さのデフォルト値を 1.3 に変更
- 情報ドロワーの数値に桁区切り（カンマ）を入れるように変更
- 情報ドロワーの日時のフォーマットを変更
- ステータスバーの表示スタイルを調整
- シンタックスカラーリングでコメントと勘案してカラーリング処理をするクオート文字に `\`` を追加
- 移動パネルをシートに変更
- ステータスバーとナビゲーションバーのトグルにアニメーション効果を追加
- 不可視文字を描画するフォントを固定
- 不可視文字の選択肢を一部変更
- エンコーディング編集シートの表示を改良
- 環境設定のウインドウサイズ入力欄をタブキーで移動できるように改良
- デフォルト表示を縦書きにする隠し設定 `layoutTextVertical` を追加
- 隠し設定であるナビゲーションバーのフォント設定を廃止
- ドキュメントの更新
- Sparkle framework を 1.8.0 に更新
- ビルド環境を OS X Yosemite + Xcode 6.1 (SDK 10.10) に変更
- ほか、内部コードの変更


### Fixes

- 「検索文字列をほかのアプリケーションと共有」オプションが有効にならない不具合を修正
- 引用符で囲まれた文字列内にコメント開始記号がある場合、同行内で引用符外にコメントがあってもカラーリングされない不具合を修正
- 不可視制御文字 Variation Selector の表示が消えることがある不具合を修正
- エンコーディングの順序を変更したときにツールバーの選択がリセットされる不具合を修正
- ステータスバーの情報がウインドウ幅からあふれるとき、左右の文字が重なっていたのを「…」で省略されるように修正
- テキストの全文置換後に置換対象でないウインドウも再カラーリングが実行される不具合を修正
- 日本語を持たないフォントで日本語を入力したときになど表示フォントが混合した際にページガイドが誤った位置に描画されることがある不具合を修正
- ビューを分割しているとき、現在行ハイライトが編集中のビューのみに表示されるように修正
- 縦書きで行間を固定し現在行をハイライトしているとき、キャレットを移動すると行が微動することがある不具合を修正
- テキストを編集したとき、フォーカスのある分割エディタ以外の行番号が更新されない不具合を修正
- ツールバーアイコンを後から追加したときに、追加されたアイコンがそのウインドウの状態を反映していない不具合を修正
- 非互換文字リストの空欄をクリックするとコンソールにエラーログが吐かれる不具合を修正
- ウインドウが開いた状態で環境設定からビューの不透明度を100%から下げると既出のウインドウの背景が透けない不具合を修正
- カスタム行間設定パネルからの入力が即座に反映されない不具合を修正
- プリント時の不可視文字設定「書類の設定と同じ」が書類の設定を反映しない不具合を修正
- 選択範囲の最後に改行を含むとき、選択行数が1行多く表示される不具合を修正
- AppleScript Editor から `selection` オブジェクトのプロパティを見たときに `range` プロパティの名前が `character range` と表示される不具合を修正
- 正しく実行できなかったいくつかのサンプルスクリプトを修正
- OS X Lion において、環境設定のいくつかの設定項目が非表示になっていた不具合を修正

