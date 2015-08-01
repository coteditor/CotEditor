/*
 
 NSData+MD5.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-07.
 
 ------------
 This category is from the following blog article by iOS Developer Tips.
 We would like to thank for sharing this helpful tip.
 http://iosdevelopertips.com/core-services/create-md5-hash-from-nsstring-nsdata-or-file.html
 Copyright iOSDeveloperTips.com All rights reserved.
 
 ------------------------------------------------------------------------------
 
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

@import Foundation;


@interface NSData (MD5)

- (nonnull NSString *)MD5;

@end
