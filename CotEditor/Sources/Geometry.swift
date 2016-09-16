/*
 
 Geometry.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-03-20.
 
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

// MARK: Scalable

protocol Scalable {
    
    func scaled(to scale: CGFloat) -> Self
}


extension CGPoint: Scalable {
    
    func scaled(to scale: CGFloat) -> CGPoint {
        
        return CGPoint(x: scale * self.x, y: scale * self.y)
    }
    
}


extension CGSize: Scalable {
    
    func scaled(to scale: CGFloat) -> CGSize {
        
        return CGSize(width: scale * self.width, height: scale * self.height)
    }
    
}


extension CGRect: Scalable {
    
    func scaled(to scale: CGFloat) -> CGRect {
        
        return CGRect(x: scale * self.origin.x, y: scale * self.origin.y, width: scale * self.width, height: scale * self.height)
    }
    
}



// MARK:
// MARK: Syntax Sugares

extension CGPoint {
    
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
}


extension CGSize {
    
    static let unit = CGSize(width: 1, height: 1)
    static let infinite = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    
}


extension CGRect {
    
    var mid: CGPoint {
        
        return NSPoint(x: self.midX, y: self.midY)
    }
    
}



// MARK: CGFloat

extension CGFloat {
    
    /// round to decimal places value
    func rounded(to places: Int) -> CGFloat {
        
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
    
}
