(*
最前面のウィンドウの選択範囲を property newStr  に設定された文字列で置き換えるスクリプト。
この例では、「TEMPLATE」に置換します。処理後は、「TEMPLATE」を選択状態にします。
*)
(* written by nakamuxu. 2005.04.14 *)
--
property newStr : "TEMPLATE"
--
--
tell application "CotEditor"
	if exists front document then
		set contents of selection of front document to newStr
	end if
end tell