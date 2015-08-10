/*
 
 CEEditorScrollView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-15.
 
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

#import "CEEditorScrollView.h"
#import "CELineNumberView.h"


@implementation CEEditorScrollView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// use custom ruler view
+ (nonnull Class)rulerViewClass
// ------------------------------------------------------
{
    return [CELineNumberView class];
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setHasVerticalRuler:YES];
        [self setHasHorizontalRuler:NO];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    if ([[self documentView] isKindOfClass:[NSTextView class]]) {
        [(NSTextView *)[self documentView] removeObserver:self forKeyPath:@"layoutOrientation"];
    }
}


// ------------------------------------------------------
/// set text view
- (void)setDocumentView:(nullable id)documentView
// ------------------------------------------------------
{
    // observe layout orientation change
    if ([[self documentView] isKindOfClass:[NSTextView class]]) {
        [(NSTextView *)documentView removeObserver:self forKeyPath:@"layoutOrientation"];
    }
    if ([documentView isKindOfClass:[NSTextView class]]) {
        [(NSTextView *)documentView addObserver:self forKeyPath:@"layoutOrientation" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [super setDocumentView:documentView];
}


// ------------------------------------------------------
/// observed key value did update
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqual:@"layoutOrientation"]) {
        switch ([self layoutOrientation]) {
            case NSTextLayoutOrientationHorizontal:
                [self setHasVerticalRuler:YES];
                [self setHasHorizontalRuler:NO];
                break;
                
            case NSTextLayoutOrientationVertical:
                [self setHasVerticalRuler:NO];
                [self setHasHorizontalRuler:YES];
                break;
        };
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// update line numbers
- (void)invalidateLineNumber
// ------------------------------------------------------
{
    [[self lineNumberView] setNeedsDisplay:YES];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return layout orientation of document text view
- (NSTextLayoutOrientation)layoutOrientation
// ------------------------------------------------------
{
    if (![self documentView] || ![[self documentView] isKindOfClass:[NSTextView class]]) { return NSTextLayoutOrientationHorizontal; }  // documentView is "unsafe"
    
    return [(NSTextView *)[self documentView] layoutOrientation];
}


// ------------------------------------------------------
/// return current line number veiw
- (nullable NSRulerView *)lineNumberView
// ------------------------------------------------------
{
    switch ([self layoutOrientation]) {
        case NSTextLayoutOrientationHorizontal:
            return [self verticalRulerView];
            
        case NSTextLayoutOrientationVertical:
            return [self horizontalRulerView];
    }
}

@end
