#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=Selection}%%%
#%%%{CotEditorXOutput=ReplaceSelection}%%%

# 選択範囲の行頭に ' を付加します。
# VB コードの一部をまとめてコメント化させたい時に使うと便利です。元に戻す時は unshift を使います。

while gets
	print $_.sub(/^/, "'")
end

exit
