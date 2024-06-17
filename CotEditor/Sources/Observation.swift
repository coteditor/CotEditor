//
//  Observation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

import Observation

/// Tracks access to properties continuously.
///
/// - Parameters:
///   - initial: If `true`, `onChange` closure will be evaluated immediately before the actual observation.
///   - apply: A closure that contains properties to track.
///   - onChange: The closure invoked when the value of a property changes.
/// - Returns: The value that the apply closure returns if it has a return value; otherwise, there is no return value.
func withContinuousObservationTracking<T>(initial: Bool = false, _ apply: @escaping (@Sendable () -> T), onChange: @escaping (@Sendable () -> Void)) {
    
    if initial {
        onChange()
    }
    
    _ = withObservationTracking(apply, onChange: {
        onChange()
        withContinuousObservationTracking(apply, onChange: onChange)
    })
}
