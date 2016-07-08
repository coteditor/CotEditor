/*
 
 FileDropComposer.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-09.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

class FileDropComposer: NSObject {  // TODO: remove NSObject
    
    /// keys for dicts in CEDefaultFileDropArrayKey
    enum SettingKey {
        
        static let extensions = "extensions"
        static let formatString = "formatString"
    }
    
    
    enum Token: String {
        
        case absolutePath = "<<<ABSOLUTE-PATH>>>"
        case relativePath = "<<<RELATIVE-PATH>>>"
        case filename = "<<<FILENAME>>>"
        case filenameWithoutExtension = "<<<FILENAME-NOSUFFIX>>>"
        case fileExtension = "<<<FILEEXTENSION>>>"
        case fileExtensionLowercase = "<<<FILEEXTENSION-LOWER>>>"
        case fileExtensionUppercase = "<<<FILEEXTENSION-UPPER>>>"
        case directory = "<<<DIRECTORY>>>"
        case imageWidth = "<<<IMAGEWIDTH>>>"
        case imageHeight = "<<<IMAGEHEIGHT>>>"
        
        static let pathTokens: [Token] = [.absolutePath, .relativePath, .filename, .filenameWithoutExtension, .fileExtension, .fileExtensionLowercase, .fileExtensionUppercase, .directory]
        static let imageTokens: [Token] = [.imageWidth, .imageHeight]
        static let all = Token.pathTokens + Token.imageTokens
        
        
        var localizedDescription: String {
            switch self {
            case .absolutePath:
                return NSLocalizedString("The dropped file absolute path.", comment: "")
            case .relativePath:
                return NSLocalizedString("The relative path between dropped file and the document.", comment: "")
            case .filename:
                return NSLocalizedString("The dropped file’s name include extension (if exists).", comment: "")
            case .filenameWithoutExtension:
                return NSLocalizedString("The dropped file’s name without extension.", comment: "")
            case .fileExtension:
                return NSLocalizedString("The dropped file’s extension.", comment: "")
            case .fileExtensionLowercase:
                return NSLocalizedString("The dropped file’s extension (converted to lowercase).", comment: "")
            case .fileExtensionUppercase:
                return NSLocalizedString("The dropped file’s extension (converted to uppercase).", comment: "")
            case .directory:
                return NSLocalizedString("The parent directory name of dropped file.", comment: "")
            case .imageWidth:
                return NSLocalizedString("(If the dropped file is an image) image width.", comment: "")
            case .imageHeight:
                return NSLocalizedString("(If the dropped file is an image) image height.", comment: "")
            }
        }
    }
    
    
    // MARK: Public Methods
    
    ///
    class func dropText(forFileURL droppedFileURL: URL, documentURL: URL?) -> String? {
        
        let pathExtension = droppedFileURL.pathExtension
        
        guard var dropText = self.template(forExtension: pathExtension) else { return nil }
        
        // replace template
        if let path = droppedFileURL.path {
            dropText = dropText.replacingOccurrences(of: Token.absolutePath.rawValue, with: path)
            dropText = dropText.replacingOccurrences(of: Token.relativePath.rawValue, with: droppedFileURL.path(relativeTo: documentURL) ?? path)
        }
        if let filename = droppedFileURL.lastPathComponent {
            dropText = dropText.replacingOccurrences(of: Token.filename.rawValue, with: filename)
        }
        if let filename = (try? droppedFileURL.deletingPathExtension())?.lastPathComponent {
            dropText = dropText.replacingOccurrences(of: Token.filenameWithoutExtension.rawValue, with: filename)
        }
        if let pathExtension = pathExtension {
            dropText = dropText.replacingOccurrences(of: Token.fileExtension.rawValue, with: pathExtension)
            dropText = dropText.replacingOccurrences(of: Token.fileExtensionLowercase.rawValue, with: pathExtension.lowercased())
            dropText = dropText.replacingOccurrences(of: Token.fileExtensionUppercase.rawValue, with: pathExtension.uppercased())
        }
        if let directory = (try? droppedFileURL.deletingLastPathComponent())?.lastPathComponent {
            dropText = dropText.replacingOccurrences(of: Token.directory.rawValue, with: directory)
        }
        
        // get image dimension if needed
        //   -> Use NSImageRep because NSImage's `size` returns an DPI applied size.
        var imageRep: NSImageRep?
        NSFileCoordinator().coordinate(readingItemAt: droppedFileURL, options: [.withoutChanges, .resolvesSymbolicLink], error: nil) { (newURL: URL) in
            imageRep = NSImageRep(contentsOf: newURL)
        }
        if let imageRep = imageRep {
            dropText = dropText.replacingOccurrences(of: Token.imageWidth.rawValue, with: String(imageRep.pixelsWide))
            dropText = dropText.replacingOccurrences(of: Token.imageHeight.rawValue, with: String(imageRep.pixelsHigh))
        }
        
        return dropText
    }
    
    
    
    // MARK: Private Methods
    
    /// find matched template for path extension
    private class func template(forExtension fileExtension: String?) -> String? {
        
        guard let fileExtension = fileExtension else { return nil }
        
        let definitions = UserDefaults.standard.array(forKey: CEDefaultFileDropArrayKey) as! [[String: String]]
        
        for definition in definitions {
            guard let extensions = definition[SettingKey.extensions]?.components(separatedBy: ", ") else { continue }
            
            if extensions.contains(fileExtension.lowercased()) || extensions.contains(fileExtension.uppercased()) {
                return definition[SettingKey.formatString]
            }
        }
        
        return nil
    }
    
}
