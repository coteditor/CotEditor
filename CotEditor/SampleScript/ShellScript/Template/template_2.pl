#! /usr/bin/perl
#
# Sample Perl Script for CotEditor
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

$INPUT=`cat -`;

$INPUT =~ tr/a-z/A-Z/;
print $INPUT;
