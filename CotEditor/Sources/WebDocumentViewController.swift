//
//  WebDocumentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa
import WebKit

final class WebDocumentViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var appearanceObserver: NSKeyValueObservation?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    deinit {
        self.appearanceObserver?.invalidate()
    }
    
    
    override var representedObject: Any? {
        
        didSet {
            guard let url = representedObject as? URL else { return }
            
            self.webView?.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.appearanceObserver?.invalidate()
        self.appearanceObserver = self.view.observe(\.effectiveAppearance) { [weak self] (_, _) in
            guard let self = self else { return }

            let isDark = self.view.effectiveAppearance.isDark
            let command = isDark ? "add('dark')" : "remove('dark')"
            self.webView?.evaluateJavaScript("document.body.classList." + command)
            self.view.window?.backgroundColor = isDark ? nil : .white
        }
    }
    
    
    /// set window background programmatically
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        if !self.view.effectiveAppearance.isDark {
            self.view.window!.backgroundColor = .white
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// content web view
    private var webView: WKWebView? {
        
        return self.view as? WKWebView
    }

}



extension WebDocumentViewController: WKNavigationDelegate {
    
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
            webView.apply(styleSheet: ".Sparkle { display: none }")
        #endif
        
        if self.view.effectiveAppearance.isDark {
            webView.evaluateJavaScript("document.body.classList.add('dark')")
        }
    }
    
    
    /// document was loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if let title = webView.title {
            self.view.window?.title = title
        }
    }
    
}



// MARK: -

private extension WKWebView {
    
    /// apply user style sheet to the current page
    func apply(styleSheet: String) {
        
        let js = "var style = document.createElement('style'); style.innerHTML = '\(styleSheet)'; document.head.appendChild(style);"
        
        self.evaluateJavaScript(js)
    }
    
}
