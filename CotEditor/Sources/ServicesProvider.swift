/*
 
 ServicesProvider.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-23.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

final class ServicesProvider: NSObject {
    
    // MARK: Public Methods
    
    /// open new document with string via Services
    func openSelection(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        
        guard let selection = pboard.string(forType: NSPasteboardTypeString) else { return }
        
        let document: NSDocument
        do {
            document = try NSDocumentController.shared().openUntitledDocumentAndDisplay(false)
            
        } catch let error as NSError {
            NSApp.presentError(error)
            return
        }
        
        if let document = document as? Document {
            document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: selection)
            document.makeWindowControllers()
            document.showWindows()
        }
    }
    
    
    /// open files via Services
    func openFile(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        
        guard let items = pboard.pasteboardItems else { return }
        
        for item in items {
            guard let type = item.availableType(from: [kUTTypeFileURL as String, kUTTypeText as String]) else { continue }
            guard let path = item.string(forType: type) else { continue }
            let fileURL = URL(fileURLWithPath: path)
            
            // get file UTI
            guard let UTI = try! fileURL.resourceValues(forKeys: Set([.typeIdentifierKey])).typeIdentifier else { continue }
            
            // process only plain-text files
            guard NSWorkspace.shared().type(UTI, conformsToType: kUTTypeText as String) else {
                let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [NSURLErrorKey: fileURL])
                NSApp.presentError(error)
                continue
            }
            
            // open file
            NSDocumentController.shared().openDocument(withContentsOf: fileURL,
                                                       display: true,
                                                       completionHandler: { (document: NSDocument?, documentWasAlreadyOpen: Bool, error: Error?) in
                                                        if let error = error {
                                                            NSAlert(error: error).runModal()
                                                        }
            })
        }
    }
    
}
