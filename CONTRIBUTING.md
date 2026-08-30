# Contributing Guidelines

## General Feedback

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). We welcome feedback in either English (preferred) or Japanese.

Instead of listing multiple features or issues in a single post, create an issue for each topic.


### Issue reports

Create a new issue using the “Bug report” template.

Before submitting an issue, please do the following:

- Confirm that you are using the latest versions of both CotEditor and macOS, and that the issue still occurs in those versions.
- Confirm that the issue is specific to CotEditor. If possible, try performing the same steps in TextEdit and verify that the issue does not occur there.
- Search for existing issues related to your problem. If you find a similar issue, add your case to that thread instead of creating a new issue. Multiple reports of the same issue can be very helpful in identifying the cause. When adding your case, please include your environment details, such as the versions of CotEditor and macOS you are using.

If possible, attach screenshots or screen recordings that show the issue clearly. It’s also helpful to include sample files that can reproduce the problem. If the issue is related to syntax highlighting, please include a minimal code sample that demonstrates the unexpected highlighting.


### Feature requests

Create a new issue using the “Feature request” template.

Before submitting a request, please do the following:

- Search for existing feature requests. If your idea is already posted, comment on that thread instead of creating a new issue.

Please refrain from simply adding “+1” or similar comments to existing requests; such comments serve no purpose and create unnecessary clutter.


## Pull Requests

### General Code Improvements

Bug fixes are always welcome. However, if you are considering adding a new feature or making a significant change, please consult the team beforehand to ensure it aligns with the project’s direction. Feature additions that do not align with the project's direction are likely to be rejected.

Instead of modifying multiple features in a single pull request, create a separate pull request for each feature.

When contributing code, please adhere to our coding style guide for consistency and maintainability.


### Localizations

Fixing or updating existing localizations is always appreciated. Check each .xcstrings file to find strings that need to be localized or reviewed by native speakers. Refer to the comments and key names to understand where and how each string will be used. If you are uncertain, feel free to ask @1024jp.

If your localization disrupts a view’s layout, first try shortening the sentence. If that is not possible, provide a screenshot when you submit a pull request. We’ll update the view to lay out your localized text correctly.

#### Submitting a new localization

Currently, the CotEditor project accepts new localizations only from contributors who can maintain them in the future. When submitting a new localization, please explicitly indicate whether you also intend to be its maintainer. For more information about the standard localization maintenance process, refer to the following subsection.

You have two options for adding a new localization to CotEditor. Choose one of them depending on your knowledge and preferences:

- Option 1: Add a new localization in Xcode and submit a pull request (for those familiar with Git and Xcode projects):
    - Open CotEditor.xcodeproj in Xcode, go to Project > CotEditor > Info > Localizations, and add your language to the table. The language will then automatically appear in the string catalogs.
    - CotEditor uses the String Catalog format (.xcstrings), introduced in 2023. To add translations to each string catalog, select your language and fill in the corresponding cells in the table. See [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog).
    - You can find the string catalogs to localize under:
        - CotEditor/Localizables/
        - CotEditor/Storyboards/mul.lproj/
        - Packages/EditorCore/Sources/CharacterInfo/Resources/
        - Packages/EditorCore/Sources/FileEncoding/Resources/
        - Packages/EditorCore/Sources/LineEnding/Resources/
        - Packages/EditorCore/Sources/StringUtils/Resources/
        - Packages/Syntax/Sources/SyntaxFormat/Resources/
    - Note that you don’t need to localize the UnicodeBlock.xcstrings file in Packages/EditorCore/Sources/CharacterInfo/. It will be handled by @1024jp based on Apple’s localization data.
- Option 2: Contact the maintainer directly and work with a provided localization template (.xcloc file):
    - Ask the maintainer (@1024jp) for the localization template (.xcloc file) for your language, either by creating a new issue on GitHub or by email. Upon receiving the .xcloc file, open it in Xcode and fill in each cell in your language’s column. Once you have completed it, send the template file back to the maintainer.

#### Localization maintenance process

A standard localization update proceeds as follows:

1. When CotEditor has new strings to be localized, the CotEditor maintainer, @1024jp, creates a new ticket on GitHub Issues. This ticket includes all the strings to be updated along with their descriptions and, sometimes, screenshots. For instance, [#1519](https://github.com/coteditor/CotEditor/issues/1519) is an example of such a ticket.
2. The localizers then post the localized strings in the thread or submit a pull request on GitHub. Localization maintainers are expected to provide the updated strings within approximately one week. A shorter turnaround is appreciated but not required. All responses must be made on GitHub, not by email.
3. The CotEditor maintainer reviews and merges the updates provided by the localizers.

Localization updates generally occur once every few months. If a localization maintainer needs to stop maintaining a language, please let the CotEditor maintainer know by email. In that case, I will reach out to the community to find a new maintainer.

Currently, we already have maintainers for:

- English (UK)
- Chinese, Simplified
- Chinese, Traditional
- Chinese (Hong Kong)
- Czech
- German
- Italian
- Japanese
- Korean
- Polish
- Portuguese
- Russian
- Turkish

We are now looking for new maintainers for:

- Dutch
- French
- Spanish

Although CotEditor is not yet localized in any bidirectional languages, the project is prepared for it. If you're interested in localizing CotEditor to those languages, please let us know.

#### Localization for the App Store

The CotEditor project also seeks localizations for its Mac App Store descriptions. We have a separate repository for them at [coteditor/Documents-for-AppStore](https://github.com/coteditor/Documents-for-AppStore). If the Mac App Store supports your language, we’d appreciate it if you could localize these descriptions as well.

#### Hints on localization

When localizing, use standard macOS terminology. It may be helpful to study Apple apps such as TextEdit and System Settings to learn how Apple localizes terms.

In particular, follow the terminology used in these apps:

- Menu item titles in TextEdit
- The Find panel in Pages
- Some setting messages in Script Editor

Additionally, we strongly recommend using the [Apple Localization Terms Glossary for macOS](https://applelocalization.com/macos) by Kishikawa Katsumi to find macOS-friendly expressions. This service lets you search Apple’s localized text for macOS apps and frameworks.

Pay attention to how Apple treats punctuation and symbols. For example, Apple generally prefers typographic quotation marks.

Recent versions of Xcode include a translation skill at `~/Library/Developer/Xcode/CodingAssistant/codex/skills/__xcode/translation/`. Although the skill is intended for agentic coding, its `references` directory contains useful style guides for several languages. If you have Xcode installed and a guide is available for your language, we recommend consulting it as well.


### Syntaxes

#### Adding a new built-in syntax

Rather than opening a pull request directly, first create an issue and ask the maintainers whether the language is appropriate for inclusion as a built-in syntax in CotEditor. Please note that pull requests for new tree-sitter-based syntaxes are not accepted because of their maintenance cost. If the language is relatively uncommon, we recommend distributing the definition independently as an additional syntax instead of adding it to CotEditor as a built-in syntax. You can then add a link to it on our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Syntax-Styles).

When adding a new built-in syntax, add only your new syntax to the `/CotEditor/Resources/Syntaxes/` directory. You don’t need to modify the `SyntaxMap.json` file because it is generated automatically during the build phase.

The license for built-in syntax definitions must be “Same as CotEditor.”


### Themes

We don’t currently accept pull requests that add built-in themes. You can distribute yours independently as an additional theme and add a link to it on our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Themes).


### Graphic Resources

We don’t accept pull requests for image resources. @1024jp enjoys creating and refining the graphics ;). If you find an issue with a graphic resource, please point it out on the Issues page.


## Coding Style Guide

Please follow the style of the existing code in CotEditor.

- Respect the existing coding style.
- Leave reasonable comments.
- Never omit `self` except in `willSet`/`didSet`.
- Add `final` to classes and extension methods by default.
- Insert a blank line after a class or function declaration.
  ```swift
  /// Says moof.
  func bark() {
      
      print("moof")
  }
  ```
- Write a `guard` statement on one line when its `else` clause simply returns a value.
  ```swift
  // prefer
  guard !foo.isEmpty else { return nil }
  
  // instead of
  guard !foo.isEmpty else {
      return nil
  }
  ```
