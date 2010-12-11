(*
最前面のウィンドウの選択範囲を property beginStr と endStr  に設定された文字列で囲むスクリプト。
この例では、「<h1>」と「</h1>」で囲みます。処理後は、選択範囲があった場合には「</h1>」の直後に、なかった場合は前に、キャレットを移動します。
property preMargin に0 以外の数値を入れると、処理前の選択範囲の開始位置から preMargin 文字分、キャレットを強制的に移動できます。
*)
(* written by nakamuxu. 2005.04.14 *)
--
property beginStr : "<h1>"
property endStr : "</h1>"
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