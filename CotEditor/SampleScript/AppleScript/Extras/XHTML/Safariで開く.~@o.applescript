(* written by 1024jp. 2014-10-11 *)
--
tell application "CotEditor"
	if exists front document then
		set theFile to file of front document
		if theFile exists then
			tell application "Safari"
				activate
				open theFile
			end tell
		end if
	end if
end tell