/*
 ==============================================================================
 CEStatusBarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-11 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@import Cocoa;


@interface CEStatusBarController : NSViewController

@property (nonatomic) BOOL showsReadOnly;

@property (readonly, nonatomic, getter=isShown) BOOL shown;

// editor status
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

// document status
@property (nonatomic, copy) NSString *encodingInfo;
@property (nonatomic, copy) NSString *lineEndingsInfo;
@property (nonatomic) unsigned long long fileSizeInfo;


// Public method
- (void)setShown:(BOOL)shown animate:(BOOL)performAnimation;
- (void)updateEditorStatus;
- (void)updateDocumentStatus;

@end
