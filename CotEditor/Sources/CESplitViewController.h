/*
 ==============================================================================
 CESplitViewController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2006-03-26 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
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


@class CETheme;


@interface CESplitViewController : NSViewController <NSSplitViewDelegate>

- (NSSplitView *)splitView;
- (NSArray *)layoutManagers;

- (void)setShowsLineNum:(BOOL)showsLineNum;
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar;
- (void)setWrapsLines:(BOOL)wrapsLines;
- (void)setVerticalLayoutOrientation:(BOOL)isVerticalLayoutOrientation;
- (void)setShowsInvisibles:(BOOL)showsInvisibles;
- (void)setShowsPageGuide:(BOOL)showsPageGuide;
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled;
- (void)setUsesAntialias:(BOOL)usesAntialias;
- (void)updateCloseSplitViewButton;

- (void)moveAllCaretToBeginning;
- (void)setTheme:(CETheme *)theme;
- (void)setSyntaxWithName:(NSString *)syntaxName;
- (void)recolorAllTextView;
- (void)updateAllOutlineMenu;
- (void)setAllBackgroundColorWithAlpha:(CGFloat)alpha;

- (IBAction)toggleSplitOrientation:(id)sender;
- (IBAction)focusNextSplitTextView:(id)sender;
- (IBAction)focusPrevSplitTextView:(id)sender;

@end
