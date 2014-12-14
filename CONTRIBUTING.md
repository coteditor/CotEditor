
Contributing Guidelines
==========================

General Feedback
--------------------------

Create a new issue on our [Issues page](https://github.com/coteditor/CotEditor/issues). You can write your feedback either in English or in Japanese.

Bug reports __must__ include your environment. You can generate a bug report template automatically in CotEditor selecting "Help" > "Create Bug Report…" in the menu.



Pull-Request
--------------------------

- Make a topic branch, instead commit to the master or develop branch.


### General Code Improvements

Bug fixes and improvements are welcome. If you wanna add a new feature or the change is huge, it's better at first to ask the team whether your idea will be accepted.

By adding code, please follow our coding style guide below. 


### Localization

Fixing/updating existing localizations is always welcome. The project team may add `FIXME:` tag as a comment in the localized strings files, if there are updated strings to be localized.

By localization, use OS X standard terms. It might be helpful for you to study native Apple applications like TextEdit.app or the System Preferences to know how Apple localizes terms in their apps.

If your localization makes the Autolayout destroy, just tell us about it with a screenshot when you make a pull-request. We'll update the xib file to layout your localized terms correctly.

#### Submit a new localization

__We will migrate to the Base Internationalisation on CotEditor 2.1 within 2014. We recommend to wait for it to add a new localization.__

To localize CotEditor, [OgreKit framework](https://github.com/sonoisa/OgreKit) which is used for the CotEditor's find panel and the find menu must also be localized. If OgreKit doesn't contain your language, localize it and make a pull-request to both the original [OgreKit framework](https://github.com/sonoisa/OgreKit) *and* the [CotEditor's repo](https://github.com/coteditor/OgreKit).


### Syntax Styles

#### Add a new bundled syntax style

Put just your new syntax stye into `/CotEditor/syntaxes/` directory. You don't need to modify `SyntaxMap.json` file. It's generated automatically on build.

The license for the bundled syntax styles should be "Same as CotEditor".

If the syntax language is relatively minor, we recommend you to distribute it as an additional syntax style by your own way, and just add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Syntax-Styles).


### Themes

We aren't accepting pull-requests adding bundled theme at the moment. You can distribute it as an additional theme by your own way, and add a link to our [wiki page](https://github.com/coteditor/CotEditor/wiki/Additional-Themes).


### Graphics Resources

We aren't accepting pull-requests for image resources. [1024jp](https://github.com/1024jp) is enjoying to create and brush-up the graphics ;). Please just point out on the Issues page if graphic resource has some kind of mistake to be fixed.


Coding Style Guide
--------------------------

Please follow the style of the existing codes in CotEditor.

- Use always the [modern Objective-C](https://developer.apple.com/library/mac/releasenotes/ObjectiveC/ModernizationObjC/AdoptingModernObjective-C/AdoptingModernObjective-C.html).
- Leave reasonable comments.
- Prefer using the classic bracket style to access properties.
	```ObjC
	// use
	[self setFoo:@"foo"];
	NSString *foo = [self foo];
	
	// instead
	self.foo = @"foo";
	NSString *foo = self.foo;
	```
- Leave the opening-curly-bracket `{` in the same line as long as the condition statement is a single line, otherwise put it in a new line.
	```ObjC
	// single line
	if (foo > 0) {
		// your code
	}
	
	// multiple lines
	if ((foo > 0) &&
	    (foo < 100))
	{
		// your code
	}
	```
- Don't omit curly brackets even the contents is a single line.
	```ObjC
	// use
	if (!foo) { return; }
	
	// instead
	if (!foo) return;
	```
