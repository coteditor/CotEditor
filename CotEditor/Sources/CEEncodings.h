/*
 
 CEEncodings.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
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

@import Foundation;


// Original special encoding type
extern NSInteger const CEAutoDetectEncoding;

// Max length to scan encoding declaration
extern NSUInteger const kMaxEncodingScanLength;

// Encodings list
extern CFStringEncoding kCFStringEncodingList[];
extern NSUInteger const kSizeOfCFStringEncodingList;

// Encodings that need convert Yen mark to back-slash
extern CFStringEncoding kCFStringEncodingInvalidYenList[];
extern NSUInteger const kSizeOfCFStringEncodingInvalidYenList;

// Yen mark char
extern unichar const kYenMark;
