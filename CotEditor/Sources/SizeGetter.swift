//
//  SizeGetter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

struct WidthGetter<Key: PreferenceKey>: View where Key.Value == CGFloat {
    
    let key: Key.Type
    
    
    var body: some View {
        
        GeometryReader { (geometry) in
            Color.clear.preference(key: self.key.self, value: geometry.size.width)
        }
    }
}


protocol MaxWidthKey: PreferenceKey {
    
    static var defaultValue: CGFloat { get }
}


extension MaxWidthKey {
    
    static var defaultValue: CGFloat { 0 }
    
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        
        value = max(value, nextValue())
    }
}


struct WidthKey: MaxWidthKey { }
