# Contributing Guidelines

## General Feedback

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). We welcome feedback in either English (preferred) or Japanese.


### Issue reports

Update CotEditor to the latest version and make sure that the issue you are having is also present in the latest version.

First, search for existing issues related to your problem. If you find a similar issue that has already been reported, post your case to that thread. If not, create a new issue by filling out the “Bug report” template. Feel free to post the same issue to the existing one, as long as there are fewer than 10 cases. Multiple instances of the same issue can be very helpful in finding the cause. In that case, please include your environment (versions of both CotEditor and macOS) in your post.

If possible, attach screenshots or screencasts of the issue you encounter. It is also helpful to attach sample files that can reproduce the issue.

If your issue relates to syntax highlighting, include the sample code that can reproduce the unwanted highlight in your post.


### Feature requests

First, search for existing feature requests. If your idea is already posted, comment on that thread. Otherwise, create a new one using the “Feature request” template.
Instead of listing multiple features in a single post, create an issue for each feature.

Please refrain from simply adding “+1” or similar comments to existing requests; it serves no purpose and contributes to unnecessary clutter.



## Pull Requests

### General Code Improvements

Bug fixes and improvements are welcome. Before adding a new feature or making a significant change, please consult the team to ensure its acceptance.

When contributing code, please adhere to our coding style guide for consistency and maintainability.


### Localizations

Fixing or updating existing localizations is always appreciated. See each .xcstrings file to find which strings need to be localized or reviewed by native speakers. Please refer to the comments and key naming to understand where and how each string will be used. If you are uncertain, feel free to ask @1024jp.

If your localization disrupts the layout of views, try first shortening the sentence. However, if it's impossible, provide a screenshot when you submit a pull request. We'll update the view to correctly lay out your localized text.

#### Submitting a new localization

Currently, the CotEditor project only accepts new localizations from providers who can maintain them in the future. When submitting a new localization, please explicitly indicate if you also intend to be a localization maintainer. For more information on the standard maintenance process of localizations, please refer to the following subsection.

You have two options for adding a new localization to CotEditor.app. Choose one of them depending on your knowledge and preferences:

- Option 1: Add a new localization in Xcode by yourself and make a pull request (for those who get used to git and Xcode projects):
    - Open CotEditor.xcodeproj in Xcode, go to Project > CotEditor > Info > Localizations, and add your language to the table. Then, the new language you added will automatically appear in the string catalogs.
    - CotEditor uses the String Catalog format (.xcstrings), introduced in 2023. To add localization to each string catalog file, select your language and fill in the corresponding cells in the table. Cf. [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
    - You can find the string catalogs to localize under:
        - CotEditor/Resources/Localizables/
        - CotEditor/Storyboards/mul.lproj/
        - Packages/EditorCore/Sources/CharacterInfo/Resources/
        - Packages/EditorCore/Sources/FileEncoding/Resources/
        - Packages/EditorCore/Sources/LineEnding/Resources/
        - Packages/EditorCore/Sources/StringUtils/Resources/
        - Packages/EditorCore/Sources/Syntax/Resources/
    - Note that you don't need to localize the UnicodeBlock.xcstrings file in Packages/Libraries/Sources/CharacterInfo/. This will be handled by @1024jp based on Apple's localization data.
- Option 2: Communicate with the maintainer personally and work with a provided localization template (.xcloc file):
    - Send a message to the maintainer (@1024jp) either by creating a new issue on GitHub or by e-mail to ask for the localization template (.xcloc file) for your language. Upon receiving the .xcloc file, open it in Xcode and fill each cell of your language column in the tables. Once completed, send the template file back to the maintainer.

#### Localization maintenance process

A standard localization update proceeds as follows:

1. When CotEditor has new strings to be localized, the CotEditor maintainer, @1024jp, creates a new ticket on GitHub Issues. This ticket includes all the strings to be updated along with their descriptions and, sometimes, screenshots. For instance, [#1519](https://github.com/coteditor/CotEditor/issues/1519) is an example of such a ticket.
2. The localizers then post the localized strings to the thread or make a pull request on GitHub. The maintainers are responsible for localizing the updated strings within approximately one week. While a shorter period is preferred, it’s not mandatory. All responses must be made on GitHub, not via email.
3. The CotEditor maintainer reviews and merges the updates provided by the localizers.

Localization updates may happen once per few months, in general. If a maintainer wants to decline further ongoing maintenance for some reason, it would be kind to express their intentions to the maintainer via email or something. In that case, I will reach out to the community to find a new maintainer.

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

We are now looking for new maintainers for:

- French
- Spanish

Although CotEditor is not yet localized in any bidirectional languages, the project is prepared for it. If you're interested in localizing CotEditor to those languages, please let us know.

#### Localization for the App Store

The CotEditor project is also asking for localization of descriptions on the Mac App Store. We have a separate repository for it at [coteditor/Documents-for-AppStore](https://github.com/coteditor/Documents-for-AppStore).

#### Hints on localization

By localization, use macOS standard terms. It may be helpful to study native Apple applications like TextEdit.app or System Settings to learn how Apple localizes terms in their apps.

Especially, follow the terms of the following applications:

- Menu item titles in TextEdit.app
- The Find panel in Pages.app
- Some setting messages in ScriptEditor.app

Additionally, we recommend utilizing the [Apple Localization Terms Glossary for macOS](https://applelocalization.com/macos) by Kishikawa Katsumi to find macOS-friendly expressions. This service enables us to search in the texts localized by Apple for macOS apps and frameworks.
You also need to take care of how Apple treats punctuation characters and symbols. For example, regarding quotation marks, they generally prefer the typographer's ones.


### Syntaxes

#### Adding a new bundled syntax

Put just your new syntax into the `/CotEditor/Resources/syntaxes/` directory. You don't need to modify the `SyntaxMap.json` file because it will be automatically generated in the build phase.

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
