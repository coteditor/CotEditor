(* written by nakamuxu. 2005.03.14 *)
--
property beginStr : "<ul>
<li>"
property endStr : "</li>
<li></li>
</ul>"
property preMargin : 0
--
--
tell application "CotEditor"
	if exists front document then
		set {loc, len} to range of selection of front document
		if (len = 0) then
			set newStr to beginStr & endStr
			if (preMargin = 0) then
				set numOfMove to count of character of beginStr
			else
				set numOfMove to preMargin
			end if
		else if (len > 0) then
			set curStr to contents of selection of front document
			set newStr to beginStr & curStr & endStr
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