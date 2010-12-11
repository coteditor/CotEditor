(*
最前面のウィンドウの行頭／行末の空白を削除するスクリプト。
*)
(* written by nakamuxu. 2008.01.05 *)
--
--
--
tell application "CotEditor"
	if exists front document then
		replace front document for "^ +" to "" with RE and all
		replace front document for " +$" to "" with RE and all
	end if
end tell