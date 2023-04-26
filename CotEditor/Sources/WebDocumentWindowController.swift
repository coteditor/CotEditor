//
//  WebDocumentWindowController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

import AppKit
import WebKit

final class WebDocumentWindowController: NSWindowController {
    
    // MARK: Lifecycle
    
    convenience init(fileURL: URL) {
        
        let viewController = WebDocumentViewController(fileURL: fileURL)
        let window = NSWindow(contentViewController: viewController)
        window.setContentSize(NSSize(width: 480, height: 480))
        window.styleMask = [.closable, .resizable, .titled]
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .textBackgroundColor
        window.center()
        
        self.init(window: window)
    }
}



// MARK: -

private final class WebDocumentViewController: NSViewController {
    
    // MARK: Private Properties
    
    private let fileURL: URL
    
    
    // MARK: Lifecycle
    
    init(fileURL: URL) {
        
        self.fileURL = fileURL
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.loadFileURL(self.fileURL, allowingReadAccessTo: self.fileURL)
        
        self.view = webView
        
        // hide Sparkle if not used
        #if !SPARKLE
            let source = "document.querySelector('.Sparkle').style.display='none'"
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

            webView.configuration.userContentController.addUserScript(script)
        #endif
    }
}


extension WebDocumentViewController: WKNavigationDelegate {
    
    // MARK: Navigation Delegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        if let title = webView.title {
            webView.window?.title = title
        }
        
        // avoid flashing view on the first launch in Dark Mode
        webView.animator().isHidden = false
    }
    
    
    /// Open external link in default browser.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard
            navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url, url.host != nil,
            NSWorkspace.shared.open(url)
        else { return decisionHandler(.allow) }
        
        decisionHandler(.cancel)
    }
}
