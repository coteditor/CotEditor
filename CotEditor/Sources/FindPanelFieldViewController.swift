/*
 
 FindPanelFieldViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-26.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private dynamic let textFinder = TextFinder.shared
    
    private dynamic var resultMessage: String?  // binding
    private weak var currentResultMessageTarget: NSLayoutManager?  // grab layoutManager instead of NSTextView to use weak reference
    
    private lazy var regexReferenceViewController = DetachablePopoverViewController(nibName: "RegexReferenceView", bundle: nil)!
    private lazy var preferencesViewController = NSViewController(nibName: "FindPreferencesView", bundle: nil)!
    
    @IBOutlet private var findTextView: NSTextView?
    @IBOutlet private weak var findHistoryMenu: NSMenu?
    @IBOutlet private weak var replaceHistoryMenu: NSMenu?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.findHistory.rawValue)
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.replaceHistory.rawValue)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.updateFindHistoryMenu()
        self.updateReplaceHistoryMenu()
        
        // observe default change for the history menus
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.findHistory.rawValue, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.replaceHistory.rawValue, context: nil)
    }
    
    
    /// make find field initial first responder
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make find text view the initial first responder to focus it on showWindow(_:)
        self.view.window?.initialFirstResponder = self.findTextView
    }
    
    
    /// observed user defaults are changed
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case DefaultKeys.findHistory.rawValue:
            self.updateFindHistoryMenu()
        case DefaultKeys.replaceHistory.rawValue:
            self.updateReplaceHistoryMenu()
        default: break
        }
    }
    
    
    
    // MARK: Text View Delegate
    
    /// find string did change
    func textDidChange(_ notification: Notification) {
        
        guard notification.object is NSTextView else { return }
        
        self.invalidateNumberOfFound(nil)
    }
    
    
    
    // MARK: Action Messages
    
    /// show regular expression reference as popover
    @IBAction func showRegexHelp(_ sender: AnyObject?) {
        
        if self.presentedViewControllers?.contains(self.regexReferenceViewController) ?? false {
            self.dismissViewController(self.regexReferenceViewController)
            
        } else {
            guard let senderView = sender as? NSView else { return }
            
            self.presentViewController(self.regexReferenceViewController, asPopoverRelativeTo: senderView.bounds, of: senderView, preferredEdge: .maxY, behavior: .semitransient)
        }
    }
    
    
    /// show find panel preferences as popover
    @IBAction func showPreferences(_ sender: AnyObject?) {
        
        if self.presentedViewControllers?.contains(self.preferencesViewController) ?? false {
            self.dismissViewController(self.preferencesViewController)
            
        } else {
            guard let senderView = sender as? NSView else { return }
            
            self.presentViewController(self.preferencesViewController, asPopoverRelativeTo: senderView.bounds, of: senderView, preferredEdge: .maxX, behavior: .transient)
        }
    }
    
    
    /// set selected history string to find field
    @IBAction func selectFindHistory(_ sender: AnyObject?) {
        
        guard let string = sender?.representedObject as? String else { return }
        
        TextFinder.shared.findString = string
    }
    
    
    /// set selected history string to replacement field
    @IBAction func selectReplaceHistory(_ sender: AnyObject?) {
        
        guard let string = sender?.representedObject as? String else { return }
        
        TextFinder.shared.replacementString = string
    }
    
    
    /// restore find history via UI
    @IBAction func clearFindHistory(_ sender: AnyObject?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.removeObject(forKey: DefaultKeys.findHistory.rawValue)
        self.updateFindHistoryMenu()
    }
    
    
    /// restore replace history via UI
    @IBAction func clearReplaceHistory(_ sender: AnyObject?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.removeObject(forKey: DefaultKeys.replaceHistory.rawValue)
        self.updateReplaceHistoryMenu()
    }
    
    
    // MARK: Public Methods
    
    /// recieve number of found
    func updateResultCount(_ numberOfFound: Int, target: NSTextView) {
        
        self.resultMessage = {
            switch numberOfFound {
            case -1:
                return nil
            case 0:
                return NSLocalizedString("Not Found", comment: "")
            default:
                return String(format: NSLocalizedString("%@ Found", comment: ""),
                              String.localizedStringWithFormat("%li", numberOfFound))
            }
        }()
        
        // dismiss result either client text or find string did change
        self.currentResultMessageTarget = target.layoutManager
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateNumberOfFound), name: .NSTextStorageDidProcessEditing, object: target.textStorage)
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateNumberOfFound), name: .NSWindowWillClose, object: target.window)
    }

    
    
    // MARK: Private Methods
    
    /// update find history menu
    private func updateFindHistoryMenu() {
        
        self.buildHistoryMenu(self.findHistoryMenu!, defaultsKey: .findHistory, action: #selector(selectFindHistory))
    }
    
    
    /// update replace history menu
    private func updateReplaceHistoryMenu() {
        
        self.buildHistoryMenu(self.replaceHistoryMenu!, defaultsKey: .replaceHistory, action: #selector(selectReplaceHistory))
    }
    
    
    /// apply history to UI
    private func buildHistoryMenu(_ menu: NSMenu, defaultsKey key: DefaultKey<[String]>, action: Selector) {
        
        // clear current history items
        for item in menu.items {
            if item.action == action || item.isSeparatorItem {
                menu.removeItem(item)
            }
        }
        
        guard let history = Defaults[key], !history.isEmpty else { return }
        
        menu.insertItem(NSMenuItem.separator(), at: 2)  // the first item is invisible dummy
        
        for string in history {
            let title = (string.characters.count < 64) ? string : (String(string.characters.prefix(64)) + "…")
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.representedObject = string
            item.toolTip = string
            item.target = self
            menu.insertItem(item, at: 2)
        }
    }
    
    
    /// number of found in find string field becomes no more valid
    func invalidateNumberOfFound(_ notification: Notification?) {
        
        self.resultMessage = nil
        
        // -> specify the object to remove osberver to avoid removing the windowWillClose notification (via delegate) from find panel itself.
        if let target = self.currentResultMessageTarget?.firstTextView {
            NotificationCenter.default.removeObserver(self, name: .NSTextStorageDidProcessEditing, object: target.textStorage)
            NotificationCenter.default.removeObserver(self, name: .NSWindowWillClose, object: target.window)
        }
    }
    
}
