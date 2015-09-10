/*
 
 CEFindPanelLayoutManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-03-04.

 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEFindPanelLayoutManager.h"
#import "CEUtils.h"
#import "Constants.h"


@interface CEFindPanelLayoutManager ()

@property (nonatomic) CGFloat fontSize;

@end




#pragma mark -

@implementation CEFindPanelLayoutManager


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
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
    
    if ([defaults boolForKey:CEDefaultShowInvisiblesKey]) {
        NSTextView *textView = [self firstTextView];
        NSString *completeStr = [NSString stringWithString:[[self textStorage] string]];
        NSUInteger lengthToRedraw = NSMaxRange(glyphsToShow);
        NSSize inset = [textView textContainerInset];
        
        NSColor *color;
        if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10) {
            color = [NSColor tertiaryLabelColor];
        } else {
            color = [NSColor colorWithCalibratedWhite:0.0 alpha:0.25];
        }
        
        NSFont *font = [[self firstTextView] font];
        font = [font screenFont] ? : font;
        NSDictionary<NSString *, id> *attributes = @{NSFontAttributeName: font,
                                                     NSForegroundColorAttributeName: color};
        NSFont *fullwidthFont = [[NSFont fontWithName:@"HiraKakuProN-W3" size:[font pointSize]] screenFont] ? : font;
        NSDictionary<NSString *, id> *fullwidthAttributes = @{NSFontAttributeName: fullwidthFont,
                                                              NSForegroundColorAttributeName: color};
        
        BOOL showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        BOOL showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        BOOL showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        BOOL showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        BOOL showsVerticalTab = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
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
        
        NSAttributedString *verticalTab = [[NSAttributedString alloc] initWithString:[NSString stringWithCharacters:&kVerticalTabChar length:1]
                                                                          attributes:attributes];
        
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
                
            } else if (showsFullwidthSpace && (character == 0x3000)) { // fullwidth-space (JP)
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [fullwidthSpace drawAtPoint:pointToDraw];
                
            } else if (showsVerticalTab && (character == '\v')) {
                NSPoint pointToDraw = [self pointToDrawGlyphAtIndex:glyphIndex adjust:inset];
                [verticalTab drawAtPoint:pointToDraw];
                
            } else if (showsOtherInvisibles && ([self glyphAtIndex:glyphIndex] == NSControlGlyph)) {
                NSFont *replaceFont = [NSFont fontWithName:@"Lucida Grande" size:[font pointSize]];
                NSGlyph replaceGlyph = [replaceFont glyphWithName:@"replacement"];
                NSUInteger charLength = CFStringIsSurrogateHighCharacter(character) ? 2 : 1;
                NSRange charRange = NSMakeRange(charIndex, charLength);
                NSString *baseStr = [completeStr substringWithRange:charRange];
                NSGlyphInfo *glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:replaceGlyph forFont:replaceFont baseString:baseStr];
                
                if (glyphInfo) {
                    NSDictionary<NSString *, id> *replaceAttrs = @{NSGlyphInfoAttributeName: glyphInfo,
                                                                   NSFontAttributeName: replaceFont,
                                                                   NSForegroundColorAttributeName: color};
                    NSDictionary<NSString *, id> *attrs = [[self textStorage] attributesAtIndex:charIndex effectiveRange:NULL];
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
