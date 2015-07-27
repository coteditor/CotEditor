/*
 ==============================================================================
 CENavigationBarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-08-22 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

@import AppKit;


@interface CENavigationBarController : NSViewController

@property (nonatomic, nullable, strong) NSTextView *textView;  // NSTextView cannot be weak

@property (readonly, nonatomic, getter=isShown) BOOL shown;


// Public method
- (void)setShown:(BOOL)shown animate:(BOOL)performAnimation;

- (void)setOutlineMenuItems:(nonnull NSArray *)outlineItems;
- (void)selectOutlineMenuItemWithRange:(NSRange)range;
- (void)updatePrevNextButtonEnabled;
- (BOOL)canSelectPrevItem;
- (BOOL)canSelectNextItem;
- (void)showOutlineIndicator;

- (void)setCloseSplitButtonEnabled:(BOOL)enabled;
- (void)setSplitOrientationVertical:(BOOL)isVertical;


// action messages
- (IBAction)selectPrevItem:(nullable id)sender;
- (IBAction)selectNextItem:(nullable id)sender;

@end
