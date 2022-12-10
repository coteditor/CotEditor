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
//  © 2016-2020 1024jp
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
    
    private var loadingNavigation: WKNavigation?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override var representedObject: Any? {
        
        didSet {
            guard
                let url = representedObject as? URL,
                let webView = self.webView
            else { return assertionFailure() }
            
            self.loadingNavigation = webView.loadFileURL(url, allowingReadAccessTo: url)
            webView.isHidden = true
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // hide Sparkle if not used
        #if !SPARKLE
            let source = "document.querySelector('.Sparkle').style.display='none'"
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

            self.webView?.configuration.userContentController.addUserScript(script)
        #endif
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // set window here since `self.view.window` is still nil in `viewDidLoad()`.
        assert(self.view.window != nil)
        self.view.window?.backgroundColor = .textBackgroundColor
        self.view.window?.bind(.title, to: self.webView!, withKeyPath: #keyPath(title))
    }
    
    
    
    // MARK: Private Methods
    
    /// content web view
    private var webView: WKWebView? {
        
        self.view as? WKWebView
    }
    
}



extension WebDocumentViewController: WKNavigationDelegate {
    
    // MARK: Navigation Delegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // avoid flashing view on the first launch in Dark Mode
        if navigation == self.loadingNavigation {
            webView.animator().isHidden = false
        }
    }
    
    
    /// open external link in default browser
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard
            navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url, url.host != nil,
            NSWorkspace.shared.open(url)
        else { return decisionHandler(.allow) }
        
        decisionHandler(.cancel)
    }
    
}
