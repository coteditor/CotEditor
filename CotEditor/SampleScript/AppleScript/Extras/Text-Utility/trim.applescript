(*
最前面のウィンドウの行頭／行末の空白を削除するスクリプト。
*)
(* written by nakamuxu. 2008.01.05 *)
(* modified by 1024jp. 2014-10-11 *)
--
--
--
tell application "CotEditor"
	if exists front document then
		tell front document
			replace for "^ +" to "" with RE and all
			replace for " +$" to "" with RE and all
		end tell
	end if
end tell
