/*
 
 CEKeyBindingItem.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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

#import "CEKeyBindingItem.h"


@implementation CEKeyBindingItem

//------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithTitle:(NSString *)title selector:(nonnull NSString *)selector keySpecChars:(nullable NSString *)keySpecChars
//------------------------------------------------------
{
    self = [super init];
    if (self) {
        _title = title;
        _selector = selector;
        _keySpecChars = keySpecChars;
    }
    return self;
}


//------------------------------------------------------
/// disable superclass's designated initializer
- (nonnull instancetype)init
//------------------------------------------------------
{
    @throw nil;
}

@end




#pragma -

@implementation CEKeyBindingContainerItem

//------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithTitle:(NSString *)title children:(nonnull NSArray<CEKeyBindingItem *> *)children
//------------------------------------------------------
{
    self = [super init];
    if (self) {
        _title = title;
        _children = children;
    }
    return self;
}


//------------------------------------------------------
/// disable superclass's designated initializer
- (nonnull instancetype)init
//------------------------------------------------------
{
    @throw nil;
}

@end
