#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=AllText}%%%
#%%%{CotEditorXOutput=ReplaceAllText}%%%

# 一行目に、「検索対象(正規表現)、置換文字列」のペアを連続で入れておきます (各要素は全てタブで区切ってください)。
# この順に各行を一括置換します。後方参照は \1 などで指定してください。
# 「大文字小文字を同一視」などのオプションは付けられないので、正規表現を使って表してください。


to_find = Array.new
replace_to = Array.new

while gets
	if $. == 1
		$_.chomp.split("\t").each_with_index do |item, i|
			if i % 2 == 0
				to_find << item
			else
				replace_to << item
			end
		end
	else
		to_find.each_with_index do |find, i|
			re_temp = Regexp.new(find)
			if replace_to[i] == nil
				replace_to[i] = ""
			else
				replace_to[i].gsub!(/\\t/, "\t")
				replace_to[i].gsub!(/\\n/, "\n")
				replace_to[i].gsub!(/\\r/, "\r")
			end
			$_.gsub!(re_temp, replace_to[i])
		end
		print $_
	end
end

exit

# 複数行にまたがる検索・置換を行いたい場合、以下と入れ替えて使用してください。
# ただし、ファイルが大きい場合には速度が低下する可能性があります。

#to_find = Array.new
#replace_to = Array.new
#whole = ""
#
#while gets
#	if $. == 1
#		$_.chomp.split("\t").each_with_index do |item, i|
#			if i % 2 == 0
#				to_find << item
#			else
#				replace_to << item
#			end
#		end
#	else
#		whole += $_
#	end
#end
#
#to_find.each_with_index do |find, i|
#	re_temp = Regexp.new(find)
#	whole.gsub!(re_temp, replace_to[i])
#end
#print whole
#
#exit
