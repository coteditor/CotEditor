# Contributing Guidelines

## General Feedback

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). You can write your feedback either in English (recommended) or in Japanese.


### Issue reports

Search for existing issues first. If you find your issue previously reported, post your case to that issue; otherwise, create a new one by filling up the “Bug report” template. Do not hesitate to post the same phenomenon to the existing issue as long as the cases are less than 10. Multiple instances help a lot to find out the cause. In that situation, include your environment (versions of both CotEditor and macOS) in your post.

If possible, attach screenshots/screencasts of the issue you face. It is also helpful to attach sample files that can reproduce the issue.

If your issue relates to the syntax highlight, include the sample code that can reproduce the unwanted highlight in your post.


### Feature requests

Search for existing requests first. If you find your feature previously requested, post your comment to that issue; otherwise, create a new one by filling up the “Feature request” template.
Create an issue per feature instead of listing multiple features in a single post.



## Pull-Request

### General Code Improvements

Bug fixes and improvements are welcome. If you want to add a new feature or the change is huge, it's better at first to ask the team whether your idea will be accepted.

By adding code, please follow our coding style guide below.


### Localization

Fixing/updating existing localizations is always welcome. See each .xcstrings file to find which strings need to be localized or reviewed by native speaker. By localization, please refer to the comments and key naming so that you can know where and how each string will be used. If you have uncertainty, feel free to ask @1024jp.

If your localization makes some layout in views destroy, try first making the sentence shorter. However, if it's impossible, then just tell us about it with a screenshot when you make a pull-request. We'll update the view to layout your localized text correctly.

#### Submitting a new localization

Currently, the CotEditor project only accepts new localizations whose provider can maintain the localization thereafter. Please explicitly tell us if you also intend to be a localization maintainer when submitting a new localization. The standard maintenance process of a localization is described in the following subsection.

You have two options to add a new localization to CotEditor.app. Choose one of them depending on your knowledge and preference:

- Option 1: Add a new localization in Xcode by yourself and make a pull-request (for those who get used to git and Xcode projects):
    - Open CotEditor.xcodeproj in Xcode, go to Project > CotEditor > Info > Localizations, and then add your language to the table. In the Resources group in the project, you can find all strings files (.xcstrings) both in the Localizations and Storyboards subgroups. The new language you added will automatically be appeared in the catalog list. Select your language and fill each cell of your language column in the table. Note that you don't need to localize the UnicodeBlock.strings file. It will be done by @1024jp based on the localization data by Apple.
    - CotEditor currently uses the String Catalog format (.xcstrings) first introduced in Xcode 15 released in 2023. cf. [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- Option 2: Communicate with the maintainer personally and work with provided localization template (.xcloc file):
    - Send a message to the maintainer (@1024jp) either by creating a new issue on GitHub or by e-mail to ask to get the localization template (.xcloc file) for your language. When you receiving the .xcloc file, open it in Xcode and fill each cell of your language column in the tables. When finished, send back the template file to the maintainer.

#### Localization maintenance process

A standard localization update proceeds as follows:

1. When CotEditor has new strings to be localized, the CotEditor maintainer, @1024jp, creates a new ticket on GitHub Issues and mentions the localization maintainers in it so that they can keep all their localized strings up to date. The ticket includes all strings to be updated and their descriptions, sometime with screenshots. e.g., [#1519](https://github.com/coteditor/CotEditor/issues/1519).
2. The localizers either post the localized strings to the thread or make a pull request on GitHub. The maintainers should localize the updated strings within about one week (the shorter period is, of course, welcome, but not required). All the responses must be done on GitHub. Not par email.
3. The CotEditor maintainer reviews and merges the update provided by the localizers.

Localization updates may happen once par few months, in general. If a maintainer wants to decline further ongoing maintenance for some reason, it would be kind to express their intentions to the maintainer via email or something. In that case, I will contact the community to find a new maintainer.

Currently, we already have maintainers for:

- English (UK)
- Simplified Chinese
- Traditional Chinese
- Czech
- Dutch
- French
- German
- Italian
- Japanese
- Portuguese
- Turkish

#### Localization for the App Store

CotEditor project is also asking for localization of description on the Mac App Store. We have a separate repository for it at [coteditor/Documents-for-AppStore](https://github.com/coteditor/Documents-for-AppStore).

#### Hints on localization

By localization, use macOS standard terms. It may be helpful to study native Apple applications like TextEdit.app or System Settings to know how Apple localizes terms in their apps.

Especially, follow the terms of the following applications:

- Menu item titles in TextEdit.app
- Find panel in Pages.app
- Some setting messages in ScriptEditor.app

Furthermore, we recommend to utilize [Apple Localization Terms Glossary for macOS](https://applelocalization.com/macos) by Kishikawa Katsumi to find macOS-friendly expressions. This service enables us to search in the texts localized by Apple for macOS apps and frameworks.
You also need to take care of how Apple treats punctuation characters and symbols. For example, regarding quotation marks, they normally prefer the typographer's ones.


### Syntaxes

#### Adding a new bundled syntax

Put just your new syntax into `/CotEditor/syntaxes/` directory. You don't need to modify `SyntaxMap.json` file because it will be automatically generated on the build.

The license for the bundled syntaxes must be "Same as CotEditor".

If the syntax language is relatively minor, we recommend you not to bundle it to CotEditor but to distribute it as an additional syntax in your own way, and just add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Syntax-Styles).


### Themes

We don't accept pull requests adding bundled themes at the moment. You can distribute yours as an additional theme in your own way, and add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Themes).


### Graphic Resources

We don't accept pull requests for image resources. @1024jp enjoys creating and brushing up the graphics ;). If you find a graphic resource having some kind of issues to be fixed, please just point out on the Issues page.



## Coding Style Guide

Please follow the style of the existing codes in CotEditor.

- Respect the existing coding style.
- Leave reasonable comments.
- Never omit `self` except in `willSet`/`didSet`.
- Add `final` to classes and extension methods by default.
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
- Write the `guard` statement in one-line if just return a simple value.
    ```Swift
    // prefer
    guard !foo.isEmpty else { return nil }
    
    // instead of
    guard !foo.isEmpty else {
        return nil
    }
    ```
