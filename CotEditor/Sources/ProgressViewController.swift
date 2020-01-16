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
//  © 2014-2020 1024jp
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
    
    // MARK: Public Properties
    
    var closesAutomatically = true
    
    
    // MARK: Private Properties
    
    @objc private dynamic var progress: Progress?
    @objc private dynamic var message: String = ""
    
    private var finishObserver: NSKeyValueObservation?
    private var cancelObserver: NSKeyValueObservation?
    private var updateTimer: DispatchSourceTimer?
    
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var descriptionField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.finishObserver?.invalidate()
        self.cancelObserver?.invalidate()
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
        timer.setEventHandler { [weak self] in self?.updateProgress() }
        timer.resume()
        self.updateTimer?.cancel()
        self.updateTimer = timer
    }
    
    
    override func dismiss(_ sender: Any?) {
        
        self.updateTimer?.cancel()
        self.updateTimer = nil
        
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
    
    /// Initialize view with given progress instance.
    /// - Parameters:
    ///   - progress: The progress instance to indicate.
    ///   - message: The text to display as the message label of the indicator.
    func setup(progress: Progress, message: String) {
        
        self.progress = progress
        self.message = message
        
        self.finishObserver?.invalidate()
        self.finishObserver = progress.observe(\.isFinished, options: .initial) { [weak self] (progress, _) in
            guard progress.isFinished else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.done()
            }
        }
        
        self.cancelObserver?.invalidate()
        self.cancelObserver = progress.observe(\.isCancelled, options: .initial) { [weak self] (progress, _) in
            guard progress.isCancelled else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(nil)
            }
        }
    }
    
    
    /// Change the state of progress to finished.
    func done() {
        
        self.updateTimer?.cancel()
        self.updateTimer = nil
        
        if self.closesAutomatically {
            self.dismiss(self)
            
        } else {
            self.updateProgress()
            
            guard let button = self.button else { return assertionFailure() }
            
            button.title = "OK".localized
            button.action = #selector(dismiss(_:) as (Any?) -> Void)
            button.keyEquivalent = "\r"
            button.isHidden = false
        }
    }
    
    
    
    // MARK: Actions
    
    /// Cancel current process.
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress?.cancel()
    }
    
    
    
    // MARK: Private Methods
    
    /// Apply the latest progress state to UI.
    private func updateProgress() {
        
        guard
            let progress = self.progress,
            let indicator = self.indicator
            else { return assertionFailure() }
        
        if indicator.doubleValue != progress.fractionCompleted {
            indicator.doubleValue = progress.fractionCompleted
        }
        if self.descriptionField?.stringValue != progress.localizedDescription {
            self.descriptionField?.stringValue = progress.localizedDescription
        }
    }
    
}
