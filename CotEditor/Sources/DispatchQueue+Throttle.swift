//
//  DispatchQueue+Throttle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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

import Dispatch

extension DispatchTimeInterval {
    
    static func seconds(_ interval: Double) -> DispatchTimeInterval {
        
        return .milliseconds(Int(interval * 1000))
    }
}



extension DispatchQueue {
    
    /// Perform action but never be called more than once each specified interval.
    ///
    /// - Parameters:
    ///    - delay: The time interval.
    func throttle(delay: DispatchTimeInterval) -> (_ action: @escaping () -> Void) -> Void {
        
        var lastFireTime: DispatchTime = .now()
        
        return { [weak self, delay] action in
            self?.asyncAfter(deadline: .now() + delay) { [delay] in
                guard (lastFireTime + delay) <= .now() else { return }
                
                lastFireTime = .now()
                action()
            }
        }
    }
    
}
