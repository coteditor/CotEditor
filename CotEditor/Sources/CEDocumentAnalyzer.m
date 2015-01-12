/*
 ==============================================================================
 CEDocumentAnalyzer
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-18 by 1024jp
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

#import "CEDocumentAnalyzer.h"
#import "CEDocument.h"
#import "NSString+ComposedCharacter.h"
#import "constants.h"


// notifications
NSString *const CEAnalyzerDidUpdateFileInfoNotification = @"CEAnalyzerDidUpdateFileInfoNotification";
NSString *const CEAnalyzerDidUpdateModeInfoNotification = @"CEAnalyzerDidUpdateModeInfoNotification";
NSString *const CEAnalyzerDidUpdateEditorInfoNotification = @"CEAnalyzerDidUpdateEditorInfoNotification";


@interface CEDocumentAnalyzer ()

// formatters
@property (nonatomic) NSNumberFormatter *integerFormatter;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) NSByteCountFormatter *byteCountFormatter;

// file infos
@property (readwrite, nonatomic) NSString *creationDate;
@property (readwrite, nonatomic) NSString *modificationDate;
@property (readwrite, nonatomic) NSString *fileSize;
@property (readwrite, nonatomic) NSString *filePath;
@property (readwrite, nonatomic) NSString *owner;
@property (readwrite, nonatomic) NSString *permission;
@property (readwrite, nonatomic) NSString *locked;

// mode infos
@property (readwrite, nonatomic) NSString *encoding;
@property (readwrite, nonatomic) NSString *charsetName;
@property (readwrite, nonatomic) NSString *lineEndings;

// editor infos
@property (readwrite, nonatomic) NSString *lines;
@property (readwrite, nonatomic) NSString *chars;
@property (readwrite, nonatomic) NSString *words;
@property (readwrite, nonatomic) NSString *length;
@property (readwrite, nonatomic) NSString *byteLength;
@property (readwrite, nonatomic) NSString *location;
@property (readwrite, nonatomic) NSString *line;
@property (readwrite, nonatomic) NSString *column;
@property (readwrite, nonatomic) NSString *unicode;

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
    NSDictionary *attrs = [[self document] fileAttributes];
    NSDateFormatter *dateFormatter = [self dateFormatter];
    NSByteCountFormatter *byteFormatter = [self byteCountFormatter];
    
    self.creationDate = [attrs fileCreationDate] ? [dateFormatter stringFromDate:[attrs fileCreationDate]] : nil;
    self.modificationDate = [attrs fileModificationDate] ? [dateFormatter stringFromDate:[attrs fileModificationDate]] : nil;
    self.fileSize = [attrs fileSize] ? [byteFormatter stringFromByteCount:[attrs fileSize]] : nil;
    self.filePath = [[[self document] fileURL] path];
    self.owner = [attrs fileOwnerAccountName];
    self.permission = [attrs filePosixPermissions] ? [NSString stringWithFormat:@"%tu (%@)",
                                                      [attrs filePosixPermissions],
                                                      humanReadablePermission([attrs filePosixPermissions])] : nil;
    self.locked = attrs ? NSLocalizedString([attrs fileIsImmutable] ? @"Yes" : @"No", nil) : nil;
    
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
        typeof(self) strongSelf = weakSelf;
        
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



#pragma mark Plivate methods
                                     
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
    NSMutableString *result = [NSMutableString stringWithString:@"-"];  // always file
    
    for (NSInteger i = 2; i >= 0; i--) {
        NSUInteger digit = (permission >> (i * 3)) & 0x7;
        
        [result appendString:units[digit]];
    }
    
    return [result copy];
}

@end
