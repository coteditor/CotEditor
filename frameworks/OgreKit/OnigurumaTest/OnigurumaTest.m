/*
 * Name: OnigurumaTest.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "oniguruma.h"
#import "OnigurumaTest.h"

@implementation OnigurumaTest

- (IBAction)match:(id)sender
{
	NSString	*targetString = [targetField stringValue];
	NSString	*regexString = [regexField stringValue];
	
	int r;
	unichar *start, *range, *end;
	regex_t* reg;
	OnigErrorInfo einfo;
	OnigRegion *region;
	
	unichar* pattern = (unichar*)malloc(sizeof(unichar) * [regexString length]);
    [regexString getCharacters:pattern];
    
	unichar* str = (unichar*)malloc(sizeof(unichar) * [targetString length]);
    [targetString getCharacters:str];
	
	r = onig_new(&reg, (unsigned char*)pattern, (unsigned char*)(pattern + [regexString length]),
	(ONIG_OPTION_CAPTURE_GROUP), ONIG_ENCODING_UTF16_BE, ONIG_SYNTAX_RUBY, &einfo);
	if (r != ONIG_NORMAL) {
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r, &einfo);
		[resultTextView insertText:[NSString stringWithFormat:@"ERROR: %s\n", s]];
		return;
	}
	
	region = onig_region_new();
	
	end   = str + [targetString length];
	start = str;
	range = end;
	r = onig_search(reg, (unsigned char*)str, (unsigned char*)end, (unsigned char*)start, (unsigned char*)range, region, ONIG_OPTION_NONE);
	
	if (r >= 0) {
		int i;
		
		[resultTextView insertText:[NSString stringWithFormat:@"match at %d\n", r]];
		for (i = 0; i < region->num_regs; i++) {
			[resultTextView insertText:[NSString stringWithFormat:@"%d: (%d-%d)\n", i, region->beg[i] / sizeof(unichar), region->end[i] / sizeof(unichar)]];
		}
	} else if (r == ONIG_MISMATCH) {
		[resultTextView insertText:[NSString stringWithFormat:@"search fail\n"]];
	} else {
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		[resultTextView insertText:[NSString stringWithFormat:@"ERROR: %s\n", s]];
		return;
	}
	
	onig_region_free(region, 1);
	onig_free(reg);
}

- (void)awakeFromNib
{
	[resultTextView setRichText: NO];
	[resultTextView setFont:[NSFont fontWithName:@"Monaco" size:10.0]];
	[resultTextView setContinuousSpellCheckingEnabled:NO];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)aApp
{
	return YES;	// 全てのウィンドウを閉じたら終了する。
}


@end
