//
//  PopoverHolderView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-09-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

extension View {
    
    func detachablePopover<Content>(isPresented: Binding<Bool>, arrowEdge: Edge = .top, content: @escaping () -> Content) -> some View where Content: View {
        
        self.background(PopoverHolderView(isPresented: isPresented, arrowEdge: arrowEdge, content: content))
    }
}



// MARK: - Private

private extension Edge {
    
    var rectEdge: NSRectEdge {
        
        switch self {
            case .trailing: .maxX
            case .leading:  .minX
            case .top:      .minY
            case .bottom:   .maxY
        }
    }
}


private struct PopoverHolderView<T: View>: NSViewRepresentable {
    
    @Binding var isPresented: Bool
    let arrowEdge: Edge
    var content: () -> T
    
    
    func makeNSView(context: Context) -> NSView {
        
        NSView()
    }
    
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
        context.coordinator.setVisible(self.isPresented, in: nsView, preferredEdge: self.arrowEdge.rectEdge)
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(state: self._isPresented, content: self.content)
    }
    
    
    
    @MainActor final class Coordinator: NSObject, NSPopoverDelegate {
        
        private let popover: NSPopover
        private let state: Binding<Bool>
        
        
        init<V: View>(state: Binding<Bool>, content: @escaping () -> V) {
            
            self.popover = NSPopover()
            self.state = state
            
            super.init()
            
            self.popover.delegate = self
            self.popover.contentViewController = NSHostingController(rootView: content())
            self.popover.behavior = .transient
        }
        
        
        func setVisible(_ isPresented: Bool, in view: NSView, preferredEdge: NSRectEdge) {
            if isPresented {
                self.popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
            } else {
                self.popover.close()
            }
        }
        
        
        func popoverDidClose(_ notification: Notification) {
            
            self.state.wrappedValue = false
        }
        
        
        func popoverShouldDetach(_ popover: NSPopover) -> Bool {
            
            true
        }
    }
}
