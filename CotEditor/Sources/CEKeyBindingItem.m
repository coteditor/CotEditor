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
#import "CEKeyBindingUtils.h"


@implementation KeyBindingItem

//------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithSelector:(nonnull NSString *)selector keySpecChars:(nullable NSString *)keySpecChars
//------------------------------------------------------
{
    self = [super init];
    if (self) {
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


//------------------------------------------------------
- (nullable NSString *)printableKey
//------------------------------------------------------
{
    return [CEKeyBindingUtils printableKeyStringFromKeySpecChars:[self keySpecChars]];
}

@end


@implementation NamedTreeNode

//------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithName:(nonnull NSString *)name representedObject:(nullable id)representedObject
//------------------------------------------------------
{
    self = [super initWithRepresentedObject:representedObject];
    if (self) {
        _name = name;
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
