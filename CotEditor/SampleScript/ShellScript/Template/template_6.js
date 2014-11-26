#!/usr/bin/osascript -l JavaScript
//
// Sample JavaScript Script for CotEditor
//
// This script uses JavaScript for Automation on Yosemite.



// set CotEditor
CotEditor = Application('CotEditor')

// set front most document
document = CotEditor.documents[0]


selection = document.selection
console.log(selection.contents())
selection.commentOut()
