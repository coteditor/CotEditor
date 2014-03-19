#! /usr/bin/perl
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

$INPUT=`cat -`;

$INPUT =~ tr/a-z/A-Z/;
print $INPUT;