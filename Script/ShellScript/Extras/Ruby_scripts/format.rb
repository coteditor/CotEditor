#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=Selection}%%%
#%%%{CotEditorXOutput=ReplaceSelection}%%%

# 選択範囲の 1 行目に整数 (例えば 50) を入れておくと、各行をその文字数で強制改行します。
# 1 行目に数字以外の要素が含まれている場合は「指定なし」となり、default の 60 を使用して改行を入れます。

# default
$line_len = 60

while gets
	$_.chomp!
	if $. == 1
		if /^\d+$/ =~ $_
			$line_len = $_.to_i
		end
	end

	if $_.length > $line_len
		line = $_.gsub(/(.{#{$line_len}})/) {|matched|
			matched.to_s+"\n"
		}
		line.chomp!
	else
		line = $_
	end
	print(line, "\n")
end

exit
