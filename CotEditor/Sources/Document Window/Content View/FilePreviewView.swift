//
//  FilePreviewView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-09-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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
import QuickLookUI

struct FilePreviewView: View {
    
    @State var item: PreviewDocument
    
    
    var body: some View {
        
        VStack {
            QuickLookView(item: self.item)
                .frame(maxWidth: self.item.previewSize?.width, maxHeight: self.item.previewSize?.height, alignment: .center)
//                .aspectRatio(self.item.previewSize?.aspectRatio, contentMode: .fit)
            Text(self.item.previewItemTitle)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                if self.item.isAlias {
                    Button(String(localized: "Show in Finder", table: "Document")) {
                        NSWorkspace.shared.activateFileViewerSelecting([self.item.previewItemURL])
                    }
                } else {
                    Button(String(localized: "Open with External Editor", table: "Document")) {
                        NSWorkspace.shared.open(self.item.previewItemURL)
                    }
                }
                
                Button(String(localized: "Open as Plain Text", table: "Document")) {
                    let menuItem = NSMenuItem()
                    menuItem.representedObject = self.item.previewItemURL
                    NSApp.sendAction(#selector(DirectoryDocument.openDocumentAsPlainText), to: nil, from: menuItem)
                }
            }
            .padding(.top)
            
            Form {
                LabeledContent(String(localized: "Kind", table: "Document")) {
                    if let type = self.item.fileType, let typeName = UTType(type)?.localizedDescription {
                        Text(typeName)
                    } else {
                        Text("Unknown")
                            .italic()
                            .foregroundStyle(.secondary)
                            .textSelection(.disabled)
                    }
                }
                
                switch self.item.contentAttributes {
                    case let attributes as ImageAttributes:
                        ImageAttributesView(attributes: attributes)
                    case let attributes as MovieAttributes:
                        MovieAttributesView(attributes: attributes)
                    default:
                        EmptyView()
                }
            }
            .monospacedDigit()
            .formStyle(.grouped)
            .frame(maxWidth: 400)
            .accessibilityLabel(String(localized: "Information", table: "Document", comment: "accessibility label"))
        }
        .scenePadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thickMaterial)
    }
}


private struct QuickLookView: NSViewRepresentable {
    
    typealias NSViewType = QLPreviewView
    
    var item: any QLPreviewItem
    
    
    func makeNSView(context: Context) -> QLPreviewView {
        
        let view = QLPreviewView(frame: .zero, style: .compact) ?? QLPreviewView()
        view.shouldCloseWithWindow = false
        
        return view
    }
    
    
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        
        nsView.previewItem = self.item
    }
    
    
    static func dismantleNSView(_ nsView: QLPreviewView, coordinator: ()) {
        
        nsView.close()
    }
    
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: QLPreviewView, context: Context) -> CGSize? {
        
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 512, height: 512))
    }
}


struct ImageAttributesView: View {
    
    var attributes: ImageAttributes
    
    
    var body: some View {
        
        LabeledContent(String(localized: "Dimensions", table: "Document"),
                       value: self.attributes.dimensions.formatted)
        LabeledContent(String(localized: "Image DPI", table: "Document"),
                       value: String(localized: "\(self.attributes.dotsPerInch, format: .number) pixels/inch", table: "Document"))
        if let colorSpace = self.attributes.colorSpace {
            LabeledContent(String(localized: "Color space", table: "Document"),
                           optional: colorSpace.colorSpaceModel.localizedName)
            LabeledContent(String(localized: "Color profile", table: "Document"),
                           optional: colorSpace.localizedName)
        }
    }
}


struct MovieAttributesView: View {
    
    var attributes: MovieAttributes
    
    
    var body: some View {
        
        LabeledContent(String(localized: "Dimensions", table: "Document"),
                       value: self.attributes.dimensions.formatted)
        LabeledContent(String(localized: "Duration", table: "Document"),
                       value: self.attributes.duration,
                       format: .time(pattern: self.attributes.duration.naturalPattern))
    }
}


private extension CGSize {
    
    /// The human-readable representation.
    var formatted: String {
        
        func format(_ value: Double) -> String { Int(value).formatted(.number.grouping(.never)) }
        
        return "\(format(self.width))×\(format(self.height))"
    }
}


private extension Duration {
    
    /// The natural format pattern based on the length.
    var naturalPattern: TimeFormatStyle.Pattern {
        
        (self.components.seconds >= 60 * 60) ? .hourMinuteSecond : .minuteSecond
    }
}


// MARK: - Preview

#Preview {
    let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")!
    let item = try! PreviewDocument(contentsOf: url, ofType: UTType.icns.identifier)
    
    return FilePreviewView(item: item)
}

#Preview("ImageAttributesView") {
    ImageAttributesView(attributes: ImageAttributes(dimensions: .init(width: 1024, height: 900),
                                                    dotsPerInch: 72,
                                                    colorSpace: .extendedGenericGamma22Gray))
    
    ImageAttributesView(attributes: ImageAttributes(dimensions: .init(width: 0, height: 0),
                                                    dotsPerInch: 0.5))
}
