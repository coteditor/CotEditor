/*
 
 CEDocumentAnalyzer.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "CEDocumentAnalyzer.h"
#import "CEDocument.h"
#import "CEEditorWrapper.h"
#import "CETextView.h"
#import "CECharacterInfo.h"
#import "CEDefaults.h"

#import "NSString+CECounting.h"
#import "NSString+CEEncoding.h"
#import "NSString+CENewLine.h"


// notifications
NSString *_Nonnull const CEAnalyzerDidUpdateFileInfoNotification = @"CEAnalyzerDidUpdateFileInfoNotification";
NSString *_Nonnull const CEAnalyzerDidUpdateModeInfoNotification = @"CEAnalyzerDidUpdateModeInfoNotification";
NSString *_Nonnull const CEAnalyzerDidUpdateEditorInfoNotification = @"CEAnalyzerDidUpdateEditorInfoNotification";


@interface CEDocumentAnalyzer ()

@property (nonatomic, nullable, weak) CEDocument *document;  // weak to avoid cycle retain

@property (nonatomic, nullable, weak) NSTimer *editorInfoUpdateTimer;

// file infos
@property (readwrite, nonatomic, nullable) NSDate *creationDate;
@property (readwrite, nonatomic, nullable) NSDate *modificationDate;
@property (readwrite, nonatomic, nullable) NSNumber *fileSize;
@property (readwrite, nonatomic, nullable) NSString *filePath;
@property (readwrite, nonatomic, nullable) NSString *owner;
@property (readwrite, nonatomic, nullable) NSNumber *permission;
@property (readwrite, nonatomic, getter=isReadOnly) BOOL readOnly;

// mode infos
@property (readwrite, nonatomic, nullable) NSString *encoding;
@property (readwrite, nonatomic, nullable) NSString *charsetName;
@property (readwrite, nonatomic, nullable) NSString *lineEndings;

// editor infos
@property (readwrite, nonatomic, nullable) NSString *lines;
@property (readwrite, nonatomic, nullable) NSString *chars;
@property (readwrite, nonatomic, nullable) NSString *words;
@property (readwrite, nonatomic, nullable) NSString *length;
@property (readwrite, nonatomic, nullable) NSString *location;
@property (readwrite, nonatomic, nullable) NSString *line;
@property (readwrite, nonatomic, nullable) NSString *column;
@property (readwrite, nonatomic, nullable) NSString *unicode;

@end




#pragma mark -

@implementation CEDocumentAnalyzer

#pragma mark Superclass methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_editorInfoUpdateTimer invalidate];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithDocument:(nonnull CEDocument *)document
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _document = document;
    }
    return self;
}


// ------------------------------------------------------
/// update file info
- (void)invalidateFileInfo
// ------------------------------------------------------
{
    CEDocument *document = [self document];
    NSDictionary<NSString *, id> *attrs = [document fileAttributes];
    
    self.creationDate = [attrs fileCreationDate];
    self.modificationDate = [attrs fileModificationDate];
    self.fileSize = attrs[NSFileSize];
    self.filePath = [[document fileURL] path];
    self.owner = [attrs fileOwnerAccountName];
    self.permission = attrs[NSFilePosixPermissions];
    
    self.readOnly = [attrs fileIsImmutable];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateFileInfoNotification
                                                        object:self];
}


// ------------------------------------------------------
/// update current encoding and line endings
- (void)invalidateModeInfo
// ------------------------------------------------------
{
    CEDocument *document = [self document];
    
    self.encoding = [NSString localizedNameOfStringEncoding:[document encoding] withUTF8BOM:[document hasUTF8BOM]];
    self.charsetName = [NSString IANACharSetNameOfStringEncoding:[document encoding]];
    self.lineEndings = [NSString newLineNameWithType:[document lineEnding]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateModeInfoNotification
                                                        object:self];
}


// ------------------------------------------------------
/// update editor info (only if really needed)
- (void)invalidateEditorInfo
// ------------------------------------------------------
{
    if (![self needsUpdateEditorInfo] && ![self needsUpdateStatusEditorInfo]) { return; }
    
    [self setupEditorInfoUpdateTimer];
}


// ------------------------------------------------------
/// update current editor string info
- (void)updateEditorInfo
// ------------------------------------------------------
{
    BOOL needsAll = [self needsUpdateEditorInfo];
    
    CEDocument *document = [self document];
    NSTextView *textView = [[document editor] focusedTextView];
    
    if (![textView string]) { return; }
    
    NSString *wholeString = [NSString stringWithString:[textView string]];  // LF
    NSRange selectedRange = [textView selectedRange];
    CENewLineType lineEnding = [document lineEnding];
    
    // IM で変換途中の文字列は選択範囲としてカウントしない (2007-05-20)
    if ([textView hasMarkedText]) {
        selectedRange.length = 0;
    }
    
    // calculate on background thread
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL countsLineEnding = [defaults boolForKey:CEDefaultCountLineEndingAsCharKey];
        NSUInteger column = 0, currentLine = 0, location = 0;
        NSUInteger length = 0, selectedLength = 0;
        NSUInteger numberOfLines = 0, numberOfSelectedLines = 0;
        NSUInteger numberOfChars = 0, numberOfSelectedChars = 0;
        NSUInteger numberOfWords = 0, numberOfSelectedWords = 0;
        NSString *unicode;
        
        if (wholeString.length > 0) {
            NSString *selectedString = [wholeString substringWithRange:selectedRange];  // LF
            BOOL hasSelection = (selectedRange.length > 0);
            
            // count length
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarLengthKey]) {
                BOOL isSingleLineEnding = ([[NSString newLineStringWithType:lineEnding] length] == 1);
                NSString *str = isSingleLineEnding ? wholeString : [wholeString stringByReplacingNewLineCharacersWith:lineEnding];
                length = [str length];
                
                if (hasSelection) {
                    str = isSingleLineEnding ? selectedString : [selectedString stringByReplacingNewLineCharacersWith:lineEnding];
                    selectedLength = [str length];
                }
            }
            
            // count characters
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarCharsKey]) {
                NSString *str = countsLineEnding ? wholeString : [wholeString stringByDeletingNewLineCharacters];
                numberOfChars = [str numberOfComposedCharacters];
                if (hasSelection) {
                    str = countsLineEnding ? selectedString : [selectedString stringByDeletingNewLineCharacters];
                    numberOfSelectedChars = [str numberOfComposedCharacters];
                }
            }
            
            // count lines
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarLinesKey]) {
                numberOfLines = [wholeString numberOfLines];
                if (hasSelection) {
                    numberOfSelectedLines = [selectedString numberOfLines];
                }
            }
            
            // count words
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
                numberOfWords = [wholeString numberOfWords];
                if (hasSelection) {
                    numberOfSelectedWords = [selectedString numberOfWords];
                }
            }
            
            // calculate current location
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
                NSString *locString = [wholeString substringToIndex:selectedRange.location];
                NSString *str = countsLineEnding ? locString : [locString stringByDeletingNewLineCharacters];
                location = [str numberOfComposedCharacters];
            }
            
            // calculate current line
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarLineKey]) {
                currentLine = [wholeString lineNumberAtIndex:selectedRange.location];
            }
            
            // calculate current column
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarColumnKey]) {
                NSRange lineRange = [wholeString lineRangeForRange:selectedRange];
                column = selectedRange.location - lineRange.location;  // as length
                column = [[wholeString substringWithRange:NSMakeRange(lineRange.location, column)] numberOfComposedCharacters];
            }
            
            // unicode
            if (needsAll && hasSelection) {
                CECharacterInfo *characterInfo = [CECharacterInfo characterInfoWithString:selectedString];
                if ([[characterInfo unicodes] count] == 1) {
                    unicode = [[[characterInfo unicodes] firstObject] unicode];
                }
            }
        }
        
        // apply to UI
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.length = [self formatCount:length selected:selectedLength];
            self.chars = [self formatCount:numberOfChars selected:numberOfSelectedChars];
            self.lines = [self formatCount:numberOfLines selected:numberOfSelectedLines];
            self.words = [self formatCount:numberOfWords selected:numberOfSelectedWords];
            self.location = [NSString localizedStringWithFormat:@"%li", location];
            self.line = [NSString localizedStringWithFormat:@"%li", currentLine];
            self.column = [NSString localizedStringWithFormat:@"%li", column];
            self.unicode = unicode;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateEditorInfoNotification
                                                                object:self];
        });
    });
}



#pragma mark Private methods

// ------------------------------------------------------
/// format count number with selection
- (NSString *)formatCount:(NSUInteger)count selected:(NSUInteger)selectedCount
// ------------------------------------------------------
{
    if (selectedCount > 0) {
        return [NSString localizedStringWithFormat:@"%li (%li)", count, selectedCount];
    } else {
        return [NSString localizedStringWithFormat:@"%li", count];
    }
}


// ------------------------------------------------------
/// set update timer for information about the content text
- (void)setupEditorInfoUpdateTimer
// ------------------------------------------------------
{
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultInfoUpdateIntervalKey];
    
    if ([[self editorInfoUpdateTimer] isValid]) {
        [[self editorInfoUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    } else {
        [self setEditorInfoUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                                        target:self
                                                                      selector:@selector(updateEditorInfoWithTimer:)
                                                                      userInfo:nil
                                                                       repeats:NO]];
    }
}


// ------------------------------------------------------
/// editor info update timer is fired
- (void)updateEditorInfoWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [[self editorInfoUpdateTimer] invalidate];
    [self updateEditorInfo];
}

@end
