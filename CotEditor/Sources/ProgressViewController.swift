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
//  © 2014-2022 1024jp
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

import Combine
import Cocoa

final class ProgressViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc private dynamic let progress: Progress
    @objc private dynamic let message: String
    private let closesAutomatically: Bool
    
    private var progressSubscriptions: Set<AnyCancellable> = []
    private var completionSubscriptions: Set<AnyCancellable> = []
    
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var descriptionField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view with given progress instance.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - progress: The progress instance to indicate.
    ///   - message: The text to display as the message label of the indicator.
    ///   - closesAutomatically: Whether dismiss the view when the progress is finished.
    init?(coder: NSCoder, progress: Progress, message: String, closesAutomatically: Bool = true) {
        
        assert(!progress.isCancelled)
        assert(!progress.isFinished)
        
        self.progress = progress
        self.message = message
        self.closesAutomatically = closesAutomatically
        
        super.init(coder: coder)
        
        progress.publisher(for: \.isFinished)
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.done() }
            .store(in: &self.completionSubscriptions)
        
        progress.publisher(for: \.isCancelled)
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismiss(nil) }
            .store(in: &self.completionSubscriptions)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard
            let indicator = self.indicator,
            let descriptionField = self.descriptionField
            else { return assertionFailure() }
        
        self.progressSubscriptions.removeAll()
        
        self.progress.publisher(for: \.fractionCompleted, options: .initial)
            .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.doubleValue, on: indicator)
            .store(in: &self.progressSubscriptions)
        
        self.progress.publisher(for: \.localizedDescription, options: .initial)
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.stringValue, on: descriptionField)
            .store(in: &self.progressSubscriptions)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.progressSubscriptions.removeAll()
        self.completionSubscriptions.removeAll()
    }
    
    
    
    // MARK: Public Methods
    
    /// Change the state of progress to finished.
    func done() {
        
        self.completionSubscriptions.removeAll()
        
        if self.closesAutomatically {
            return self.dismiss(self)
        }
        
        guard let button = self.button else { return assertionFailure() }
        
        self.descriptionField?.stringValue = self.progress.localizedDescription
        
        button.title = "OK".localized
        button.action = #selector(dismiss(_:) as (Any?) -> Void)
        button.keyEquivalent = "\r"
    }
    
    
    
    // MARK: Actions
    
    /// Cancel current process.
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress.cancel()
    }
    
}
