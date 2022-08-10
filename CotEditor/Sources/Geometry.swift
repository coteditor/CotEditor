//
//  Geometry.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-03-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import CoreGraphics

// MARK: Scalable

protocol Scalable {
    
    func scaled(to scale: CGFloat) -> Self
}


extension CGPoint: Scalable {
    
    func scaled(to scale: CGFloat) -> CGPoint {
        
        CGPoint(x: scale * self.x, y: scale * self.y)
    }
    
}


extension CGSize: Scalable {
    
    func scaled(to scale: CGFloat) -> CGSize {
        
        CGSize(width: scale * self.width, height: scale * self.height)
    }
    
}


extension CGRect: Scalable {
    
    func scaled(to scale: CGFloat) -> CGRect {
        
        CGRect(x: scale * self.origin.x, y: scale * self.origin.y, width: scale * self.width, height: scale * self.height)
    }
    
}



// MARK: - Syntax Sugares

extension CGPoint {
    
    static prefix func - (point: CGPoint) -> CGPoint {
        
        CGPoint(x: -point.x, y: -point.y)
    }
    
    
    func offsetBy(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        
        CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    
    func offset(by point: CGPoint) -> CGPoint {
        
        self.offsetBy(dx: point.x, dy: point.y)
    }
    
    
    func offset(by size: CGSize) -> CGPoint {
        
        self.offsetBy(dx: size.width, dy: size.height)
    }
    
}


extension CGSize {
    
    static prefix func - (size: Self) -> Self {
        
        Self(width: -size.width, height: -size.height)
    }
    
    
    static let unit = CGSize(width: 1, height: 1)
    static let infinite = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
}


extension CGRect {
    
    var mid: CGPoint {
        
        CGPoint(x: self.midX, y: self.midY)
    }
    
    
    func offset(by point: CGPoint) -> CGRect {
        
        self.offsetBy(dx: point.x, dy: point.y)
    }
    
    
    func offset(by size: CGSize) -> CGRect {
        
        self.offsetBy(dx: size.width, dy: size.height)
    }
    
    
    func inset(by point: CGPoint) -> CGRect {
        
        self.insetBy(dx: point.x, dy: point.y)
    }
    
    
    func inset(by size: CGSize) -> CGRect {
        
        self.insetBy(dx: size.width, dy: size.height)
    }
    
}
