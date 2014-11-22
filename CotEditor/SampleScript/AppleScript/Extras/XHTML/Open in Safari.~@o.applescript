(*
Open in Safari.applescript
Sample Script for CotEditor

Description:
Open the frontmost document in Safari.

modified by 1024jp on 2014-11-22
*)

--
tell application "CotEditor"
	set theFile to file of front document
	
	-- do nothing if the frontmost document has not been saved.
	if not theFile exists then return
	
	tell application "Safari"
		activate
		open theFile
	end tell
end tell
