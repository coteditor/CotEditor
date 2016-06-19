/*
 
 CEInspectorTabView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CEInspectorTabView.h"
#import "CESwitcherSegmentedCell.h"


static const CGFloat kControlHeight = 28;


@interface CEInspectorTabView ()

@property (nonatomic, nonnull) NSSegmentedControl *segmentedControl;

@end




#pragma mark -

@implementation CEInspectorTabView

#pragma mark TabView Methods

// ------------------------------------------------------
/// initialize instance
-(nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setTabViewType:NSNoTabsNoBorder];
        
        // setup segmented control
        _segmentedControl = [[NSSegmentedControl alloc] init];
        [_segmentedControl setCell:[[CESwitcherSegmentedCell alloc] init]];
        [_segmentedControl setSegmentStyle:NSSegmentStyleTexturedSquare];
        [_segmentedControl setFrameOrigin:NSMakePoint(0, floor((kControlHeight - [_segmentedControl intrinsicContentSize].height) / 2))];
        [_segmentedControl setAction:@selector(selectTabViewItemWithSegmentedControl:)];
        [_segmentedControl setTarget:self];
        [self addSubview:_segmentedControl];
        
        [self rebuildSegmentedControl];
    }
    
    return self;
}


// ------------------------------------------------------
/// take off control space
- (NSRect)contentRect
// ------------------------------------------------------
{
    NSRect rect = [self bounds];
    rect.origin.y = kControlHeight + 1;  // +1 for border
    rect.size.height -= kControlHeight + 1;
    
    return rect;
}


// ------------------------------------------------------
/// reposition control manually
- (void)setFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    [super setFrame:frameRect];
    [self invalidateControlPosition];
}


// ------------------------------------------------------
/// draw border below control
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];
    
    [NSGraphicsContext saveGraphicsState];
    
    [[NSColor gridColor] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), kControlHeight + 0.5)
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), kControlHeight + 0.5)];
    
    [NSGraphicsContext restoreGraphicsState];
}


// ------------------------------------------------------
/// select also the private control
-(void)selectTabViewItem:(nullable NSTabViewItem *)tabViewItem
// ------------------------------------------------------
{
    [super selectTabViewItem:tabViewItem];
    [self invalidateControlSelection];
}


// ------------------------------------------------------
/// update the private control
-(void)addTabViewItem:(nonnull NSTabViewItem *)anItem
// ------------------------------------------------------
{
    [super addTabViewItem:anItem];
    [self rebuildSegmentedControl];
}


// ------------------------------------------------------
/// update the private control
- (void)insertTabViewItem:(nonnull NSTabViewItem *)tabViewItem atIndex:(NSInteger)index
// ------------------------------------------------------
{
    [super insertTabViewItem:tabViewItem atIndex:index];
    [self rebuildSegmentedControl];
}


// ------------------------------------------------------
/// update the private control
- (void)removeTabViewItem:(nonnull NSTabViewItem *)tabViewItem
// ------------------------------------------------------
{
    [super removeTabViewItem:tabViewItem];
    [self rebuildSegmentedControl];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// switch tab from the private control
-(void)selectTabViewItemWithSegmentedControl:(nonnull NSSegmentedControl *)sender
// ------------------------------------------------------
{
    [super selectTabViewItemAtIndex:[sender selectedSegment]];
}


// ------------------------------------------------------
/// update selection of the private control
- (void)invalidateControlSelection
// ------------------------------------------------------
{
    NSInteger index = [self indexOfTabViewItem:[self selectedTabViewItem]];
    
    if (index == NSNotFound) { return; }
    
    if ([self numberOfTabViewItems] != [[self segmentedControl] segmentCount]) {
        [self rebuildSegmentedControl];
        return;  // This method will be invoked again in `rebuildSegmentedControl`.
    }
    
    [[self segmentedControl] setSelectedSegment:index];
}


// ------------------------------------------------------
/// update private control position
- (void)invalidateControlPosition
// ------------------------------------------------------
{
    CGRect frame = [[self segmentedControl] frame];
    frame.origin.x = floor(([self frame].size.width - frame.size.width) / 2);
    [[self segmentedControl] setFrame:frame];
}


// ------------------------------------------------------
/// update the private control every time when tab item line-up changed
- (void)rebuildSegmentedControl
// ------------------------------------------------------
{
    NSSegmentedControl *control = [self segmentedControl];
    [control setSegmentCount:[self numberOfTabViewItems]];
    [[self tabViewItems] enumerateObjectsUsingBlock:^(NSTabViewItem * _Nonnull item, NSUInteger index, BOOL *stop) {
        [control setImage:[item image] forSegment:index];
        [(NSSegmentedCell *)[control cell] setToolTip:[item toolTip] forSegment:index];
    }];
    [control sizeToFit];
    [self invalidateControlPosition];
    [self invalidateControlSelection];
}

@end
