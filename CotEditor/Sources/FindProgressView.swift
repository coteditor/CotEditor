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

import SwiftUI

struct FindProgressView: View {
    
    enum Unit {
        
        case find
        case replacement
    }
    
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work

    @ObservedObject private var progress: FindProgress
    private let unit: Unit
    private let label: LocalizedStringKey
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var description: LocalizedStringKey = ""
    
    
    // MARK: View
    
    /// Initialize view from a storyboard with given progress instance.
    ///
    /// - Parameters:
    ///   - label: The text to display as the label of the indicator.
    ///   - unit: The unit to count results in the description.
    ///   - progress: The progress instance to indicate.
    init(_ label: LocalizedStringKey, unit: Unit, progress: FindProgress) {
        
        assert(!progress.isCancelled)
        assert(!progress.isFinished)
        
        self.progress = progress
        self.unit = unit
        self.label = label
        
        self.updateDescription()
    }
    
    
    var body: some View {
        
        VStack(alignment: .center) {
            ProgressView(value: self.progress.fractionCompleted) {
                Text(self.label)
                    .fontWeight(.semibold)
            }.progressViewStyle(.linear)
            
            HStack {
                Text(self.description)
                    .monospacedDigit()
                    .foregroundColor(.secondaryLabel)
                    .controlSize(.small)
                    
                Spacer()
                
                if self.progress.isFinished {
                    Button("Done") {
                        self.parent?.dismiss(nil)
                    }.keyboardShortcut(.defaultAction)
                } else {
                    Button("Cancel", role: .cancel) {
                        self.progress.isCancelled = true
                    }
                }
            }.controlSize(.small)
        }
        .onReceive(self.timer) { _ in
            self.updateDescription()
        }
        .onChange(of: self.progress.isCancelled) { isCancelled in
            if isCancelled {
                self.parent?.dismiss(nil)
            }
        }
        .onChange(of: self.progress.isFinished) { isFinished in
            if isFinished {
                self.updateDescription()
                self.timer.upstream.connect().cancel()
            }
        }
        .padding()
        .frame(width: 260)
    }
    
    
    // MARK: Public Methods
    
    /// Update the progress description.
    private func updateDescription() {
        
        self.description = self.unit.format(self.progress)
    }
}


private extension FindProgressView.Unit {
    
    func format(_ progress: FindProgress) -> LocalizedStringKey {
        
        switch progress.count {
            case 0:
                if progress.isFinished {
                    return "Not found"
                } else {
                    return "Searching in text…"
                }
            case 1:
                switch self {
                    case .find:
                        return "\(progress.count) string found."
                    case .replacement:
                        return "\(progress.count) string replaced."
                }
            default:
                switch self {
                    case .find:
                        return "\(progress.count) strings found."
                    case .replacement:
                        return "\(progress.count) strings replaced."
                }
        }
    }
}



// MARK: - Preview

struct FindProgressView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        FindProgressView("Label", unit: .find, progress: .init(scope: 0..<100))
    }
}
