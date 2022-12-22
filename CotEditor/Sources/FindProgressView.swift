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
    ///   - progress: The progress instance to indicate.
    ///   - unit: The unit to count results in the description.
    init(_ label: LocalizedStringKey, progress: FindProgress, unit: Unit) {
        
        assert(!progress.isCancelled)
        assert(!progress.isFinished)
        
        self.progress = progress
        self.unit = unit
        self.label = label
    }
    
    
    var body: some View {
        
        VStack {
            Text(self.label)
                .fontWeight(.semibold)
            
            HStack {
                ProgressView(value: self.progress.fractionCompleted)
                    .progressViewStyle(.linear)
                
                Button(role: .cancel) {
                    self.progress.isCancelled = true
                } label: {
                    Image(systemName: "xmark")
                        .symbolVariant(.circle)
                        .symbolVariant(.fill)
                }.buttonStyle(.borderless)
                    .accessibilityLabel("Cancel")
            }
            
            Text(self.description)
                .monospacedDigit()
                .foregroundColor(.secondaryLabel)
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            self.updateDescription()
        }
        .onReceive(self.timer) { _ in
            self.updateDescription()
        }
        .onChange(of: self.progress.isCancelled) { newValue in
            if newValue {
                self.parent?.dismiss(nil)
            }
        }
        .onChange(of: self.progress.isFinished) { newValue in
            if newValue {
                self.updateDescription()
                self.parent?.dismiss(nil)
            }
        }
        .padding()
        .frame(width: 260)
    }
    
    
    // MARK: Private Methods
    
    /// Update the progress description.
    private func updateDescription() {
        
        self.description = self.unit.format(self.progress.count)
    }
}


private extension FindProgressView.Unit {
    
    func format(_ count: Int) -> LocalizedStringKey {
        
        switch count {
            case 0:
                return "Searching in text…"
            case 1:
                switch self {
                    case .find:
                        return "\(count) string found."
                    case .replacement:
                        return "\(count) string replaced."
                }
            default:
                switch self {
                    case .find:
                        return "\(count) strings found."
                    case .replacement:
                        return "\(count) strings replaced."
                }
        }
    }
}



// MARK: - Preview

struct FindProgressView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        FindProgressView("Label", progress: .init(scope: 0..<100, completedUnit: 30), unit: .find)
    }
}
