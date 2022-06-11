
CotEditor
==========================

CotEditor is a lightweight plain-text editor for macOS.

- __Requirement__: macOS 12 Monterey or later
- __Web Site__: <https://coteditor.com>
- __Mac App Store__: <https://itunes.apple.com/app/coteditor/id1024640650?ls=1>

<img src="screenshot@2x.png" width="731" alt="screenshot"/>



Source Code
--------------------------

CotEditor is a pure document-based Cocoa application written in Swift.


### Development Environment

- macOS 12 Monterey
- Xcode 13.4
- Swift 5.6
- Sandbox enabled



Contribution
--------------------------

CotEditor has own contributing guidelines. Read [CONTRIBUTING.md](CONTRIBUTING.md) through before you create an issue or make a pull-request.



How to Build
--------------------------

### Build for Ad-hoc usage

For those people who just want to build and play with CotEditor locally.

1. Run following commands to resolve dependencies.
    - `git submodule update --init --recursive`
1. Open `CotEditor.xcodeproj` in Xcode.
1. Change to ad-hoc build mode:
    1. Open `Configurations/CodeSigning.xcconfig`.
    1. Comment out `#include "CodeSigning-Default.xcconfig"`.
    1. Uncomment `#include "CodeSigning-AdHoc.xcconfig"`.
1. Build "CotEditor" scheme in the workspace.


### Build for distribution

1. Run following commands to resolve dependencies.
    - `git submodule update --init --recursive`
1. Open `CotEditor.xcodeproj` in Xcode.
1. Build "CotEditor" scheme in the workspace.



License
--------------------------

© 2005-2009 nakamuxu,
© 2011, 2014 usami-k,
© 2013-2022 1024jp.

The source code is licensed under the terms of the __Apache License, Version 2.0__. The image resources are licensed under the terms of the [__Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License__](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE](LICENSE) for details.
