/*
 
 CEErrors.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
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

@import Foundation;


// Error domain
extern NSString *_Nonnull const CEErrorDomain;

typedef NS_ENUM(OSStatus, CEErrorCode) {
    CEInvalidNameError = 1000,
    CEScriptNoTargetDocumentError,
    CEFileReadTooLargeError,
    CEFileReadBinaryFileError,
    
    // encoding errors
    CEIANACharsetNameConflictError = 1100,
    CEUnconvertibleCharactersError,
    CEReinterpretationFailedError,
    CELossyEncodingConversionError,
    
    // text finder
    CERegularExpressionError = 1200,
    
    // setting manager
    CESettingDeletionFailedError = 1300,
    CESettingImportFailedError,
    CESettingImportFileDuplicatedError,
    
    // key binding manager
    CEInvalidKeySpecCharsError = 1400,
    
    // for command-line tool installer
    CEApplicationNotInApplicationDirectoryError = 1500,
    CEApplicationNameIsModifiedError,
    CESymlinkCreationDeniedError,
};
