/*
 
 CETextFinder.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-03.

 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import <OgreKit/OgreTextFinder.h>


// notifications
/// Posted when text finder performed "Replace All." Object is target text view.
extern NSString *__nonnull const CETextFinderDidReplaceAllNotification;
extern NSString *__nonnull const CETextFinderDidUnhighlightNotification;


@interface CETextFinder : OgreTextFinder

@end
