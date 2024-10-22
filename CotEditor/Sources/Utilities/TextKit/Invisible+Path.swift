//
//  Invisible+Path.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-10-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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
import Invisible

extension Invisible {
    
    /// Returns the path to draw an alternative symbol.
    ///
    /// - Parameters:
    ///   - size: The size of bounding box.
    ///   - lineWidth: The standard line width.
    ///   - isRTL: Whether the path will be used for right-to-left writing direction.
    /// - Returns: The path.
    func path(in size: CGSize, lineWidth: CGFloat, isRTL: Bool = false) -> CGPath {
        
        switch self {
            case .newLine:
                // -> Do not use `size.width` as new line glyphs actually have no area.
                let y = 0.5 * size.height
                let radius = 0.25 * size.height
                let transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1) : .identity
                let path = CGMutablePath()
                // arrow body
                path.addArc(center: CGPoint(x: 0.9 * size.height, y: y),
                            radius: radius, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
                path.addLine(to: CGPoint(x: 0.2 * size.height, y: y + radius))
                // arrow head
                path.addLines(between: [CGPoint(x: 0.5 * size.height, y: y + radius + 0.25 * size.height),
                                        CGPoint(x: 0.2 * size.height, y: y + radius),
                                        CGPoint(x: 0.5 * size.height, y: y + radius - 0.25 * size.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, transform: transform)
                
            case .tab:
                // -> The width of tab is elastic and even can be (almost) zero.
                let arrow = CGSize(width: 0.3 * size.height, height: 0.25 * size.height)
                let margin = (0.7 * (size.width - arrow.width)).clamped(to: 0...(0.4 * size.height))
                let endPoint = CGPoint(x: size.width - margin, y: size.height / 2)
                let transform = isRTL ? CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -size.width, y: 0) : .identity
                let path = CGMutablePath()
                // arrow body
                path.addLines(between: [endPoint, endPoint.offsetBy(dx: -max(size.width - 2 * margin, arrow.width))])
                // arrow head
                path.addLines(between: [endPoint.offsetBy(dx: -arrow.width, dy: +arrow.height),
                                        endPoint,
                                        endPoint.offsetBy(dx: -arrow.width, dy: -arrow.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0, transform: transform)
                
            case .space:
                let radius = 0.15 * size.height + lineWidth
                let rect = CGRect(x: (size.width - radius) / 2, y: (size.height - radius) / 2, width: radius, height: radius)
                return CGPath(ellipseIn: rect, transform: nil)
                
            case .noBreakSpace:
                let hat = CGMutablePath()
                let hatCorner = CGPoint(x: 0.5 * size.width, y: 0.05 * size.height)
                hat.addLines(between: [hatCorner.offsetBy(dx: -0.15 * size.height, dy: 0.18 * size.height),
                                       hatCorner,
                                       hatCorner.offsetBy(dx: 0.15 * size.height, dy: 0.18 * size.height)])
                let path = CGMutablePath()
                path.addPath(hat.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 0))
                path.addPath(Self.space.path(in: size, lineWidth: lineWidth))
                return path
                
            case .fullwidthSpace:
                let length = min(0.95 * size.width, size.height) - lineWidth
                let radius = 0.1 * length
                let rect = CGRect(x: (size.width - length) / 2, y: (size.height - length) / 2, width: length, height: length)
                return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
                    .copy(strokingWithWidth: lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: 0)
                
            case .otherWhitespace:
                let path = CGMutablePath()
                path.addLines(between: [CGPoint(x: 0.2 * size.width, y: 0.3 * size.height),
                                        CGPoint(x: 0.8 * size.width, y: 0.3 * size.height)])
                path.addLines(between: [CGPoint(x: 0.2 * size.width, y: 0.8 * size.height),
                                        CGPoint(x: 0.8 * size.width, y: 0.8 * size.height)])
                return path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .miter, miterLimit: 0)
                
            case .otherControl:
                let question = CGMutablePath()  // `?` mark in unit size
                question.move(to: CGPoint(x: 0, y: 0.25))
                question.addCurve(to: CGPoint(x: 0.5, y: 0), control1: CGPoint(x: 0, y: 0.12), control2: CGPoint(x: 0.22, y: 0))
                question.addCurve(to: CGPoint(x: 1.0, y: 0.25), control1: CGPoint(x: 0.78, y: 0), control2: CGPoint(x: 1.0, y: 0.12))
                question.addCurve(to: CGPoint(x: 0.7, y: 0.48), control1: CGPoint(x: 1.0, y: 0.32), control2: CGPoint(x: 0.92, y: 0.4))
                question.addCurve(to: CGPoint(x: 0.5, y: 0.75), control1: CGPoint(x: 0.48, y: 0.56), control2: CGPoint(x: 0.5, y: 0.72))
                question.move(to: CGPoint(x: 0.5, y: 0.99))
                question.addLine(to: CGPoint(x: 0.5, y: 1.0))
                let transform = CGAffineTransform(translationX: 0.25 * size.width, y: 0.12 * size.height)
                    .scaledBy(x: 0.5 * size.width, y: 0.76 * size.height)
                let scaledQuestion = question.copy(using: [transform])!
                    .copy(strokingWithWidth: 0.15 * size.width, lineCap: .round, lineJoin: .miter, miterLimit: 0)
                let path = CGMutablePath()
                path.addPath(scaledQuestion)
                path.addLines(between: [CGPoint(x: 0.5 * size.width, y: -0.15 * size.height),
                                        CGPoint(x: 0.9 * size.width, y: 0.15 * size.height),
                                        CGPoint(x: 0.9 * size.width, y: 0.85 * size.height),
                                        CGPoint(x: 0.5 * size.width, y: 1.15 * size.height),
                                        CGPoint(x: 0.1 * size.width, y: 0.85 * size.height),
                                        CGPoint(x: 0.1 * size.width, y: 0.15 * size.height)])
                path.closeSubpath()
                return path
        }
    }
}


// MARK: - Preview

import SwiftUI

#Preview {
    HStack(spacing: 20) {
        ForEach(Invisible.allCases, id: \.self) { invisible in
            let size = CGSize(width: (invisible == .tab) ? 30 : 12, height: 16)
            
            Path(invisible.path(in: size, lineWidth: 1.5))
                .frame(width: size.width, height: size.height)
                .border(.tertiary, width: 0.5)
        }
    }
    .padding()
    .background()
}
