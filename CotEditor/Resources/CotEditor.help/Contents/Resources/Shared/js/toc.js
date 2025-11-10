/*
Help Script for Table of Contents
 
 CotEditor
 https://coteditor.com
 
 © 2023-2025 1024jp
*/

// enable toc button in the viewer's toolbar
if ('HelpViewer' in window) {
    function toggleTOC() {
        const parentDirectory = window.location.href.split('/').slice(-2)[0]
        
        if (parentDirectory == 'pgs') {
            window.location = "../toc.html";
        } else {
            window.location = "toc.html";
        }
    }
    
    window.setTimeout(function() {
        window.HelpViewer.showTOCButton(true, toggleTOC, toggleTOC);
    }, 100);
}
