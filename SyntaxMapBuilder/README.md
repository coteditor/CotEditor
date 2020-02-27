# Syntax Map Builder

The command-line helper application for CotEditor development to build SyntaxMap.json from the bundled syntax styles.

SyntaxMap.json gathers the file mapping information of all bundled syntax styles into a single JSON file in advance to prevent parse each bundled YAML file on every application launch that may take time.

This program is aimed to be used only locally in the CotEditor.app's build phase.


## Usage

Give the path to the directory for the bundled syntax files, then JSON string will be printed to the standard output.

```console
$ SyntaxMapBuilder Syntaxes/ > SyntaxMap.json
```
