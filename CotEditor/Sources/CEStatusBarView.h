/*
=================================================
CEStatusBarView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.30

------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
arranged by 1024jp, Mar 2014.
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

@import Cocoa;


@class CEEditorView;

@interface CEStatusBarView : NSView

@property (nonatomic, weak) CEEditorView *masterView;
@property (nonatomic) BOOL showStatusBar;

@property (nonatomic) NSInteger linesInfo;
@property (nonatomic) NSInteger selectedLinesInfo;
@property (nonatomic) NSInteger charsInfo;
@property (nonatomic) NSInteger selectedCharsInfo;
@property (nonatomic) NSInteger lengthInfo;
@property (nonatomic) NSInteger selectedLengthInfo;
@property (nonatomic) NSInteger wordsInfo;
@property (nonatomic) NSInteger selectedWordsInfo;
@property (nonatomic) NSInteger locationInfo;
@property (nonatomic) NSInteger lineInfo;
@property (nonatomic) NSInteger columnInfo;

@property (nonatomic, copy) NSString *encodingInfo;
@property (nonatomic, copy) NSString *lineEndingsInfo;
@property (nonatomic) NSInteger fileSizeInfo;


// Public method

- (void)setShowsReadOnlyIcon:(BOOL)showsReadOnlyIcon;
- (void)updateLeftField;
- (void)updateRightField;

@end
