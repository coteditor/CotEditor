//
//  ProgressViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2018 1024jp
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

final class ProgressViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic let progress: Progress
    @objc private dynamic let message: String
    
    private var progressObserver: NSKeyValueObservation?
    private var descriptionObserver: NSKeyValueObservation?
    private var finishObserver: NSKeyValueObservation?
    private lazy var progressThrottle = DispatchQueue.main.throttle(delay: .milliseconds(200))
    
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var descriptionField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(progress: Progress, message: String, closesWhenFinished: Bool = false) {
        
        self.progress = progress
        self.message = message
        
        super.init(nibName: nil, bundle: nil)
        
        self.progressObserver = progress.observe(\.fractionCompleted, options: .initial) { [weak self] (progress, _) in
            guard !progress.isIndeterminate else { return }
            
            self?.progressThrottle {
                self?.indicator?.doubleValue = progress.fractionCompleted
            }
        }
        
        self.descriptionObserver = progress.observe(\.localizedDescription, options: .initial) { [weak self] (progress, _) in
            DispatchQueue.main.async {
                self?.descriptionField?.stringValue = progress.localizedDescription
            }
        }
        
        self.finishObserver = progress.observe(\.isFinished) { [weak self] (progress, _) in
            guard closesWhenFinished, progress.isFinished else { return }
            
            DispatchQueue.main.async {
                self?.dismiss(nil)
            }
        }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.progressObserver?.invalidate()
        self.descriptionObserver?.invalidate()
        self.finishObserver?.invalidate()
    }
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("ProgressView")
    }
    
    
    
    // MARK: Public Methods
    
    /// change button to done
    func done() {
        
        self.button?.title = "OK".localized
        self.button?.action = #selector(dismiss(_:) as (Any?) -> Void)
        self.button?.keyEquivalent = "\r"
    }
    
    
    
    // MARK: Actions
    
    /// cancel current process
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress.cancel()
        
        self.dismiss(sender)
    }
    
}
