#!/usr/bin/env ruby -Ku
#%%%{CotEditorXInput=None}%%%
#%%%{CotEditorXOutput=InsertAfterSelection}%%%

# カーソル位置に現在の日時を挿入します。
# 以下の "separator" は、自分の好きなものに書き換えてお使いください。
day_sep = "."
time_sep = ":"
dt_sep = " "

now = Time.now

# 日だけ
print now.strftime("%y#{day_sep}%m#{day_sep}%d")
# 時だけ
#print now.strftime("%H#{time_sep}%M#{time_sep}%S")
# 日時両方
#print now.strftime("%y#{day_sep}%m#{day_sep}%d#{dt_sep}%H#{time_sep}%M#{time_sep}%S")

exit
