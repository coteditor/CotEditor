#! /bin/sh
#
# Sample Shell Script for CotEditor
#
# Wraps the selection with <h1> tags.
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

INPUT=`cat -`
echo "<h1>${INPUT}</h1>"
