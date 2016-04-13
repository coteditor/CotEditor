/*
 
 CEGeometry.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-03-20.
 
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

@import Foundation.NSGeometry;


static inline NSPoint CEScalePoint(NSPoint point, CGFloat scale) {
    point.x *= scale;
    point.y *= scale;
    return point;
}

static inline NSSize CEScaleSize(NSSize size, CGFloat scale) {
    size.width *= scale;
    size.height *= scale;
    return size;
}

static inline NSRect CEScaleRect(NSRect rect, CGFloat scale) {
    rect.origin.x *= scale;
    rect.origin.y *= scale;
    rect.size.width *= scale;
    rect.size.height *= scale;
    return rect;
}

static inline NSPoint CEMidInRect(NSRect rect) {
    return NSMakePoint(NSMidX(rect), NSMidY(rect));
}
