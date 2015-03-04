/*
 ==============================================================================
 CEFindPanelLayoutManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-03-04 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEFindPanelLayoutManager.h"
#import "CEUtils.h"
#import "constants.h"


@interface CEFindPanelLayoutManager ()

@property (nonatomic) CGFloat fontSize;

@end




#pragma mark -

@implementation CEFindPanelLayoutManager


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _fontSize = [NSFont systemFontSize];
        [self setUsesScreenFonts:YES];
    }
    return self;
}

// ------------------------------------------------------
/// show invisible characters
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL showInvisibles = [defaults boolForKey:CEDefaultShowInvisiblesKey];
    
    if (showInvisibles) {
        NSTextView *textView = [self firstTextView];
        NSString *completeStr = [[self textStorage] string];
        NSUInteger lengthToRedraw = NSMaxRange(glyphsToShow);
        NSSize inset = [textView textContainerInset];
        
        NSColor *color;
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
            color = [NSColor tertiaryLabelColor];
        } else {
            color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.25];
        }
        
        NSFont *font = [[self firstTextView] font];
        font = [font screenFont] ? : font;
        NSDictionary *attributes = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: color};
        NSFont *fullwidthFont = [[NSFont fontWithName:@"HiraKakuProN-W3" size:[font pointSize]] screenFont] ? : font;
        NSDictionary *fullwidthAttributes = @{NSFontAttributeName: fullwidthFont,
                                              NSForegroundColorAttributeName: color};
        
        BOOL showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        BOOL showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        BOOL showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        BOOL showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        BOOL showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        
        unichar spaceChar = [CEUtils invisibleSpaceChar:[defaults integerForKey:CEDefaultInvisibleSpaceKey]];
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&spaceChar length:1]
                                                                    attributes:attributes];
        
        unichar tabChar = [CEUtils invisibleTabChar:[defaults integerForKey:CEDefaultInvisibleTabKey]];
        NSAttributedString *tab = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&tabChar length:1]
                                                                  attributes:attributes];
        
        unichar newLineChar = [CEUtils invisibleNewLineChar:[defaults integerForKey:CEDefaultInvisibleNewLineKey]];
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&newLineChar length:1]
                                                                      attributes:attributes];
        
        unichar fullwidthSpaceChar = [CEUtils invisibleFullwidthSpaceChar:[defaults integerForKey:CEDefaultInvisibleFullwidthSpaceKey]];
        NSAttributedString *fullwidthSpace = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&fullwidthSpaceChar length:1]
                                                                             attributes:fullwidthAttributes];
        
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < lengthToRedraw; glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeStr characterAtIndex:charIndex];
            
            if (showsSpace && ((character == ' ') || (character == 0x00A0))) {
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [space drawAtPoint:pointToDraw];
                
            } else if (showsTab && (character == '\t')) {
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [tab drawAtPoint:pointToDraw];
                
            } else if (showsNewLine && (character == '\n')) {
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [newLine drawAtPoint:pointToDraw];
                
            } else if (showsFullwidthSpace && (character == 0x3000)) { // Fullwidth-space (JP)
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [fullwidthSpace drawAtPoint:pointToDraw];
                
            } else if (showsOtherInvisibles && ([self glyphAtIndex:glyphIndex] == NSControlGlyph)) {
                NSFont *replaceFont = [NSFont fontWithName:@"Lucida Grande" size:[font pointSize]];
                NSGlyph replaceGlyph = [replaceFont glyphWithName:@"replacement"];
                NSUInteger charLength = CFStringIsSurrogateHighCharacter(character) ? 2 : 1;
                NSRange charRange = NSMakeRange(charIndex, charLength);
                NSString *baseStr = [completeStr substringWithRange:charRange];
                NSGlyphInfo *glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:replaceGlyph forFont:replaceFont baseString:baseStr];
                
                if (glyphInfo) {
                    NSDictionary *replaceAttrs = @{NSGlyphInfoAttributeName: glyphInfo,
                                                   NSFontAttributeName: replaceFont,
                                                   NSForegroundColorAttributeName: color};
                    NSDictionary *attrs = [[self textStorage] attributesAtIndex:charIndex effectiveRange:NULL];
                    if (attrs[NSGlyphInfoAttributeName] == nil) {
                        [[self textStorage] addAttributes:replaceAttrs range:charRange];
                    }
                }
            }
        }
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}


// ------------------------------------------------------
/// fix vertical glyph location for mixed font
- (NSPoint)locationForGlyphAtIndex:(NSUInteger)glyphIndex
// ------------------------------------------------------
{
    NSPoint point = [super locationForGlyphAtIndex:glyphIndex];
    point.y = [[NSFont systemFontOfSize:[self fontSize]] ascender];
    
    return point;
}


// ------------------------------------------------------
/// fix line height for mixed font
- (void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
// ------------------------------------------------------
{
    static const CGFloat kLineSpacing = 4.0;
    CGFloat lineHeight = [self fontSize] + kLineSpacing;
    
    fragmentRect.size.height = lineHeight;
    usedRect.size.height = lineHeight;
    
    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}



#pragma mark Private Methods

//------------------------------------------------------
/// calculate point to draw invisible character
- (NSPoint)pointToDrawGlyphAtIndex:(NSUInteger)glyphIndex adjust:(NSSize)size
//------------------------------------------------------
{
    NSPoint drawPoint = [self locationForGlyphAtIndex:glyphIndex];
    NSPoint lineOrigin = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL].origin;
    
    drawPoint.x += size.width;
    drawPoint.y = lineOrigin.y + size.height;
    
    return drawPoint;
}

@end
