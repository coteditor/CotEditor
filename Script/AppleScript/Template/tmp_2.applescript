(*
最前面のウィンドウの選択範囲を property newStr  に設定された文字列で置き換えるスクリプト。
この例では、「TEMPLATE」に置換します。処理後は、「TEMPLATE」の直後にキャレットを移動します。
*)
(* written by nakamuxu. 2005.04.14 *)
--
property newStr : "TEMPLATE"
--
--
tell application "CotEditor"
	if exists front document then
		set {loc, len} to range of selection of front document
		set numOfMove to count of character of newStr
		set contents of selection of front document to newStr
		set range of selection of front document to {loc + numOfMove, 0}
	end if
end tell