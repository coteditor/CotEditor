#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=Selection}%%%
#%%%{CotEditorXOutput=ReplaceSelection}%%%

# Selection を [] で挟みます。空白行は無視します。

a = $stdin.read

soa = ""
eoa = ""

if /\A([\n\r]+)/ =~ a
	soa = $1
	a.sub!(/\A[\n\r]+/, "")
end
if /([\n\r]+)\Z/ =~ a
	eoa = $1
	a.sub!(/[\n\r]+\Z/, "")
end

print(soa+"["+a+"]"+eoa)

exit
