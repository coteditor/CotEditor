#! /usr/bin/php -q
<?php
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

do {
    $tmp = fread(STDIN, 8192);
    if (strlen($tmp) == 0) {
        break;
    }
    $INPUT .= $tmp;
} while(true);

$OUTPUT = mb_convert_kana($INPUT, "k", "UTF-8");
fwrite(STDOUT, $OUTPUT);
?>