/*
 
 AppInfo.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-23.
 
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

/// Container for application specific information.
enum AppInfo {
    
    /// application name
    static let bundleName = Bundle.main().objectForInfoDictionaryKey("CFBundleName") as! String
    
    /// human-friendly version expression
    static let shortVersion = Bundle.main().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    
    /// build number
    static let bundleVersion = Bundle.main().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
    
    /// help book name
    static let helpBookName = Bundle.main().objectForInfoDictionaryKey("CFBundleHelpBookName") as! String
}
