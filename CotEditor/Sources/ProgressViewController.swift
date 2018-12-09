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
    
    @objc private dynamic var progress: Progress?
    @objc private dynamic var message: String = ""
    
    private var finishObserver: NSKeyValueObservation?
    private var updateTimer: DispatchSourceTimer?
    
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var descriptionField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.finishObserver?.invalidate()
        self.updateTimer?.cancel()
    }
    
    
    
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.indicator?.doubleValue = self.progress!.fractionCompleted
        self.descriptionField?.stringValue = self.progress!.localizedDescription
        
        // trigger a timer updating UI every 0.1 seconds.
        // -> This is much more performance-efficient than KV-Observing `.fractionCompleted` or `.localizedDescription`. (2018-12 macOS 10.14)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            guard let progress = self?.progress else { return }
            
            self?.indicator?.doubleValue = progress.fractionCompleted
            self?.descriptionField?.stringValue = progress.localizedDescription
        }
        timer.resume()
        self.updateTimer?.cancel()
        self.updateTimer = timer
    }
    
    
    override func dismiss(_ sender: Any?) {
        
        self.updateTimer?.cancel()
        
        // close sheet in an old way
        // -> Otherwise, a meanless empty sheet shows up after another sheet is closed
        //    if the receiver was presented and dismissed during another sheet is already presented. (2018-09 macOS 10.12)
        if let parentWindow = self.presentingViewController?.view.window,
            let sheetWindow = self.view.window,
            parentWindow.sheets.count > 1 {
            parentWindow.endSheet(sheetWindow)
        }
        
        super.dismiss(sender)
    }
    
    
    
    // MARK: Public Methods
    
    /// initialize view with given progress instance
    func setup(progress: Progress, message: String, closesWhenFinished: Bool = false) {
        
        self.progress = progress
        self.message = message
        
        if closesWhenFinished {
            self.finishObserver = progress.observe(\.isFinished) { [weak self] (progress, _) in
                guard progress.isFinished else { return }
                
                DispatchQueue.main.async {
                    self?.dismiss(nil)
                }
            }
        }
    }
    
    
    /// change button to done
    func done() {
        
        self.updateTimer?.cancel()
        
        self.button?.title = "OK".localized
        self.button?.action = #selector(dismiss(_:) as (Any?) -> Void)
        self.button?.keyEquivalent = "\r"
    }
    
    
    
    // MARK: Actions
    
    /// cancel current process
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress?.cancel()
        
        self.dismiss(sender)
    }
    
}
