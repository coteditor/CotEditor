/*
 
 CEDocument+Authopen.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-06-29.

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

#import "CEDocument.h"


// ------------------------------------------------------------------------------
// This category is Sandbox incompatible.
// They had been used until CotEditor 2.1.6 (2015-07) which is the last non-Sandboxed version.
// Currently not in use, and should not be used.
// We keep this just for a record.
// You can remove these if you feel it's really needless.
// ------------------------------------------------------------------------------

@interface CEDocument (Authopen)

/// Try reading data at the URL using authopen (Sandobox incompatible)
- (nullable NSData *)forceReadDataFromURL:(nonnull NSURL *)url __attribute__((unavailable("Sandbox incompatible")));

/// Try writing data to the URL using authopen (Sandobox incompatible)
- (BOOL)forceWriteData:(nonnull NSData *)data URL:(nonnull NSURL *)url __attribute__((unavailable("Sandbox incompatible")));

@end
