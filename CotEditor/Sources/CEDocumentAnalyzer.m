/*
 
 CEDocumentAnalyzer.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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
#import "NSString+ComposedCharacter.h"
#import "Constants.h"


// notifications
NSString *__nonnull const CEAnalyzerDidUpdateFileInfoNotification = @"CEAnalyzerDidUpdateFileInfoNotification";
NSString *__nonnull const CEAnalyzerDidUpdateModeInfoNotification = @"CEAnalyzerDidUpdateModeInfoNotification";
NSString *__nonnull const CEAnalyzerDidUpdateEditorInfoNotification = @"CEAnalyzerDidUpdateEditorInfoNotification";


@interface CEDocumentAnalyzer ()

// formatters
@property (nonatomic, nonnull) NSNumberFormatter *integerFormatter;
@property (nonatomic, nonnull) NSDateFormatter *dateFormatter;
@property (nonatomic, nonnull) NSByteCountFormatter *byteCountFormatter;

// file infos
@property (readwrite, nonatomic, nullable) NSString *creationDate;
@property (readwrite, nonatomic, nullable) NSString *modificationDate;
@property (readwrite, nonatomic, nullable) NSString *fileSize;
@property (readwrite, nonatomic, nullable) NSString *filePath;
@property (readwrite, nonatomic, nullable) NSString *owner;
@property (readwrite, nonatomic, nullable) NSString *permission;
@property (readwrite, nonatomic, getter=isWritable) BOOL writable;

// mode infos
@property (readwrite, nonatomic, nullable) NSString *encoding;
@property (readwrite, nonatomic, nullable) NSString *charsetName;
@property (readwrite, nonatomic, nullable) NSString *lineEndings;

// editor infos
@property (readwrite, nonatomic, nullable) NSString *lines;
@property (readwrite, nonatomic, nullable) NSString *chars;
@property (readwrite, nonatomic, nullable) NSString *words;
@property (readwrite, nonatomic, nullable) NSString *length;
@property (readwrite, nonatomic, nullable) NSString *byteLength;
@property (readwrite, nonatomic, nullable) NSString *location;
@property (readwrite, nonatomic, nullable) NSString *line;
@property (readwrite, nonatomic, nullable) NSString *column;
@property (readwrite, nonatomic, nullable) NSString *unicode;

@end




#pragma mark -

@implementation CEDocumentAnalyzer

#pragma mark Superclass methods

// ------------------------------------------------------
/// setup
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _integerFormatter = [[NSNumberFormatter alloc] init];
        [_integerFormatter setUsesGroupingSeparator:YES];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// update file info
- (void)updateFileInfo
// ------------------------------------------------------
{
    CEDocument *document = [self document];
    NSDictionary *attrs = [document fileAttributes];
    NSDateFormatter *dateFormatter = [self dateFormatter];
    NSByteCountFormatter *byteFormatter = [self byteCountFormatter];
    
    self.creationDate = [attrs fileCreationDate] ? [dateFormatter stringFromDate:[attrs fileCreationDate]] : nil;
    self.modificationDate = [attrs fileModificationDate] ? [dateFormatter stringFromDate:[attrs fileModificationDate]] : nil;
    self.fileSize = [attrs fileSize] ? [byteFormatter stringFromByteCount:[attrs fileSize]] : nil;
    self.filePath = [[document fileURL] path];
    self.owner = [attrs fileOwnerAccountName];
    self.permission = [attrs filePosixPermissions] ? [NSString stringWithFormat:@"%lo (%@)",
                                                      (unsigned long)[attrs filePosixPermissions],
                                                      humanReadablePermission([attrs filePosixPermissions])] : nil;
    self.writable = [document isWritable];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateFileInfoNotification
                                                        object:self];
}


// ------------------------------------------------------
/// update current encoding and line endings
- (void)updateModeInfo
// ------------------------------------------------------
{
    CEDocument *document = [self document];
    
    self.encoding = [NSString localizedNameOfStringEncoding:[document encoding]];
    self.charsetName = [document currentIANACharSetName];
    self.lineEndings = [NSString newLineNameWithType:[document lineEnding]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateModeInfoNotification
                                                        object:self];
}


// ------------------------------------------------------
/// update current editor string info
- (void)updateEditorInfo:(BOOL)needsAll
// ------------------------------------------------------
{
    CEDocument *document = [self document];
    CEEditorWrapper *editor = [document editor];
    NSNumberFormatter *integerFormatter = [self integerFormatter];
    
    BOOL hasMarked = [[editor focusedTextView] hasMarkedText];
    NSString *wholeString = ([document lineEnding] == CENewLineCRLF) ? [document stringForSave] : [[editor string] copy];
    NSString *selectedString = hasMarked ? nil : [editor substringWithSelection];
    NSStringEncoding encoding = [document encoding];
    __block NSRange selectedRange = [editor selectedRange];
    
    // IM で変換途中の文字列は選択範囲としてカウントしない (2007-05-20)
    if (hasMarked) {
        selectedRange.length = 0;
    }
    
    // calculate on background thread
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(weakSelf) strongSelf = weakSelf;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL countsLineEnding = [defaults boolForKey:CEDefaultCountLineEndingAsCharKey];
        NSUInteger column = 0, currentLine = 0, length = [wholeString length], location = 0;
        NSUInteger numberOfLines = 0, numberOfSelectedLines = 0;
        NSUInteger numberOfChars = 0, numberOfSelectedChars = 0;
        NSUInteger numberOfWords = 0, numberOfSelectedWords = 0;
        NSUInteger byteLength = 0, selectedByteLength = 0;
        NSString *unicode;
        
        if (length > 0) {
            BOOL hasSelection = (selectedRange.length > 0);
            NSRange lineRange = [wholeString lineRangeForRange:selectedRange];
            column = selectedRange.location - lineRange.location;  // as length
            column = [[wholeString substringWithRange:NSMakeRange(lineRange.location, column)] numberOfComposedCharacters];
            
            for (NSUInteger index = 0; index < length; numberOfLines++) {
                if (index <= selectedRange.location) {
                    currentLine = numberOfLines + 1;
                }
                index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
            }
            
            // count selected lines
            if (hasSelection) {
                numberOfSelectedLines = [[selectedString componentsSeparatedByString:@"\n"] count];
                if ([selectedString hasSuffix:@"\n"]) {
                    numberOfSelectedLines--;
                }
            }
            
            // count words
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarWordsKey]) {
                NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
                numberOfWords = [spellChecker countWordsInString:wholeString language:nil];
                if (hasSelection) {
                    numberOfSelectedWords = [spellChecker countWordsInString:selectedString language:nil];
                }
            }
            
            // count location
            if (needsAll || [defaults boolForKey:CEDefaultShowStatusBarLocationKey]) {
                NSString *locString = [wholeString substringToIndex:selectedRange.location];
                NSString *str = countsLineEnding ? locString : [locString stringByDeletingNewLineCharacters];
                
                location = [str numberOfComposedCharacters];
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
            
            // re-calculate length without line ending if needed
            if (!countsLineEnding) {
                length = [[wholeString stringByDeletingNewLineCharacters] length];
                selectedRange.length = [[selectedString stringByDeletingNewLineCharacters] length];
            }
            
            if (needsAll) {
                // unicode
                if (selectedRange.length == 2) {
                    unichar firstChar = [wholeString characterAtIndex:selectedRange.location];
                    unichar secondChar = [wholeString characterAtIndex:selectedRange.location + 1];
                    if (CFStringIsSurrogateHighCharacter(firstChar) && CFStringIsSurrogateLowCharacter(secondChar)) {
                        UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(firstChar, secondChar);
                        unicode = [NSString stringWithFormat:@"U+%04tX", pair];
                    }
                }
                if (selectedRange.length == 1) {
                    unichar character = [wholeString characterAtIndex:selectedRange.location];
                    unicode = [NSString stringWithFormat:@"U+%.4X", character];
                }
                
                // count byte length
                byteLength = [wholeString lengthOfBytesUsingEncoding:encoding];
                selectedByteLength = [selectedString lengthOfBytesUsingEncoding:encoding];
            }
        }
        
        // apply to UI
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.lines = [strongSelf formatCount:numberOfLines selected:numberOfSelectedLines];
            strongSelf.length = [strongSelf formatCount:length selected:selectedRange.length];
            strongSelf.chars = [strongSelf formatCount:numberOfChars selected:numberOfSelectedChars];
            strongSelf.byteLength = [strongSelf formatCount:byteLength selected:selectedByteLength];
            strongSelf.words = [strongSelf formatCount:numberOfWords selected:numberOfSelectedWords];
            strongSelf.location = [integerFormatter stringFromNumber:@(location)];
            strongSelf.line = [integerFormatter stringFromNumber:@(currentLine)];
            strongSelf.column = [integerFormatter stringFromNumber:@(column)];
            strongSelf.unicode = unicode;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEAnalyzerDidUpdateEditorInfoNotification
                                                                object:strongSelf];
        });
    });
}



#pragma mark Private methods

// ------------------------------------------------------
/// format count number with selection
- (NSString *)formatCount:(NSUInteger)count selected:(NSUInteger)selectedCount
// ------------------------------------------------------
{
    NSNumberFormatter *formatter = [self integerFormatter];
    
    if (selectedCount > 0) {
        return [NSString stringWithFormat:@"%@ (%@)",
                [formatter stringFromNumber:@(count)], [formatter stringFromNumber:@(selectedCount)]];
    } else {
        return [NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(count)]];
    }
}


// ------------------------------------------------------
/// create human-readable permission expression from integer
NSString *humanReadablePermission(NSUInteger permission)
// ------------------------------------------------------
{
    NSArray *units = @[@"---", @"--x", @"-w-", @"-wx", @"r--", @"r-x", @"rw-", @"rwx"];
    NSMutableString *result = [NSMutableString stringWithString:@"-"];  // Document is always file.
    
    for (NSInteger i = 2; i >= 0; i--) {
        NSUInteger digit = (permission >> (i * 3)) & 0x7;
        
        [result appendString:units[digit]];
    }
    
    return [result copy];
}

@end
