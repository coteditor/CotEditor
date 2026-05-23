//
//  ContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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
import SwiftUI

final class ContentViewController: NSViewController {
    
    // MARK: Public Properties
    
    var document: DataDocument?  { didSet { self.updateDocument(from: oldValue) } }
    
    private(set) var hostedViewController: NSViewController
    
    
    // MARK: Lifecycle
    
    init(document: DataDocument?) {
        
        self.document = document
        self.hostedViewController = Self.viewController(document: document)
        
        super.init(nibName: nil, bundle: nil)
        
        self.addChild(self.hostedViewController)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        
        let view = NSView()
        view.embedSubview(self.hostedViewController.view)
        
        self.view = view
    }
    
    
    // MARK: Private Methods
    
    /// Updates the hosted view controller when the document changes.
    ///
    /// - Parameter oldDocument: The previous document.
    private func updateDocument(from oldDocument: DataDocument?) {
        
        guard oldDocument != self.document else { return }
        
        // remove only the hosted view controller to preserve accessories such as the status bar
        // -> Split view item accessory controllers can be attached as children (2026-05, macOS 26).
        self.hostedViewController.viewIfLoaded?.removeFromSuperview()
        self.hostedViewController.removeFromParent()
        
        self.hostedViewController = Self.viewController(document: self.document)
        self.addChild(self.hostedViewController)
        self.viewIfLoaded?.embedSubview(self.hostedViewController.view)
    }
    
    
    /// Creates a new view controller with the passed-in document.
    ///
    /// - Parameter document: The represented document.
    /// - Returns: A view controller.
    private static func viewController(document: DataDocument?) -> sending NSViewController {
        
        switch document {
            case let document as Document:
                DocumentViewController(document: document)
            case let document as PreviewDocument:
                NSHostingController(rootView: FilePreviewView(item: document))
            case .none:
                NSHostingController(rootView: NoDocumentView())
            default:
                preconditionFailure()
        }
    }
}


private extension NSView {
    
    /// Adds a subview constrained to fill the receiver.
    ///
    /// - Parameter subview: The subview to embed.
    func embedSubview(_ subview: NSView) {
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            subview.topAnchor.constraint(equalTo: self.topAnchor),
            subview.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
