/*
 
 CESyntaxDictionaryKeys.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-04.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CESyntaxDictionaryKeys.h"


// syntax style keys
NSString * _Nonnull const CESyntaxMetadataKey = @"metadata";
NSString * _Nonnull const CESyntaxExtensionsKey = @"extensions";
NSString * _Nonnull const CESyntaxFileNamesKey = @"filenames";
NSString * _Nonnull const CESyntaxInterpretersKey = @"interpreters";
NSString * _Nonnull const CESyntaxKeywordsKey = @"keywords";
NSString * _Nonnull const CESyntaxCommandsKey = @"commands";
NSString * _Nonnull const CESyntaxTypesKey = @"types";
NSString * _Nonnull const CESyntaxAttributesKey = @"attributes";
NSString * _Nonnull const CESyntaxVariablesKey = @"variables";
NSString * _Nonnull const CESyntaxValuesKey = @"values";
NSString * _Nonnull const CESyntaxNumbersKey = @"numbers";
NSString * _Nonnull const CESyntaxStringsKey = @"strings";
NSString * _Nonnull const CESyntaxCharactersKey = @"characters";
NSString * _Nonnull const CESyntaxCommentsKey = @"comments";
NSString * _Nonnull const CESyntaxCommentDelimitersKey = @"commentDelimiters";
NSString * _Nonnull const CESyntaxOutlineMenuKey = @"outlineMenu";
NSString * _Nonnull const CESyntaxCompletionsKey = @"completions";
NSString * _Nonnull const kAllSyntaxKeys[] = {
    @"keywords",
    @"commands",
    @"types",
    @"attributes",
    @"variables",
    @"values",
    @"numbers",
    @"strings",
    @"characters",
    @"comments"
};
NSUInteger const kSizeOfAllSyntaxKeys = sizeof(kAllSyntaxKeys)/sizeof(kAllSyntaxKeys[0]);

NSString * _Nonnull const CESyntaxKeyStringKey = @"keyString";
NSString * _Nonnull const CESyntaxBeginStringKey = @"beginString";
NSString * _Nonnull const CESyntaxEndStringKey = @"endString";
NSString * _Nonnull const CESyntaxIgnoreCaseKey = @"ignoreCase";
NSString * _Nonnull const CESyntaxRegularExpressionKey = @"regularExpression";

NSString * _Nonnull const CESyntaxInlineCommentKey = @"inlineDelimiter";
NSString * _Nonnull const CESyntaxBeginCommentKey = @"beginDelimiter";
NSString * _Nonnull const CESyntaxEndCommentKey = @"endDelimiter";

NSString * _Nonnull const CESyntaxBoldKey = @"bold";
NSString * _Nonnull const CESyntaxUnderlineKey = @"underline";
NSString * _Nonnull const CESyntaxItalicKey = @"italic";

// comment delimiter keys
NSString * _Nonnull const CEBeginDelimiterKey = @"beginDelimiter";
NSString * _Nonnull const CEEndDelimiterKey = @"endDelimiter";
