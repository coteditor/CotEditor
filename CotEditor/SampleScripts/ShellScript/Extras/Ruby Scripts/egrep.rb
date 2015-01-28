#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=AllText}%%%
#%%%{CotEditorXOutput=ReplaceAllText}%%%

# egrep もどきです。1 行目は条件指定行として使い、検索対象の正規表現を入れておくと、それを含む行だけを抽出します。
# タブで区切った 2 番目の要素として、以下のオプションを指定できます。
# -i を付けておくと「大文字小文字を無視する」オプションとして働きます。
# -n を付けておくと「行頭に元の行番号を付加する」オプションとして働きます。
# -r を付けておくと「逆順に表示する」オプションとして働きます。
# -v を付けておくと「検索対象を含まない行を表示する」オプションとして働きます。
# 混合オプションは、-inrv のように、まとめて指定してください (順不同)。

whole = Array.new
rev_flag = nil
inv_flag = nil
num_flag = nil

while gets
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
			if /n/i =~ cond[1]
				num_flag = 1
			end
		else
			re = Regexp.new(cond[0])
		end
	else
		if inv_flag
			if !(re =~ $_)
				if num_flag
					temp = ($.-1).to_s + ": " + $_
					whole << temp
				else
					whole << $_
				end
			end
		else
			if re =~ $_
				if num_flag
					temp = ($.-1).to_s + ": " + $_
					whole << temp
				else
					whole << $_
				end
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
