/*
 
 NSFont+CESize.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-22.
 
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


@interface NSFont (CESize)

/**
 Calculate advancement of a character using NSLayoutManager.
 @param range     Character to calculate advancement.
 
 @return Advancement of passed-in character.
 
 @note This method is not light-weigt. You should store the value somewhere to use this repeatedly.
 */
- (CGFloat)advancementForCharacter:(unichar)character;

@end
