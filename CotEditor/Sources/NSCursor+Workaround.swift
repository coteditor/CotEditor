//
//  NSCursor+Workaround.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-09-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2021 1024jp
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

import AppKit.NSCursor

extension NSCursor {
    
    /// Fix i-beam for vertical text orientation (FB7722838).
    func fixIBeam() {
        
        if self == .iBeamCursorForVerticalLayout {
            // -> The system draws i-beam with custom colors correctly.
            if #available(macOS 12, *), (NSCursor.outlineColor != nil || NSCursor.fillColor != nil) {
                return
            }
            
            Self.lightIBeamCursorForVerticalLayout.set()
        }
    }
}



// MARK: -

private extension NSCursor {
    
    /// Fixed i-beam for vertical text orientation.
    static let lightIBeamCursorForVerticalLayout = NSCursor(image: #imageLiteral(resourceName: "LightIBeamCursorForVerticalLayout"), hotSpot: NSCursor.iBeamCursorForVerticalLayout.hotSpot)
    
    
    /// The outline color for cursors that the user set in System Preferences > Accessibility > Display > Pointer.
    @available(macOS 12, *)
    static var outlineColor: NSColor? {
        
        guard
            let defaults = UserDefaults(suiteName: "com.apple.universalaccess"),
            let dictionary = defaults.dictionary(forKey: "cursorOutline"),
            let color = Color(dictionary: dictionary)
        else { return nil }
        
        return color == .white ? nil : NSColor(color: color)
    }
    
    
    /// The fill color for cursors that the user set in System Preferences > Accessibility > Display > Pointer
    @available(macOS 12, *)
    static var fillColor: NSColor? {
        
        guard
            let defaults = UserDefaults(suiteName: "com.apple.universalaccess"),
            let dictionary = defaults.dictionary(forKey: "cursorFill"),
            let color = Color(dictionary: dictionary)
        else { return nil }
        
        return color == .black ? nil : NSColor(color: color)
    }
    
}


private struct Color: Hashable {
    
    static let white = Color(red: 1, green: 1, blue: 1)
    static let black = Color(red: 0, green: 0, blue: 0)
    
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1
}


private extension Color {
    
    init?(dictionary: [String: Any]) {
        
        guard let red = dictionary["red"] as? Double,
              let green = dictionary["green"] as? Double,
              let blue = dictionary["blue"] as? Double
        else { return nil }
        
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = dictionary["alpha"] as? Double ?? 1
    }
}


private extension NSColor {
    
    convenience init?(color: Color) {
        
        self.init(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}
