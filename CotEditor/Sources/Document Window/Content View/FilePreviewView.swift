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
//  © 2024 1024jp
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
                .aspectRatio(self.item.previewSize?.aspectRatio, contentMode: .fit)
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
            
            Group {
                switch self.item.contentAttributes {
                    case .image(let attributes):
                        ImageAttributesView(attributes: attributes)
                    default:
                        EmptyView()
                }
            }
            .monospacedDigit()
            .formStyle(.grouped)
            .frame(maxWidth: 400)
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
        
        Form {
            LabeledContent(String(localized: "Image size", table: "Document"),
                           value: self.attributes.pixelSize.formatted)
            LabeledContent(String(localized: "Image DPI", table: "Document"),
                           value: String(localized: "\(self.attributes.dotsPerInch, format: .number) pixels/inch", table: "Document"))
            LabeledContent(String(localized: "Color model", table: "Document")) {
                if let name = self.attributes.colorSpace?.colorSpaceModel.localizedName {
                    Text(name)
                } else {
                    Text(verbatim: "–")
                        .foregroundStyle(.tertiary)
                }
            }
            LabeledContent(String(localized: "ColorSync profile", table: "Document")) {
                if let name = self.attributes.colorSpace?.localizedName {
                    Text(name)
                } else {
                    Text(verbatim: "–")
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}


private extension PixelSize {
    
    var formatted: String {
        
        String(localized: "\(self.width) × \(self.height) pixels", table: "Document")
    }
}



// MARK: - Preview

#Preview {
    let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")!
    let item = try! PreviewDocument(contentsOf: url, ofType: UTType.icns.identifier)
    
    return FilePreviewView(item: item)
}

#Preview("ImageAttributesView") {
    ImageAttributesView(attributes: ImageAttributes(pixelSize: .init(width: 1024, height: 900),
                                                    dotsPerInch: 72,
                                                    colorSpace: .extendedGenericGamma22Gray))
    
    ImageAttributesView(attributes: ImageAttributes(pixelSize: .init(width: 0, height: 0),
                                                    dotsPerInch: 0.5))
}
