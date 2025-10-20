# CotEditor

CotEditor is a lightweight plain-text editor designed for macOS. The project aims to provide a general plain-text editor for everyone with an intuitive macOS-native user interface.

- __Requirement__: macOS Sequoia 15 or later
- __Web Site__: <https://coteditor.com>
- __Mac App Store__: <https://apps.apple.com/app/coteditor/id1024640650>
- __Languages__: English, Czech, Dutch, French, German, Italian, Japanese, Korean, Polish, Portuguese, Spanish, Simplified Chinese, Traditional Chinese, and Turkish

![screenshot](screenshot@2x.png)



## Source Code

CotEditor is a purely macOS native application written in Swift. It adheres to Cocoa's document-based application architecture and respects the power of `NSTextView` and related text system APIs.


### Development Environment

- macOS Tahoe 26
- Xcode 26
- Swift 6.2 (partly in Swift 5 mode)
- Sandbox and hardened runtime enabled



## Contribution

CotEditor has its own contributing guidelines. Read [CONTRIBUTING.md](CONTRIBUTING.md) through before you create an issue or make a pull request.



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
