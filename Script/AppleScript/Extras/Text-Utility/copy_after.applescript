(*
最前面のウィンドウの選択範囲の直後に、選択範囲をコピーするスクリプト。
Mac OS X 10.5+ で選択範囲の直前／直後へのドラッグ&ドロップができなくなったことへの対策として作成。
*)
(* written by nakamuxu. 2008.01.05 *)
--
--
--
tell application "CotEditor"
	if exists front document then
		set oldRange to range of selection as list
		set len to item 2 of oldRange
		if len > 0 then
			set copyStr to contents of selection of front document
			set loc to item 1 of oldRange
			set range of selection of front document to {loc + len, 0}
			set contents of selection of front document to copyStr
		end if
	end if
end tell