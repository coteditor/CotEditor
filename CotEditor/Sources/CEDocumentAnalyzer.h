/*
 ==============================================================================
 CEDocumentAnalyzer
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@import Cocoa;


// notifications
extern NSString *__nonnull const CEAnalyzerDidUpdateFileInfoNotification;
extern NSString *__nonnull const CEAnalyzerDidUpdateModeInfoNotification;
extern NSString *__nonnull const CEAnalyzerDidUpdateEditorInfoNotification;


@class CEDocument;


@interface CEDocumentAnalyzer : NSObject

@property (nonatomic, nullable, weak) CEDocument *document;

// file info
@property (readonly, nonatomic, nullable) NSString *creationDate;
@property (readonly, nonatomic, nullable) NSString *modificationDate;
@property (readonly, nonatomic, nullable) NSString *fileSize;
@property (readonly, nonatomic, nullable) NSString *filePath;
@property (readonly, nonatomic, nullable) NSString *owner;
@property (readonly, nonatomic, nullable) NSString *permission;
@property (readonly, nonatomic, getter=isWritable) BOOL writable;

// mode info
@property (readonly, nonatomic, nullable) NSString *encoding;
@property (readonly, nonatomic, nullable) NSString *charsetName;
@property (readonly, nonatomic, nullable) NSString *lineEndings;

// editor info
@property (readonly, nonatomic, nullable) NSString *lines;
@property (readonly, nonatomic, nullable) NSString *chars;
@property (readonly, nonatomic, nullable) NSString *words;
@property (readonly, nonatomic, nullable) NSString *length;
@property (readonly, nonatomic, nullable) NSString *byteLength;
@property (readonly, nonatomic, nullable) NSString *location;  // caret location from the beginning of document
@property (readonly, nonatomic, nullable) NSString *line;      // current line
@property (readonly, nonatomic, nullable) NSString *column;    // caret location from the beginning of line
@property (readonly, nonatomic, nullable) NSString *unicode;   // Unicode of selected single character (or surrogate-pair)


// Public Methods
- (void)updateFileInfo;
- (void)updateModeInfo;
- (void)updateEditorInfo:(BOOL)needsAll;

@end
