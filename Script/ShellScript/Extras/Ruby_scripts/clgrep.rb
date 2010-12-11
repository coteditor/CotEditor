#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=AllText}%%%
#%%%{CotEditorXOutput=ReplaceAllText}%%%

# 空白行を区切りとした「ブロック」を対象に grep します。一行目に検索対象の正規表現とオプション、二行目は空白行 (必ず)、として使用してください。
# 一行目に、タブで区切った 2 番目の要素として、以下のオプションを指定できます。
# -i を付けておくと「大文字小文字を無視する」オプションとして働きます。
# -r を付けておくと「逆順に表示する」オプションとして働きます。
# -v を付けておくと「検索対象を含まないブロックを表示する」オプションとして働きます。
# 混合オプションは、-irv のように、まとめて指定してください (順不同)。

whole = Array.new
rev_flag = nil
inv_flag = nil

while gets("")
	if $. == 1
		cond = $_.chomp.split("\t")
		if cond[1]
			if /i/i =~ cond[1]
				re = Regexp.new(cond[0], "-i")
			else
				re = Regexp.new(cond[0])
			end
			if /r/i =~ cond[1]
				rev_flag = 1
			end
			if /v/i =~ cond[1]
				inv_flag = 1
			end
		else
			re = Regexp.new(cond[0])
		end
	else
		if inv_flag
			if !(re =~ $_)
				whole << $_
			end
		else
			if re =~ $_
				whole << $_
			end
		end
	end
end

if rev_flag
	whole.reverse!
end

whole.each do |line|
	print line
end


exit
