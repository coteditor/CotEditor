/*
=================================================
CELayoutManager
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.01.10

------------
This class is based on Smultron - SMLLayoutManager (written by Peter Borg – http://smultron.sourceforge.net)
Smultron  Copyright (c) 2004 Peter Borg, All rights reserved.
Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
arranged by nakamuxu, Jan 2005.
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import <Cocoa/Cocoa.h>
#import "CEATSTypesetter.h"
#import "CEPrivateMutableArray.h"
#import "constants.h"


@interface CELayoutManager : NSLayoutManager
{
    NSDictionary *_attributes;
    NSString *_spaceCharacter;
    NSString *_tabCharacter;
    NSString *_newLineCharacter;
    NSString *_fullwidthSpaceCharacter;
    NSFont *_textFont;
    id _appController;

    BOOL _showInvisibles;
    BOOL _showSpace;
    BOOL _showTab;
    BOOL _showNewLine;
    BOOL _showFullwidthSpace;
    BOOL _showOtherInvisibles;

    BOOL _fixLineHeight;
    BOOL _useAntialias;
    BOOL _isPrinting;

    float _defaultLineHeightForTextFont;
    float _textFontPointSize;
    float _textFontGlyphY;
}

// Public method
- (BOOL)showInvisibles;
- (void)setShowInvisibles:(BOOL)inValue;
- (BOOL)showSpace;
- (void)setShowSpace:(BOOL)inValue;
- (BOOL)showTab;
- (void)setShowTab:(BOOL)inValue;
- (BOOL)showNewLine;
- (void)setShowNewLine:(BOOL)inValue;
- (BOOL)showFullwidthSpace;
- (void)setShowFullwidthSpace:(BOOL)inValue;
- (BOOL)showOtherInvisibles;
- (void)setShowOtherInvisibles:(BOOL)inValue;
- (BOOL)fixLineHeight;
- (void)setFixLineHeight:(BOOL)inValue;
- (BOOL)useAntialias;
- (void)setUseAntialias:(BOOL)inValue;
- (BOOL)isPrinting;
- (void)setIsPrinting:(BOOL)inValue;
- (NSFont *)textFont;
- (void)setTextFont:(NSFont *)inFont;
- (void)setValuesForTextFont:(NSFont *)inFont;
- (float)defaultLineHeightForTextFont;
- (float)textFontPointSize;
- (float)textFontGlyphY;
- (float)lineHeight;
@end
