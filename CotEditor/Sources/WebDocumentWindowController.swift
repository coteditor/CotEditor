/*
 
 WebDocumentWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-05-20.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa
import WebKit

final class WebDocumentWindowController: NSWindowController, WebPolicyDelegate {
    
    // MARK: Private Properties
    
    private let fileURL: URL
    
    @IBOutlet private weak var webView: WebView?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init?(documentName: String) {
        
        guard let fileURL = Bundle.main.url(forResource: documentName, withExtension: "html") else { return nil }
        
        self.fileURL = fileURL
        
        super.init(window: nil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var windowNibName: String? {
        
        return "WebDocumentWindow"
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// let webView load document file
    override func windowDidLoad() {
        
        super.windowDidLoad()
    
        let request = URLRequest(url: self.fileURL)
        self.webView?.mainFrame.load(request)
    }
    
    
    
    // MARK: Delegate
    
    /// open external link in default browser
    func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        guard let url = request.url, url.host != nil else {
            listener.use()
            return
        }
        
        NSWorkspace.shared().open(url)
    }

}
