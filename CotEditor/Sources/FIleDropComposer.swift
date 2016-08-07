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

final class FileDropComposer {
    
    /// keys for dicts in DefaultKey.fileDropArray
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
            
            return NSLocalizedString(self.descriptioin, comment: "")
        }
        
        
        private var descriptioin: String {
            
            switch self {
            case .absolutePath:
                return "The dropped file absolute path."
                
            case .relativePath:
                return "The relative path between dropped file and the document."
                
            case .filename:
                return "The dropped file’s name include extension (if exists)."
                
            case .filenameWithoutExtension:
                return "The dropped file’s name without extension."
                
            case .fileExtension:
                return "The dropped file’s extension."
                
            case .fileExtensionLowercase:
                return "The dropped file’s extension (converted to lowercase)."
                
            case .fileExtensionUppercase:
                return "The dropped file’s extension (converted to uppercase)."
                
            case .directory:
                return "The parent directory name of dropped file."
                
            case .imageWidth:
                return "(If the dropped file is an image) image width."
                
            case .imageHeight:
                return "(If the dropped file is an image) image height."
            }
        }
        
    }
    
    
    // MARK: Public Methods
    
    ///
    class func dropText(forFileURL droppedFileURL: URL, documentURL: URL?) -> String? {
        
        let pathExtension = droppedFileURL.pathExtension
        
        guard let template = self.template(forExtension: pathExtension) else { return nil }
        
        // replace template
        var dropText = template
            .replacingOccurrences(of: Token.absolutePath.rawValue, with: droppedFileURL.path)
            .replacingOccurrences(of: Token.relativePath.rawValue, with: droppedFileURL.path(relativeTo: documentURL) ?? droppedFileURL.path)
            .replacingOccurrences(of: Token.filename.rawValue, with: droppedFileURL.lastPathComponent)
            .replacingOccurrences(of: Token.filenameWithoutExtension.rawValue, with: droppedFileURL.deletingPathExtension().lastPathComponent)
            .replacingOccurrences(of: Token.fileExtension.rawValue, with: pathExtension)
            .replacingOccurrences(of: Token.fileExtensionLowercase.rawValue, with: pathExtension.lowercased())
            .replacingOccurrences(of: Token.fileExtensionUppercase.rawValue, with: pathExtension.uppercased())
            .replacingOccurrences(of: Token.directory.rawValue, with: droppedFileURL.deletingLastPathComponent().lastPathComponent)
        
        // get image dimension if needed
        //   -> Use NSImageRep because NSImage's `size` returns an DPI applied size.
        var imageRep: NSImageRep?
        NSFileCoordinator().coordinate(readingItemAt: droppedFileURL, options: [.withoutChanges, .resolvesSymbolicLink], error: nil) { (newURL: URL) in
            imageRep = NSImageRep(contentsOf: newURL)
        }
        if let imageRep = imageRep {
            dropText = dropText
                .replacingOccurrences(of: Token.imageWidth.rawValue, with: String(imageRep.pixelsWide))
                .replacingOccurrences(of: Token.imageHeight.rawValue, with: String(imageRep.pixelsHigh))
        }
        
        return dropText
    }
    
    
    
    // MARK: Private Methods
    
    /// find matched template for path extension
    private class func template(forExtension fileExtension: String?) -> String? {
        
        guard let fileExtension = fileExtension else { return nil }
        
        let definitions = UserDefaults.standard.array(forKey: DefaultKey.fileDropArray) as! [[String: String]]
        
        for definition in definitions {
            guard let extensions = definition[SettingKey.extensions]?.components(separatedBy: ", ") else { continue }
            
            if extensions.contains(fileExtension.lowercased()) || extensions.contains(fileExtension.uppercased()) {
                return definition[SettingKey.formatString]
            }
        }
        
        return nil
    }
    
}
