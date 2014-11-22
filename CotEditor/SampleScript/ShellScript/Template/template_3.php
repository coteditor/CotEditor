#! /usr/bin/php -q
<?php
#
# Sample PHP Script for CotEditor
#
# Transform the half-width alphabet in the selection to full-width.
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

do {
    $tmp = fread(STDIN, 8192);
    if (strlen($tmp) == 0) {
        break;
    }
    $INPUT .= $tmp;
} while(true);

$OUTPUT = mb_convert_kana($INPUT, "R", "UTF-8");
fwrite(STDOUT, $OUTPUT);
?>
