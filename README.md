
CotEditor
==========================

CotEditor is a lightweight plain-text editor for macOS.

- __Requirement__: macOS 10.13 High Sierra or later
- __Web Site__: <https://coteditor.com>
- __Mac App Store__: <https://itunes.apple.com/app/coteditor/id1024640650?ls=1>

<img src="screenshot@2x.png" width="750"/>



Source Code
--------------------------

[![Test Status](https://github.com/coteditor/CotEditor/workflows/Test/badge.svg)](https://github.com/coteditor/CotEditor/actions?query=workflow%3ATest)
[![GitHub release](https://img.shields.io/github/release/coteditor/CotEditor.svg)](https://github.com/coteditor/CotEditor/releases/latest)

CotEditor is a pure document-based Cocoa application written in Swift.


### Development Environment

- macOS 10.15 Catalina
- Xcode 11.4
- Swift 5.2
- Sandbox enabled



How to Build
--------------------------

1. Run following commands to resolve dependencies.
    - `git submodule update --init`
    - `carthage bootstrap`
1. Open `CotEditor.xcworkspace` in Xcode.
1. Open `Configurations/CodeSigning.xcconfig`, then comment out `#include "CodeSigning-Default.xcconfig"`, and uncomment `#include "CodeSigning-AdHoc.xcconfig"`. This step requires to build CotEditor for ad-hoc usage.
1. Build "CotEditor" scheme in the workspace.



License
--------------------------

© 2005-2009 nakamuxu,
© 2011, 2014 usami-k,
© 2013-2020 1024jp.

The source code is licensed under the terms of the __Apache License, Version 2.0__. The image resources are licensed under the terms of the [__Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License__](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE](LICENSE) for details.
