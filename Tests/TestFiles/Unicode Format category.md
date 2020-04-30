# Unicode General Category “Format” (Cf)

last modified: 2020-04-30
[Unicode 13.0.0](http://www.unicode.org/versions/Unicode13.0.0/)


## List of All characters in Format category

|   | code point             | qty | name                        | block                               |   | note  |
| - | ---------------------- | --: | --------------------------- | ----------------------------------- | - | ----- |
|   | 00AD                   |   1 | Soft Hyphen                 | Latin-1 Supplement                  | ­  | 1語内の単語境界を示す（改行時に出現） |
| - | 0600..0605             |   6 | Arabic …                    | Arabic                              | ؀ |  |
| Y | 061C                   |   1 | Arabic Letter Mark          | Arabic                              |   | 双方向テキスト制御記号[^1] |
| - | 06DD                   |   1 | Arabic End Of Ayah          | Arabic                              | ۝ |  |
| - | 070F                   |   1 | Syriac Abbreviation Mark    | Syriac                              | ܏  |  |
| - | 08E2                   |   1 | Arabic Disputed End of Ayah | Arabic Extended-A                   | ࣢|  |
| - | 180E                   |   1 | Mongolian Vowel Separator   | Mongolian                           | ᠎ | モンゴル語で前後の文字を特別な形に変える |
| Y | 200B                   |   1 | Zero Width Space            | General Punctuation[^2]             |   | 改行可能位置を示す（ゼロ幅スペース） |
| Y | 200C                   |   1 | Zero Width Non-Joiner       | General Punctuation                 |   | リガチャを抑止する（ゼロ幅非接合子） |
| - | 200D                   |   1 | Zero Width Joiner           | General Punctuation                 |   | リガチャを促進する / 絵文字の糊（ゼロ幅接合子） |
| Y | 200E..200F, 202A..202E |   9 | (Bidi controls)             | General Punctuation                 |   | 双方向テキスト制御記号 |
| Y | 2060                   |   1 | Word Joiner                 | General Punctuation                 |   | 前後での改行を禁止する (BOMの代わり) |
|   | 2061                   |   1 | Function Application        | General Punctuation                 |   | 数学用制御文字 |
|   | 2062..2064             |   3 | Invisible …                 | General Punctuation                 |   | 数学用制御文字 |
| Y | 2066..2069             |   3 | (Bidi controls)             | General Punctuation                 |   | 双方向テキスト制御記号 |
| Y | 206A..206F             |   6 | (Bidi controls)             | General Punctuation                 |   | 双方向テキスト制御記号 (deprecated in Unicode 3.0) |
| Y | FEFF                   |   1 | Zero Width No-Break Space   | Arabic Presentation Forms-B         |   | BOM |
| Y | FFF9..FFFB             |   3 | Interlinear Annotation …    | Specials                            |   | ルビ制御文字 |
| - | 110BD, 110CD           |   2 | Kaithi Number Sign …        | Kaithi                              | 𑂽|  |
|   | 13430..13438           |   9 | Egyptian Hieroglyph …       | Egyptian Hieroglyph Format Controls |   |  |
|   | 1BCA0..1BCA3           |   4 | Shorthand Format …          | Shorthand Format Controls           |   | 速記書式制御記号 |
| - | 1D173..1D17A           |   8 | Musical Symbol …            | Musical Symbols                     |   |  |
|   | E0001                  |   1 | Language Tag                | Tags[^3]                            |   | (deprecated) |
| - | E0020..E007F           |  96 | Tag …                       | Tags                                |   | formerly not recommended but now used for flag emojis[^4] |


## List of formatting-like characters in other categories (just randomly picked-up)

|   | code point             | Qty | Name                        | block                               | category          |
| - | ---------------------- | --: | --------------------------- | ----------------------------------- | ----------------- |
| - | 034F                   |   1 | Combining Grapheme Joiner   | Combining Diacritical Marks         | Nonspacing Mark   |


## References

[^1]: [Arabic letter mark - Wikipedia](https://en.wikipedia.org/wiki/Arabic_letter_mark)
[^2]: [General Punctuation (Range: 2000–206F) - Unicode.org](https://unicode.org/charts/PDF/U2000.pdf)
[^3]: [Tags (Range: E0000–E007F) - Unicode.org](https://unicode.org/charts/PDF/UE0000.pdf)
[^4]: [Emoji Tag Sequence for Subdivision Flags - emojipedia](https://emojipedia.org/emoji-tag-sequence/)
