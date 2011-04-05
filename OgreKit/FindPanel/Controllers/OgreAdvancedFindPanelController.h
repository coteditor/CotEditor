/*
 * Name: OgreAdvancedFindPanelController.h
 * Project: OgreKit
 *
 * Creation Date: Sep 14 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreTextFindThread.h>

@class OgreAFPCEscapeCharacterFormatter, OgreFindResultWindowController;

@interface OgreAdvancedFindPanelController : OgreFindPanelController 
{
	IBOutlet NSTextView		*findTextView;
	IBOutlet NSTextView		*replaceTextView;

	IBOutlet NSDrawer		*moreOptionsDrawer;
	IBOutlet NSPopUpButton	*escapeCharacterPopUpButton;
	IBOutlet NSPopUpButton	*syntaxPopUpButton;
	IBOutlet NSColorWell	*highlightColorWell;
	IBOutlet NSTextField	*maxNumOfFindHistoryTextField;
	IBOutlet NSTextField	*maxNumOfReplaceHistoryTextField;
	
	IBOutlet NSView			*findReplaceTextBox;
	IBOutlet NSView			*styleOptionsBox;
	IBOutlet NSButton		*toggleStyleOptionsButton;
	
	NSMutableArray			*_findHistory;
	NSMutableArray			*_replaceHistory;
	IBOutlet NSPopUpButton	*findPopUpButton;
	IBOutlet NSPopUpButton	*replacePopUpButton;
	
	BOOL					singleLineOption;
	BOOL					multilineOption;
	BOOL					ignoreCaseOption;
	BOOL					extendOption;
	BOOL					findLongestOption;
	BOOL					findNotEmptyOption;
	BOOL					findEmptyOption;
	BOOL					negateSingleLineOption;
	BOOL					captureGroupOption;
	BOOL					dontCaptureGroupOption;
	BOOL					delimitByWhitespaceOption;
	BOOL					notBeginOfLineOption;
	BOOL					notEndOfLineOption;
	BOOL					replaceWithStylesOption;
	BOOL					replaceFontsOption;
	BOOL					mergeStylesOption;
	
	BOOL					regularExpressionsOption;
	
	BOOL					wrapSearchOption;
	
	BOOL					openSheetOption;
	BOOL					closeWhenDoneOption;
	
	BOOL					atTopOriginOption;
	BOOL					inSelectionScopeOption;
	
	BOOL					_isAlertSheetOpen;
	
	OgreAFPCEscapeCharacterFormatter	*_escapeCharacterFormatter;
	
	IBOutlet NSButton		*findNextButton;
	IBOutlet NSButton		*moreOptionsButton;
	
	OgreFindResultWindowController	*_findResultWindowController;
	
	BOOL					_altKeyDown;
	BOOL					_tmpInSelection;
}

/* find/replace/highlight actions */
- (IBAction)findAll:(id)sender;

- (IBAction)findNext:(id)sender;
- (IBAction)findNextAndOrderOut:(id)sender;
- (OgreTextFindResult*)findNextStrategy;

- (IBAction)findPrevious:(id)sender;
- (IBAction)findSelectedText:(id)sender;
- (IBAction)highlight:(id)sender;
- (IBAction)jumpToSelection:(id)sender;
- (IBAction)replace:(id)sender;
- (IBAction)replaceAll:(id)sender;
- (IBAction)replaceAndFind:(id)sender;
- (IBAction)unhighlight:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)useSelectionForReplace:(id)sender;

- (IBAction)clearFindStringStyles:(id)sender;
- (IBAction)clearReplaceStringStyles:(id)sender;

/* update settings */
- (IBAction)updateEscapeCharacter:(id)sender;
- (IBAction)updateOptions:(id)sender;
- (IBAction)updateSyntax:(id)sender;
- (void)avoidEmptySelection;
- (void)setStartFromCursor;
- (IBAction)toggleStyleOptions:(id)sender;

/* delegate methods of OgreAdvancedFindPanel */
- (void)findPanelFlagsChanged:(unsigned)modifierFlags;
- (void)findPanelDidAddChildWindow:(NSWindow*)childWindow;
- (void)findPanelDidRemoveChildWindow:(NSWindow*)childWindow;

/* settings */
- (NSString*)escapeCharacter;
- (BOOL)shouldEquateYenWithBackslash;
- (BOOL)isStartFromTop;
- (BOOL)isWrap;
- (unsigned)options;
- (unsigned)_options;
- (OgreSyntax)syntax;

/* find/replace history */
- (void)addFindHistory:(NSAttributedString*)string;
- (void)addReplaceHistory:(NSAttributedString*)string;
- (IBAction)clearFindReplaceHistories:(id)sender;
- (IBAction)selectFindHistory:(id)sender;
- (IBAction)selectReplaceHistory:(id)sender;

- (void)setFindString:(NSAttributedString*)attrString;
- (void)setReplaceString:(NSAttributedString*)attrString;
- (void)undoableReplaceCharactersInRange:(NSRange)oldRange 
	withAttributedString:(NSAttributedString*)newString 
	inTarget:(NSTextView*)aTextView;

/* restore history/settings */
- (void)restoreHistory:(NSDictionary*)history;

/* show alert */
- (BOOL)alertIfInvalidRegex;
- (void)showErrorAlert:(NSString*)title message:(NSString*)message;

/* load find string to/from pasteboard */
- (void)loadFindStringFromPasteboard;
- (void)loadFindStringToPasteboard;

/* accessors */
- (BOOL)singleLineOption;
- (void)setSingleLineOption:(BOOL)singleLineOption;
- (BOOL)multilineOption;
- (void)setMultilineOption:(BOOL)multilineOption;
- (BOOL)ignoreCaseOption;
- (void)setIgnoreCaseOption:(BOOL)ignoreCaseOption;
- (BOOL)extendOption;
- (void)setExtendOption:(BOOL)extendOption;
- (BOOL)findLongestOption;
- (void)setFindLongestOption:(BOOL)findLongestOption;
- (BOOL)findNotEmptyOption;
- (void)setFindNotEmptyOption:(BOOL)findNotEmptyOption;
- (BOOL)findEmptyOption;
- (void)setFindEmptyOption:(BOOL)findEmptyOption;
- (BOOL)negateSingleLineOption;
- (void)setNegateSingleLineOption:(BOOL)negateSingleLineOption;
- (BOOL)captureGroupOption;
- (void)setCaptureGroupOption:(BOOL)captureGroupOption;
- (BOOL)dontCaptureGroupOption;
- (void)setDontCaptureGroupOption:(BOOL)dontCaptureGroupOption;
- (BOOL)delimitByWhitespaceOption;
- (void)setDelimitByWhitespaceOption:(BOOL)delimitByWhitespaceOption;
- (BOOL)notBeginOfLineOption;
- (void)setNotBeginOfLineOption:(BOOL)notBeginOfLineOption;
- (BOOL)notEndOfLineOption;
- (void)setNotEndOfLineOption:(BOOL)notEndOfLineOption;
- (BOOL)replaceWithStylesOption;
- (void)setReplaceWithStylesOption:(BOOL)replaceWithStylesOption;
- (BOOL)replaceFontsOption;
- (void)setReplaceFontsOption:(BOOL)replaceFontsOption;
- (BOOL)mergeStylesOption;
- (void)setMergeStylesOption:(BOOL)mergeStylesOption;
	
- (BOOL)regularExpressionsOption;
- (void)setRegularExpressionsOption:(BOOL)regularExpressionsOption;
	
- (BOOL)wrapSearchOption;
- (void)setWrapSearchOption:(BOOL)wrapSearchOption;
	
- (BOOL)openSheetOption;
- (void)setOpenSheetOption:(BOOL)openSheetOption;
- (BOOL)closeWhenDoneOption;
- (void)setCloseWhenDoneOption:(BOOL)closeWhenDoneOption;
	
- (BOOL)atTopOriginOption;
- (void)setAtTopOriginOption:(BOOL)atTopOriginOption;
- (BOOL)inSelectionScopeOption;
- (void)setInSelectionScopeOption:(BOOL)inSelectionScopeOption;

@end
