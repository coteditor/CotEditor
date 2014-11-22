(*
Input Current Time.applescript
Sample Script for CotEditor

Description:
Insert current time stamp to the insertion point.

This script was based on the following article (2005-10-09)
http://www001.upp.so-net.ne.jp/hanaden/osa/samples.html#_Smart_Quote

modified by 1024jp on 2014-11-22
*)

property format : "%Y-%m-%dT%H:%M:%S%z"

--
tell application "CotEditor"
	if not (exists front document) then return
	
	tell front document
		set contents of selection to (do shell script "date " & quoted form of ("+" & format))
	end tell
end tell
