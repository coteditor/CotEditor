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
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // hide Sparkle if not used
        #if APPSTORE
            let source = "document.querySelector('.Sparkle').style.display='none'"
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

            self.webView?.configuration.userContentController.addUserScript(script)
        #endif
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        assert(self.view.window != nil)
        
        // set window here since `self.view.window` is still nil in `viewDidLoad()`.
        self.view.window?.backgroundColor = .textBackgroundColor
        self.view.window?.bind(.title, to: self.webView!, withKeyPath: #keyPath(title))
        
        guard
            let webView = self.webView,
            let url = self.representedObject as? URL
            else { return assertionFailure() }
        
        if webView.url != url {
            webView.loadFileURL(url, allowingReadAccessTo: url)
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
    
}
