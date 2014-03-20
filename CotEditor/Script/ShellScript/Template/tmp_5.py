#!/usr/bin/python
#
# %%%{CotEditorXInput=Selection}%%%
# %%%{CotEditorXOutput=ReplaceSelection}%%%

import sys, math

def lineFormat(lineCount):
    format = "%%%dd| %%s" % int(math.ceil(math.log10(lineCount)))
    return format

def addLineNumber(text):
    newText = []
    lines = text.splitlines(True)
    format = lineFormat(len(lines))
    for index, line in enumerate(lines):
        line = format % (index + 1, line)
        newText.append(line)
    return "".join(newText)

preText = unicode(sys.stdin.read(), "utf-8")
postText = addLineNumber(preText)
sys.stdout.write(postText.encode("utf-8"))
