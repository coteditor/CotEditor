//
//  WindowContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

import AppKit

final class WindowContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var documentViewItem: NSSplitViewItem?
    @IBOutlet private weak var inspectorViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(toggleInspector_):
                (item as? NSMenuItem)?.title = self.isInspectorShown
                    ? String(localized: "Hide Inspector")
                    : String(localized: "Show Inspector")
                
            case #selector(getInfo):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .document) ? .on : .off
                
            case #selector(toggleOutlineMenu):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .outline) ? .on : .off
                
            case #selector(toggleWarningsPane):
                (item as? NSMenuItem)?.state = self.isInspectorShown(pane: .warnings) ? .on : .off
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Public Methods
    
    /// The view controller of the main pane that containing the editor.
    var documentViewController: DocumentViewController? {
        
        self.documentViewItem?.viewController as? DocumentViewController
    }
    
    
    /// Open the desired inspector pane.
    ///
    /// - Parameter pane: The inspector pane to open.
    func showInspector(pane: InspectorPane) {
        
        self.setInspectorShown(true, pane: pane, animate: true)
    }
    
    
    
    // MARK: Action Messages
    
    /// Toggle visibility of the inspector.
    @IBAction func toggleInspector_(_ sender: Any?) {  // FIXME: Restore action name
        
        NSAnimationContext.current.withAnimation {
            self.isInspectorShown.toggle()
        }
    }
    
    
    /// Toggle visibility of the document inspector pane.
    @IBAction func getInfo(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .document)
    }
    
    
    /// Toggle visibility of the outline pane.
    @IBAction func toggleOutlineMenu(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .outline)
    }
    
    
    /// Toggle visibility of warnings pane.
    @IBAction func toggleWarningsPane(_ sender: Any?) {
        
        self.toggleVisibilityOfInspector(pane: .warnings)
    }
    
    
    
    // MARK: Private Methods
    
    /// split view item to view controller
    private var inspectorViewController: InspectorViewController? {
        
        self.inspectorViewItem?.viewController as? InspectorViewController
    }
    
    
    /// whether inspector is opened
    private var isInspectorShown: Bool {
        
        get { self.inspectorViewItem?.isCollapsed == false }
        set { self.inspectorViewItem?.isCollapsed = !newValue }
    }
    
    
    /// set visibility of the inspector and switch pane
    private func setInspectorShown(_ shown: Bool, pane: InspectorPane? = nil, animate: Bool = false) {
        
        NSAnimationContext.current.withAnimation(animate) {
            self.isInspectorShown = shown
        }
    }
    
    
    /// whether the given pane in the inspector is currently shown
    private func isInspectorShown(pane: InspectorPane) -> Bool {
        
        self.isInspectorShown && (self.inspectorViewController?.selectedPane == pane)
    }
    
    
    /// toggle visibility of pane in the inspector
    private func toggleVisibilityOfInspector(pane: InspectorPane) {
        
        self.setInspectorShown(!self.isInspectorShown(pane: pane), pane: pane, animate: true)
    }
}
