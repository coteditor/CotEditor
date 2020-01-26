//
//  PointerBridge.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2019 1024jp
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

private final class Wrapper<T> {
    
    let value: T
    
    
    init(value: T) {
        
        self.value = value
    }
    
}



func bridgeWrapped<T: Any>(_ obj: T) -> UnsafeMutableRawPointer {
    
    let wrapper = Wrapper<T>(value: obj)
    
    return bridgeRetained(wrapper)
}


func bridgeUnwrapped<T: Any>(_ ptr: UnsafeRawPointer) -> T {
    
    let wrapper: Wrapper<T> = bridgeTransfer(ptr)
    
    return wrapper.value
}


private func bridgeRetained<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
    
    return Unmanaged.passRetained(obj).toOpaque()
}


private func bridgeTransfer<T: AnyObject>(_ ptr: UnsafeRawPointer) -> T {
    
    return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()
}
