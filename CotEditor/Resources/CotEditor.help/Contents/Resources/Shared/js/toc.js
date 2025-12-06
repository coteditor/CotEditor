/*
Help Script for Table of Contents
 
 CotEditor
 https://coteditor.com
 
 © 2023-2025 1024jp
*/

const directories = window.location.href.split('/').slice(-3)
const isTop = (directories[1] != 'pgs')

// enable toc button in the viewer's toolbar
document.addEventListener("DOMContentLoaded", () => {
    function toggleTOC() {
        window.location = (isTop) ? "toc.html" : "../toc.html";
    }

    if ('HelpViewer' in window) {
        window.HelpViewer.showTOCButton(true, toggleTOC, toggleTOC);
    }
});

// insert ToC button
if (!isTop) {
    document.addEventListener("DOMContentLoaded", () => {
            const tocButton = document.createElement("a");
            tocButton.className = "toc";
            tocButton.href = "../toc.html";
            
            if (directories.includes("ja.lproj")) {
                tocButton.textContent = "目次";
            } else {
                tocButton.textContent = "Table of Contents";
            }
            document.body.prepend(tocButton);
    });
}
