#!/usr/bin/ruby
#
#     xx)pre.rb
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