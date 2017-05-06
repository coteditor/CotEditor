/*
 
 KeyBindingsPaneController.m
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class KeyBindingsPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private lazy var menuViewController: NSViewController = self.storyboard!.instantiateController(withIdentifier: "MenuKeyBindingsViewController") as! NSViewController
    private lazy var textViewController: NSViewController = self.storyboard!.instantiateController(withIdentifier: "SnippetKeyBindingsViewController") as! NSViewController
    
    @IBOutlet private weak var tabView: NSTabView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup tab views
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tabView?.tabViewItem(at: 0).view = self.menuViewController.view
        self.tabView?.tabViewItem(at: 1).view = self.textViewController.view
    }
    
}
