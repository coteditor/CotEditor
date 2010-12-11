(* written by nakamuxu. 2005.03.15 *)
--
tell application "CotEditor"
	if exists front document then
		set thePath to path of front document as Unicode text
		if (thePath is not "") then
			tell application "Safari"
				activate
				open location "file://" & thePath
			end tell
		end if
	end if
end tell