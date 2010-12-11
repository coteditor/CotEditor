(* written by nakamuxu. 2005.03.26 *)
--
property newStr : "<hr />"
--
--
tell application "CotEditor"
	if exists front document then
		set contents of selection of front document to newStr
	end if
end tell