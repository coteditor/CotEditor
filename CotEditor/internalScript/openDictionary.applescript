(*
このスクリプトは、下記のソースを参考にさせていただきました。
http://piza.2ch.net/log2/mac/kako/957/957215209.html
*)
tell application "Finder"
	set the script_editor to application file id "ToyS"
	set file_path to path to frontmost application
	ignoring application responses
		open file_path using script_editor
	end ignoring
end tell
