# Contributing Guidelines

## General Feedback

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). You can write your feedback either in English (recommended) or in Japanese.


### Issue reports

Search for existing issues first. If you find your issue previously reported, post your case to that issue; otherwise, create a new one by filling out the “Bug report” template. Do not hesitate to post the same phenomenon as the existing issue as long as there are fewer than 10 cases. Multiple instances help a lot in finding the cause. In that situation, include your environment (versions of both CotEditor and macOS) in your post.

If possible, attach screenshots or screencasts of the issue you face. It is also helpful to attach sample files that can reproduce the issue.

If your issue relates to the syntax highlight, include the sample code that can reproduce the unwanted highlight in your post.


### Feature requests

Search for existing requests first. If you find your idea among the requests already posted, post your comment on that issue; otherwise, create a new one by filling out the “Feature request” template.
Create an issue per feature instead of listing multiple features in a single post.



## Pull Requests

### General Code Improvements

Bug fixes and improvements are welcome. If you want to add a new feature or make a major change, it's better to ask the team first whether your idea will be accepted.

By adding code, please follow our coding style guide below.


### Localizations

Fixing/updating existing localizations is always welcome. See each .xcstrings file to find which strings need to be localized or reviewed by native speakers. By localization, please refer to the comments and key naming so that you can know where and how each string will be used. If you are uncertain, feel free to ask @1024jp.

If your localization destroys some layout in views, try first making the sentence shorter. However, if it's impossible, then just tell us about it with a screenshot when you make a pull request. We'll update the view to lay out your localized text correctly.

#### Submitting a new localization

Currently, the CotEditor project only accepts new localizations whose provider can maintain them thereafter. When submitting a new localization, please explicitly tell us if you also intend to be a localization maintainer. The standard maintenance process of localization is described in the following subsection.

You have two options for adding a new localization to CotEditor.app. Choose one of them depending on your knowledge and preference:

- Option 1: Add a new localization in Xcode by yourself and make a pull request (for those who get used to git and Xcode projects):
    - Open CotEditor.xcodeproj in Xcode, go to Project > CotEditor > Info > Localizations, and add your language to the table. Then, the new language you added will automatically appear in the string catalogs.
    - CotEditor uses the String Catalog format (.xcstrings), first introduced in 2023. To add localization in each string catalog file, select your language and fill each cell of your language column in the table. Cf. [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
    - You can find the string catalogs to localize under:
        - CotEditor/Resources/Localizables/
        - CotEditor/Resources/Storyboards/
        - Packages/EditorCore/Sources/CharacterInfo/Resources/
        - Packages/EditorCore/Sources/FileEncoding/Resources/
        - Packages/EditorCore/Sources/LineEnding/Resources/
        - Packages/EditorCore/Sources/StringUtils/Resources/
        - Packages/EditorCore/Sources/Syntax/Resources/
    - Note that you don't need to localize the UnicodeBlock.strings file in Packages/Libraries/Sources/CharacterInfo/. It will be done by @1024jp based on the Apple's localization data.
- Option 2: Communicate with the maintainer personally and work with a provided localization template (.xcloc file):
    - Send a message to the maintainer (@1024jp) either by creating a new issue on GitHub or by e-mail to ask for the localization template (.xcloc file) for your language. When you receive the .xcloc file, open it in Xcode and fill each cell of your language column in the tables. When finished, send the template file back to the maintainer.

#### Localization maintenance process

A standard localization update proceeds as follows:

1. When CotEditor has new strings to be localized, the CotEditor maintainer, @1024jp, creates a new ticket on GitHub Issues and mentions the localization maintainers in it so that they can keep all their localized strings up to date. The ticket includes all strings to be updated and their descriptions, sometimes with screenshots. e.g., [#1519](https://github.com/coteditor/CotEditor/issues/1519).
2. The localizers either post the localized strings to the thread or make a pull request on GitHub. The maintainers should localize the updated strings within about one week (the shorter period is, of course, welcome, but not required). All the responses must be done on GitHub. Not via email.
3. The CotEditor maintainer reviews and merges the updates provided by the localizers.

Localization updates may happen once per few months, in general. If a maintainer wants to decline further ongoing maintenance for some reason, it would be kind to express their intentions to the maintainer via email or something. In that case, I will contact the community to find a new maintainer.

Currently, we already have maintainers for:

- English (UK)
- Simplified Chinese
- Traditional Chinese
- Czech
- Dutch
- German
- Italian
- Japanese
- Korean
- Polish
- Portuguese
- Turkish

We are now looking for a new maintainer for:

- French
- Spanish


#### Localization for the App Store

The CotEditor project is also asking for localization of descriptions on the Mac App Store. We have a separate repository for it at [coteditor/Documents-for-AppStore](https://github.com/coteditor/Documents-for-AppStore).

#### Hints on localization

By localization, use macOS standard terms. It may be helpful to study native Apple applications like TextEdit.app or System Settings to learn how Apple localizes terms in their apps.

Especially, follow the terms of the following applications:

- Menu item titles in TextEdit.app
- The Find panel in Pages.app
- Some setting messages in ScriptEditor.app

Furthermore, we recommend utilizing [Apple Localization Terms Glossary for macOS](https://applelocalization.com/macos) by Kishikawa Katsumi to find macOS-friendly expressions. This service enables us to search in the texts localized by Apple for macOS apps and frameworks.
You also need to take care of how Apple treats punctuation characters and symbols. For example, regarding quotation marks, they normally prefer the typographer's ones.


### Syntaxes

#### Adding a new bundled syntax

Put just your new syntax into the `/CotEditor/syntaxes/` directory. You don't need to modify the `SyntaxMap.json` file because it will be automatically generated in the build phase.

The license for the bundled syntaxes must be “Same as CotEditor.”

If the syntax language is relatively minor, we recommend you not to bundle it to CotEditor but to distribute it as an additional syntax in your way, and just add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Syntax-Styles).


### Themes

We don't accept pull requests adding bundled themes at the moment. You can distribute yours as an additional theme in your way and add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Themes).


### Graphic Resources

We don't accept pull requests for image resources. @1024jp enjoys creating and brushing up on the graphics ;). If you find a graphic resource having some kind of issues to be fixed, please just point it out on the Issues page.



## Coding Style Guide

Please follow the style of the existing codes in CotEditor.

- Respect the existing coding style.
- Leave reasonable comments.
- Never omit `self` except in `willSet`/`didSet`.
- Add `final` to classes and extension methods by default.
- Insert a blank line after a class/function statement line.
    ```Swift
    /// Says moof.
    func moof() {
        
        print("moof")
    }
    ```
- Write the `guard` statement in one line if just returning a simple value.
    ```Swift
    // prefer
    guard !foo.isEmpty else { return nil }
    
    // instead of
    guard !foo.isEmpty else {
        return nil
    }
    ```
