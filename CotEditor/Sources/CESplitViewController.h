/*
 =================================================
 CESplitViewController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created on 2006-03-26 by nakamuxu
 
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

@import AppKit;


@class CETheme;


@interface CESplitViewController : NSViewController <NSSplitViewDelegate>

- (NSArray *)layoutManagers;

- (void)setShowLineNum:(BOOL)showLineNum;
- (void)setShowNavigationBar:(BOOL)showNavigationBar;
- (void)setWrapLines:(BOOL)wrapLines;
- (void)setShowInvisibles:(BOOL)showInvisibles;
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled;
- (void)setUseAntialias:(BOOL)useAntialias;
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
