#! /usr/bin/perl
#
# Sample Perl Script for CotEditor
#
# Transform the lowercase a-z in the selection to uppercase A-Z.
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

$INPUT=`cat -`;

$INPUT =~ tr/a-z/A-Z/;
print $INPUT;
