/*
Help Script for Table of Contents
 
 CotEditor
 https://coteditor.com
 
 © 2023 1024jp
*/

function toggleTOC() {
    const parentDirectory = window.location.href.split('/').slice(-2)[0]
    
    if (parentDirectory == 'pgs') {
        window.location = "../toc.html";
    } else {
        window.location = "toc.html";
    }
}

// enable toc button in the viewer's toolbar
window.setTimeout(function() {
    window.HelpViewer.showTOCButton(true, toggleTOC, toggleTOC);
    window.HelpViewer.setTOCButton(true);
}, 100);
