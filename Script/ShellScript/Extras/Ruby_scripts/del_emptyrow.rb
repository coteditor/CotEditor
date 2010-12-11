#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=AllText}%%%
#%%%{CotEditorXOutput=ReplaceAllText}%%%

# 空白行 (= 改行のみの行)、半角/全角スペースのみを含む行、を削除します。

while gets
	if !(/^[　\s\r\n]+$/ =~ $_)
		print $_
	end
end

exit
