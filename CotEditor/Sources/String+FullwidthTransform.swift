//
//  String+FullwidthTransform.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-07-31.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

extension StringProtocol {
    
    // MARK: Public Properties
    
    /// Transform half-width roman characters to full-width forms, or vice versa.
    ///
    /// - Parameter reverse: `True` to transform from full-width to half-width.
    /// - Returns: A transformed string.
    func fullwidthRoman(reverse: Bool = false) -> String {
        
        self.unicodeScalars
            .map { $0.convertedToFullwidthRoman(reverse: reverse) ?? $0 }
            .reduce(into: "") { $0.unicodeScalars.append($1) }
    }
    
}



// MARK: - Private Extensions

private extension Unicode.Scalar {
    
    private static let fullwidthRomanRange: ClosedRange<UTF32.CodeUnit> = 0xFF01...0xFF5E
    private static let widthShifter: UTF32.CodeUnit = 0xFEE0
    
    
    func convertedToFullwidthRoman(reverse: Bool = false) -> Self? {
        
        let fullwidthValue = reverse ? self.value : self.value + Self.widthShifter
        
        guard Self.fullwidthRomanRange.contains(fullwidthValue) else { return nil }
        
        let newScalar = reverse
            ? self.value - Self.widthShifter
            : self.value + Self.widthShifter
        
        return Self(newScalar)
    }
    
}
