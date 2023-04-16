//
//  NSBezierPath.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-05-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

import AppKit.NSBezierPath

extension NSBezierPath {
    
    convenience init(path: CGPath, transform: AffineTransform? = nil) {
        
        self.init()
        
        path.applyWithBlock { (pointer) in
            let element = pointer.pointee
            
            switch element.type {
                case .moveToPoint:
                    self.move(to: element.points[0])
                    
                case .addLineToPoint:
                    self.line(to: element.points[0])
                    
                case .addQuadCurveToPoint:
                    let controlPoint1 = NSPoint(x: self.currentPoint.x + (2 / 3 * (element.points[0].x - self.currentPoint.x)),
                                                y: self.currentPoint.y + (2 / 3 * (element.points[0].y - self.currentPoint.y)))
                    let controlPoint2 = NSPoint(x: element.points[1].x + (2 / 3 * (element.points[0].x - element.points[1].x)),
                                                y: element.points[1].y + (2 / 3 * (element.points[0].y - element.points[1].y)))
                    self.curve(to: element.points[1], controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                    
                case .addCurveToPoint:
                    self.curve(to: element.points[2], controlPoint1: element.points[0], controlPoint2: element.points[1])
                    
                case .closeSubpath:
                    self.close()
                    
                @unknown default:
                    assertionFailure()
            }
        }
        
        if let transform {
            self.transform(using: transform)
        }
    }
}



// MARK: Rounded Corner

struct RectCorner: OptionSet {
    
    let rawValue: Int
    
    static let topLeft     = Self(rawValue: 1 << 0)
    static let bottomLeft  = Self(rawValue: 1 << 1)
    static let topRight    = Self(rawValue: 1 << 2)
    static let bottomRight = Self(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .bottomLeft, .topRight, .bottomRight]
}



extension NSBezierPath {
    
    /// Creates and returns a new NSBezierPath object initialized with a rounded rectangular path.
    ///
    /// - Parameters:
    ///   - rect: The rectangle that defines the basic shape of the path.
    ///   - corners: A bitmask value that identifies the corners that you want rounded. You can use this parameter to round only a subset of the corners of the rectangle.
    ///   - radius: The radius of each corner oval. Values larger than half the rectangle’s width are clamped to half the width.
    convenience init(roundedRect rect: NSRect, byRoundingCorners corners: RectCorner, cornerRadius radius: CGFloat) {
        
        self.init()
        
        let radius = radius.clamped(to: 0...(min(rect.width, rect.height) / 2))
        
        let topLeft = NSPoint(x: rect.minX, y: rect.minY)
        let topRight = NSPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = NSPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = NSPoint(x: rect.minX, y: rect.maxY)
        
        self.move(to: topLeft.offsetBy(dx: 0, dy: radius))
        self.appendArc(from: topLeft, to: topRight, radius: corners.contains(.topLeft) ? radius : 0)
        self.appendArc(from: topRight, to: bottomRight, radius: corners.contains(.topRight) ? radius : 0)
        self.appendArc(from: bottomRight, to: bottomLeft, radius: corners.contains(.bottomRight) ? radius : 0)
        self.appendArc(from: bottomLeft, to: topLeft, radius: corners.contains(.bottomLeft) ? radius : 0)
        self.close()
    }
}
