//
//  FindProgressView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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

import SwiftUI
import TextFind

struct FindProgressView: View {
    
    var dismiss: () -> Void = { }
    
    @State private var progress: FindProgress
    private var action: TextFind.Action
    private var label: String
    
    private let timer = Timer.publish(every: 0.1, tolerance: 0.1, on: .main, in: .common).autoconnect()
    @State private var description: String = ""
    
    
    // MARK: View
    
    /// Initializes a view from a storyboard with given progress instance.
    ///
    /// - Parameters:
    ///   - label: The text to display as the label of the indicator.
    ///   - progress: The progress instance to indicate.
    ///   - action: The find action type for count results in the description.
    init(_ label: String, progress: FindProgress, action: TextFind.Action) {
        
        assert(!progress.state.isTerminated)
        
        self.progress = progress
        self.action = action
        self.label = label
    }
    
    
    var body: some View {
        
        HStack {
            ProgressView(value: self.progress.fractionCompleted) {
                Text(self.label)
            } currentValueLabel: {
                Text(self.description)
            }
            
            Button(.cancel, systemImage: "xmark", role: .cancel) {
                self.progress.cancel()
            }
            .symbolVariant(.circle.fill)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .onAppear {
            self.updateDescription()
        }
        .onReceive(self.timer) { _ in
            self.updateDescription()
        }
        .onChange(of: self.progress.state) { _, newValue in
            switch newValue {
                case .ready, .processing:
                    break
                case .finished:
                    self.updateDescription()
                    self.dismiss()
                case .cancelled:
                    self.dismiss()
            }
        }
        .scenePadding()
        .frame(width: 260)
    }
    
    
    // MARK: Private Methods
    
    /// Updates the current value label.
    private func updateDescription() {
        
        self.description = self.action.processMessage(self.progress.count)
    }
}


private extension TextFind.Action {
    
    /// The formatted result message.
    ///
    /// - Parameter count: The number of processed items.
    /// - Returns: The formatted string.
    func processMessage(_ count: Int) -> String {
        
        switch self {
            case _ where count == 0:
                String(localized: "Searching in text…", table: "TextFind")
            case .find:
                String(localized: "\(count) strings found.", table: "TextFind",
                       comment: "progress report in find progress dialog")
            case .replace:
                String(localized: "\(count) strings replaced.", table: "TextFind",
                       comment: "progress report in find progress dialog")
        }
    }
}


// MARK: - Preview

#Preview {
    let progress = FindProgress(scope: 0..<100)
    progress.updateCompletedUnit(to: 30)
    
    return FindProgressView("Label", progress: progress, action: .find)
}
