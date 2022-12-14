//
//  URL+ExtendedAttribute.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

import Foundation

extension URL {
    
    /// get extended attribute
    func extendedAttribute(for name: String) throws -> Data {
        
        try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in
            // check buffer size
            let length = getxattr(fileSystemPath, name, nil, 0, 0, XATTR_NOFOLLOW)
            
            guard length >= 0 else { throw POSIXError(err: errno) }
            
            // get xattr data
            var data = Data(count: length)
            let size = data.withUnsafeMutableBytes {
                getxattr(fileSystemPath, name, $0.baseAddress, length, 0, XATTR_NOFOLLOW)
            }
            
            guard size >= 0 else { throw POSIXError(err: errno) }
            
            return data
        }
    }
    
    
    /// set extended attribute
    func setExtendedAttribute(data: Data?, for name: String) throws {
        
        // remove if nil is passed
        guard let data = data else {
            return try self.removeExtendedAttribute(for: name)
        }
        
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let size = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, XATTR_NOFOLLOW)
            }
            
            guard size >= 0 else { throw POSIXError(err: errno) }
        }
    }
    
    
    /// remove extended attribute
    private func removeExtendedAttribute(for name: String) throws {
        
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let size = removexattr(fileSystemPath, name, XATTR_NOFOLLOW)
            
            guard size >= 0 else { throw POSIXError(err: errno) }
        }
    }
}



private extension POSIXError {
    
    init(err: Int32) {
        
        self.init(Code(rawValue: err)!)
    }
}
