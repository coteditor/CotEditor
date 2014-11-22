#!/usr/bin/ruby
#
# Sample Ruby Script for CotEditor
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%
 
require 'cgi' 
 
preText = STDIN.read
 
print <<PRETAG
<pre>
#{CGI::escapeHTML(preText.chomp)}
</pre>
PRETAG
