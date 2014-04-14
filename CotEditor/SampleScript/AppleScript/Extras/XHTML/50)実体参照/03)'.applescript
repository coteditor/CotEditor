(* written by nakamuxu. 2005.03.14 *)
--
property newStr : "&#039;"
--
--
tell application "CotEditor"
	if exists front document then
		set contents of selection of front document to newStr
	end if
end tell