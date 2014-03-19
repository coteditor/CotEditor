tell application "Finder"
	set thePath to (path to application support from user domain) & "CotEditor:ScriptMenu:" as Unicode text
	open thePath
	activate
end tell