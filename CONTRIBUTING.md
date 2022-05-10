
Contributing Guidelines
==========================

General Feedback
--------------------------

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). You can write your feedback either in English (recommended) or in Japanese.

Bug reports __must__ include your environment. You can generate a bug report template automatically in CotEditor selecting "Help" > "Create Bug Report…" in the menu.



Pull-Request
--------------------------

- Make a topic branch, instead of committing to the master or develop branch.


### General Code Improvements

Bug fixes and improvements are welcome. If you want to add a new feature or the change is huge, it's better at first to ask the team whether your idea will be accepted.

By adding code, please follow our coding style guide below.


### Localization

Fixing/updating existing localizations is always welcome. The project team adds `FIXME:` tag as a comment in the localized strings files if there are updated strings to be localized.

If your localization makes the Autolayout destroy, try first making the sentence shorter. However, if it's impossible, then just tell us about it with a screenshot when you make a pull-request. We'll update the storyboard file to layout your localized terms correctly.

#### Good references for localization

By localization, use macOS standard terms. It might be helpful to study native Apple applications like TextEdit.app or System Preferences to know how Apple localizes terms in their apps.

Especially, follow the terms of the following applications.

- Menu item titles in TextEdit.app
- Find panel in Pages.app
- Some setting messages in ScriptEditor.app

We recommend to utilize [Apple Localization Terms Glossary for macOS](https://applelocalization.com/macos) by Kishikawa Katsumi to find macOS-friendly expressions.
You also need to take care of how Apple handles punctuation characters and symbols. Regarding quotation marks, they normally prefer the typographer's ones.


#### Submitting a new localization

Copy one of a whole .lproj directory and use it as a template. We recommend using `CotEditor/ja.lproj/` or `CotEditor/en-GB.lproj/` directory because they are always up-to-date and well organized.
Note that you don't need to localize the Unicode block names in the `Unicode.strings` file.

Continuous maintenance of the localization is highly recommended when providing a new localization. Please tell us if you can work with us. We'll call you every time before releasing a new version when we have new strings to be localized, so that you can keep all your localized strings up to date.
Currently, we already have maintainers for:

- Japanese
- Simplified Chinese
- Traditional Chinese
- Italian
- French
- Turkish
- English (UK)

#### Localization for App Store

CotEditor project is also asking for localization of description on the Mac App Store. We have a separate repository for it at [coteditor/Documents-for-AppStore](https://github.com/coteditor/Documents-for-AppStore).


### Syntax Styles

#### Adding a new bundled syntax style

Put just your new syntax style into `/CotEditor/syntaxes/` directory. You don't need to modify `SyntaxMap.json` file. It's generated automatically on the build.

The license for the bundled syntax styles should be "Same as CotEditor".

If the syntax language is relatively minor, we recommend you to distribute it as an additional syntax style by your own way, and just add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Syntax-Styles).


### Themes

We aren't accepting pull-requests adding bundled theme at the moment. You can distribute yours as an additional theme by your own way, and add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Themes).


### Graphics Resources

We don't accept pull-requests for image resources. [1024jp](https://github.com/1024jp) enjoys creating and brushing up the graphics ;). Please just point out on the Issues page if a graphic resource has some kind of mistake to be fixed.


Coding Style Guide
--------------------------

Please follow the style of the existing codes in CotEditor.

- Respect the existing coding style.
- Leave reasonable comments.
- Never omit `self`.
- Add `final` to classes by default.
- Insert a blank line after class/function statement line.
	```Swift
	/// say moof.
	func moof() {
		
		print("moof")
	}
	```
- Don't declare `@IBOutlet` properties with `!`.
	```Swift
    // OK
    @IBOutlet private weak var button: NSButton?
    
    // NG
    @IBOutlet private weak var button: NSButton!
	```
- Write `guard` statement in one-line if just return a simple value.
	```Swift
    // prefer
    guard let foo = foo else { return nil }
    
    // instead of
    guard let foo = foo else {
        return nil
    }
	```
