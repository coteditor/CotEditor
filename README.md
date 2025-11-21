# CotEditor

CotEditor is a lightweight plain-text editor designed for macOS. The project aims to provide a general plain-text editor for everyone with an intuitive macOS-native user interface.

- __Requirement__: macOS Sequoia 15 or later
- __Web Site__: <https://coteditor.com>
- __Mac App Store__: <https://apps.apple.com/app/coteditor/id1024640650>
- __Languages__: English, Czech, Dutch, French, German, Italian, Japanese, Korean, Polish, Portuguese, Russian, Spanish, Simplified Chinese, Traditional Chinese, and Turkish

![screenshot](screenshot@2x.png)


## Design Philosophy

CotEditor is built with a clear focus on being a truly __macOS-native__ text editor.
Its design emphasizes the following principles:

- __Behave as a first-class macOS application.__
  CotEditor adopts system-native UI components, conventions, and behaviors so that it feels instantly familiar to macOS users. Rather than asserting its own personality, CotEditor aims to blend naturally into the macOS experience as one of its native apps.

- __Be accessible and comfortable for both beginners and advanced users.__
  CotEditor aims to stay simple enough for casual use while providing the precision and control expected by experienced editors and developers.

- __Handle a wide range of plain-text formats accurately.__
  From everyday notes to niche or legacy formats, CotEditor prioritizes correct text handling, encoding support, and predictable editing behavior.

- __Respect a diverse user base through localization and accessibility.__
  Whenever possible, CotEditor integrates macOS features for localization, accessibility, and user customization to serve a global audience.

These principles guide the project’s long-term direction and day-to-day development decisions,
and they also help determine which feature requests align with CotEditor’s macOS-native identity.



## Source Code

CotEditor is a purely macOS native application written in Swift. It adheres to Cocoa's document-based application architecture and respects the power of `NSTextView` and related text system APIs.


### Development Environment

- macOS Tahoe 26
- Xcode 26.2
- Swift 6.2 (partly in Swift 5 mode)
- Sandbox and hardened runtime enabled



## Contribution

CotEditor has its own contributing guidelines. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before creating an issue or submitting a pull request.



## How to Build

### Build for ad‑hoc usage

For those people who just want to build and play with CotEditor locally.

1. Open `CotEditor.xcodeproj` in Xcode.
1. Switch to ad-hoc build mode:
    1. Open `Configurations/CodeSigning.xcconfig`.
    1. Comment out `#include "CodeSigning-Default.xcconfig"`.
    1. Uncomment `#include "CodeSigning-AdHoc.xcconfig"`.
1. Build the “CotEditor” scheme.


### Build for distribution

1. Open `CotEditor.xcodeproj` in Xcode.
1. Build the “CotEditor” scheme.



## License

© 2005-2009 nakamuxu,
© 2011, 2014 usami-k,
© 2013-2025 1024jp.

The source code is licensed under the terms of the __Apache License, Version 2.0__. Image resources are licensed under the [__Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License__](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE](LICENSE) for details.
