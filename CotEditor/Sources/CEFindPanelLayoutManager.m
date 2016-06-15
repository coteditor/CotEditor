/*
 
 CEFindPanelLayoutManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-03-04.

 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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
#import "CEInvisibles.h"
#import "CEDefaults.h"


@interface CEFindPanelLayoutManager ()

@property (nonatomic, nonnull) NSFont *font;

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
        _font = [NSFont systemFontOfSize:0];
    }
    return self;
}


// ------------------------------------------------------
/// fix line height for mixed font
- (void)setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect
// ------------------------------------------------------
{
    CGFloat lineHeight = [self defaultLineHeightForFont:[self font]];
    
    fragmentRect.size.height = lineHeight;
    usedRect.size.height = lineHeight;
    
    [super setLineFragmentRect:fragmentRect forGlyphRange:glyphRange usedRect:usedRect];
}


// ------------------------------------------------------
/// show invisible characters
- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(NSPoint)origin
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey:CEDefaultShowInvisiblesKey]) {
        NSString *completeString = [NSString stringWithString:[[self textStorage] string]];
        
        NSColor *color = [NSColor tertiaryLabelColor];
        NSFont *font = [[self firstTextView] font];
        NSDictionary<NSString *, id> *attributes = @{NSFontAttributeName: font,
                                                     NSForegroundColorAttributeName: color};
        NSFont *fullwidthFont = [NSFont fontWithName:@"HiraKakuProN-W3" size:[font pointSize]] ?: font;
        NSDictionary<NSString *, id> *fullwidthAttributes = @{NSFontAttributeName: fullwidthFont,
                                                              NSForegroundColorAttributeName: color};
        NSFont *replaceFont;
        
        BOOL showsSpace = [defaults boolForKey:CEDefaultShowInvisibleSpaceKey];
        BOOL showsTab = [defaults boolForKey:CEDefaultShowInvisibleTabKey];
        BOOL showsNewLine = [defaults boolForKey:CEDefaultShowInvisibleNewLineKey];
        BOOL showsFullwidthSpace = [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey];
        BOOL showsVerticalTab = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        BOOL showsOtherInvisibles = [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey];
        
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:[CEInvisibles stringWithType:CEInvisibleSpace
                                                                                                      Index:[defaults integerForKey:CEDefaultInvisibleSpaceKey]]
                                                                    attributes:attributes];
        NSAttributedString *tab = [[NSAttributedString alloc] initWithString:[CEInvisibles stringWithType:CEInvisibleTab
                                                                                                    Index:[defaults integerForKey:CEDefaultInvisibleTabKey]]
                                                                  attributes:attributes];
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:[CEInvisibles stringWithType:CEInvisibleNewLine
                                                                                                        Index:[defaults integerForKey:CEDefaultInvisibleNewLineKey]]
                                                                      attributes:attributes];
        NSAttributedString *fullwidthSpace = [[NSAttributedString alloc] initWithString:[CEInvisibles stringWithType:CEInvisibleFullWidthSpace
                                                                                                               Index:[defaults integerForKey:CEDefaultInvisibleNewLineKey]]
                                                                             attributes:fullwidthAttributes];
        NSAttributedString *verticalTab = [[NSAttributedString alloc] initWithString:[CEInvisibles stringWithType:CEInvisibleVerticalTab
                                                                                                            Index:0]
                                                                          attributes:attributes];
        
        // draw invisibles glyph by glyph
        for (NSUInteger glyphIndex = glyphsToShow.location; glyphIndex < NSMaxRange(glyphsToShow); glyphIndex++) {
            NSUInteger charIndex = [self characterIndexForGlyphAtIndex:glyphIndex];
            unichar character = [completeString characterAtIndex:charIndex];
            
            NSAttributedString *glyphString = nil;
            switch (character) {
                case ' ':
                case 0x00A0:
                    if (!showsSpace) { continue; }
                    glyphString = space;
                    break;
                    
                case '\t':
                    if (!showsTab) { continue; }
                    glyphString = tab;
                    break;
                    
                case '\n':
                    if (!showsNewLine) { continue; }
                    glyphString = newLine;
                    break;
                    
                case 0x3000:  // fullwidth-space (JP)
                    if (!showsFullwidthSpace) { continue; }
                    glyphString = fullwidthSpace;
                    break;
                    
                case '\v':
                    if (!showsVerticalTab) { continue; }
                    glyphString = verticalTab;
                    break;
                    
                default:
                    if (showsOtherInvisibles && ([self glyphAtIndex:glyphIndex isValidIndex:NULL] == NSControlGlyph)) {
                        NSGlyphInfo *currentGlyphInfo = [[self textStorage] attribute:NSGlyphInfoAttributeName atIndex:charIndex effectiveRange:NULL];
                        
                        if (currentGlyphInfo) { continue; }
                        
                        replaceFont = replaceFont ?: [NSFont fontWithName:@"Lucida Grande" size:[font pointSize]];
                        
                        NSRange charRange = [self characterRangeForGlyphRange:NSMakeRange(glyphIndex, 1) actualGlyphRange:NULL];
                        NSString *baseString = [completeString substringWithRange:charRange];
                        NSGlyphInfo *glyphInfo = [NSGlyphInfo glyphInfoWithGlyphName:@"replacement" forFont:replaceFont baseString:baseString];
                        
                        if (glyphInfo) {
                            // !!!: The following line can cause crash by binary document.
                            //      It's actually dangerous and to be detoured to modify textStorage while drawing.
                            //      (2015-09 by 1024jp)
                            [[self textStorage] addAttributes:@{NSGlyphInfoAttributeName: glyphInfo,
                                                                NSFontAttributeName: replaceFont,
                                                                NSForegroundColorAttributeName: color}
                                                        range:charRange];
                        }
                    }
                    continue;
            }
            
            // calcurate position to draw glyph
            NSPoint point = [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL withoutAdditionalLayout:YES].origin;
            NSPoint glyphLocation = [self locationForGlyphAtIndex:glyphIndex];
            point.x += origin.x + glyphLocation.x;
            point.y += origin.y;
            
            // draw character
            [glyphString drawAtPoint:point];
        }
    }
    
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
}

@end
