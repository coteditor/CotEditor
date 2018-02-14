/*
 
 WebDocumentWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-20.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa
import WebKit

final class WebDocumentWindowController: NSWindowController {
    
    // MARK: Public Properties
    
    var fileURL: URL? {
        didSet {
            guard let url = self.fileURL else { return }
            
            // send request
            let request = URLRequest(url: url)
            self.webView?.load(request)
        }
    }
    
    
    
    // MARK: -
    // MARK: Window Controller Methods
    
    /// let webView load document file
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        self.window?.backgroundColor = .white
        
        // set webView programmically
        let webView = WKWebView(frame: .zero)
        self.window?.contentView = webView
        webView.navigationDelegate = self
    }
    
    
    // MARK: Private Methods
    
    /// content web view
    private var webView: WKWebView? {
        
        return self.window?.contentView as? WKWebView
    }

}



extension WebDocumentWindowController: WKNavigationDelegate {
    
    // MARK: Navigation Delegate
    
    /// open external link in default browser
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard
            navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url, url.host != nil,
            NSWorkspace.shared.open(url)
            else { return decisionHandler(.allow) }
        
        decisionHandler(.cancel)
    }
    
    
    /// receive web content
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
        #if APPSTORE
            webView.apply(styleSheet: ".non-appstore { display: none }")
        #endif
    }
    
    
    /// document was loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if let title = webView.title {
            self.window?.title = title
        }
    }
    
}



// MARK: -

private extension WKWebView {
    
    /// apply user style sheet to current page
    func apply(styleSheet: String) {
        
        let js = "var style = document.createElement('style'); style.innerHTML = '\(styleSheet)'; document.head.appendChild(style);"
        
        self.evaluateJavaScript(js, completionHandler: nil)
    }
    
}
