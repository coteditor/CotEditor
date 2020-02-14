//
//  OutlineMenuButtonCell.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-08-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

import Cocoa

final class OutlineMenuButtonCell: NSPopUpButtonCell {
    
    // MARK: Pop Up Button Cell Methods
    
    /// draw cell
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        // draw background
        self.drawBezel(withFrame: cellFrame, in: controlView)
        
        // draw popup arrow
        let arrowImage = #imageLiteral(resourceName: "PopUpButtonArrowTemplate")
        let imageFrame = NSRect(x: cellFrame.maxX - arrowImage.size.width - 5,
                                y: cellFrame.minY,
                                width: arrowImage.size.width,
                                height: cellFrame.height)
        self.drawImage(arrowImage, withFrame: imageFrame, in: controlView)
        
        // draw text
        let interiorFrame = cellFrame.offsetBy(dx: 0, dy: 1.0)
        self.drawInterior(withFrame: interiorFrame, in: controlView)
    }
    
}
