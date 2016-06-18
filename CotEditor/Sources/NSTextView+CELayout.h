/*
 
 NSTextView+CELayout.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
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

@import Cocoa;


@interface NSTextView (CERange)

- (NSRange)visibleRange;

@end


@interface NSTextView (CETextWrapping)

- (BOOL)wrapsLines;
- (void)setWrapsLines:(BOOL)wrapsLines;

@end


@interface NSTextView (CEScaling)

- (CGFloat)scale;

- (void)setScale:(CGFloat)scale;
- (void)setScale:(CGFloat)scale centeredAtPoint:(NSPoint)point;
- (void)setScaleKeepingVisibleArea:(CGFloat)scale;

@end
