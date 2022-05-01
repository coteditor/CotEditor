//
//  LineEndingMigrationPanel.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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
import AppKit

struct LineEndingMigrationOptions: OptionSet {
    
    let rawValue: Int
    
    static let replacement = Self(rawValue: 1 << 0)
    static let syntax = Self(rawValue: 1 << 1)
    static let script = Self(rawValue: 1 << 2)
}


final class LineEndingMigrationPanel: NSPanel {
    
    init(options: LineEndingMigrationOptions) {
        
        super.init(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false
        self.contentView = NSHostingView(rootView: LineEndingMigrationView(options: options))
        self.backgroundColor = .white
        self.center()
    }
    
}



private struct LineEndingMigrationView: View {
    
    let options: LineEndingMigrationOptions
    
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 20) {
            self.titleView
            Divider()
            self.contentView
        }
        .padding()
        .edgesIgnoringSafeArea(.top)
    }
    
    
    private var titleView: some View {
        
        VStack(alignment: .center) {
            Image(nsImage: NSImage(named: "AppIcon")!)
            
            (Text("CotEditor ") + Text(Bundle.main.minorVersion).fontWeight(.light))
            .font(.system(size: 32))
            .foregroundColor(.init(white: 0.3))
        }
        .padding(.leading)
        .fixedSize()
    }
    
    
    private var contentView: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Important change on CotEditor 4.2.0")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("From this version, CotEditor handles line endings more strictly.")
            
            if !self.options.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    self.listItem("Due to this change, you may need manual migration for your settings below:")
                    if self.options.contains(.replacement) {
                        self.migrationItem("Multiple replacement definitions")
                    }
                    if self.options.contains(.syntax) {
                        self.migrationItem("Syntax styles")
                    }
                    if self.options.contains(.script) {
                        self.migrationItem("CotEditor scripts")
                    }
                }
            }
            
            self.listItem("`\\n` for the regular expression matches only when the line ending is actually LF. Use `\\R` instead to match any kind of line ending.")
            
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Button("Learn More…") {
                    NSHelpManager.shared.openHelpAnchor("specification_changes_on_4.2.0",
                                                        inBook: Bundle.main.helpBookName)
                }
            }
        }
        
        .frame(width: 300)
    }
    
    
    private func listItem(_ text: LocalizedStringKey) -> some View {
        
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "arrow.forward")
                .foregroundColor(.accentColor)
        }
    }
    
    
    private func migrationItem(_ text: LocalizedStringKey) -> some View {
        
        Label {
            Text(text).fixedSize()
        } icon: {
            Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
                .controlSize(.small)
        }.padding(.leading, 28)
    }
}



struct LineEndingMigrationView_Previews: PreviewProvider {

    static var previews: some View {
        
        LineEndingMigrationView(options: [.script])
    }
    
}
