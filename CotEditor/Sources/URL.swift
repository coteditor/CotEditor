/*
 
 URL.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-07-03.
 
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

import Foundation

extension URL {
    
    /// check if file URL is executable
    var isExecutable: Bool? {
        
        return (try? self.resourceValues(forKeys: [.isExecutableKey]))?.isExecutable
    }
    
    
    /// check just URL is reachable and ignore any errors
    var isReachable: Bool {
        
        return (try? self.checkResourceIsReachable()) ?? false
    }
    
    
    /// return relative-path string
    func path(relativeTo baseURL: URL?) -> String? {
        
        guard let baseURL = baseURL, baseURL != self else { return nil }
        
        let pathComponents = self.pathComponents ?? []
        let basePathComponents = baseURL.pathComponents ?? []
        
        var sameCount = 0
        for (baseComponent, component) in zip(basePathComponents, pathComponents) {
            guard baseComponent == component else { break }
            
            sameCount += 1
        }
        
        let parentCount =  basePathComponents.count - sameCount - 1
        var relativeComponents = [String](repeating: "..", count: parentCount)
        relativeComponents += pathComponents[sameCount..<pathComponents.count]
        
        return NSURL.fileURL(withPathComponents: relativeComponents)?.relativePath
    }
    
}
