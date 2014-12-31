(* written by nakamuxu. 2005.03.14 *)
--
property beginStr : "<del cite=\"\" datetime=\""
property endStr : "</del>"
property preMargin : 11
--
--
tell application "CotEditor"
	if exists front document then
		set theTime to (do shell script "date ``+%Y-%m-%dT%H:%M:%S+09:00''")
		set {loc, len} to range of selection of front document
		if (len = 0) then
			set newStr to beginStr & theTime & "\">" & endStr
			if (preMargin = 0) then
				set numOfMove to count of character of beginStr
			else
				set numOfMove to preMargin
			end if
		else if (len > 0) then
			set curStr to contents of selection of front document
			set newStr to beginStr & theTime & "\">" & curStr & endStr
			if (preMargin = 0) then
				set numOfMove to count of character of newStr
			else
				set numOfMove to preMargin
			end if
		else
			return
		end if
		set contents of selection of front document to newStr
		set range of selection of front document to {loc + numOfMove, 0}
	end if
end tell