#! /bin/sh
#
# Sample Shell Script for CotEditor
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

INPUT=`cat -`
echo "<h1>${INPUT}</h1>"
