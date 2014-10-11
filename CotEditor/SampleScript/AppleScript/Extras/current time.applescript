(*
下記の情報を参考にさせていただきました (2005.10.09)
http://www001.upp.so-net.ne.jp/hanaden/osa/samples.html#_Smart_Quote
*)
tell application "CotEditor"
	if exists front document then
		set (contents of selection of front document) to (do shell script "date '+%Y-%m-%dT%H:%M:%S%z' | sed 's/00$/:00/'")
	end if
end tell
