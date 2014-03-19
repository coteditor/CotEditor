/*
=================================================
CEPrivateMutableArray
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2008.04.27

------------
＜要素の追加速度向上を目的としたカスタム配列クラス＞
こちらの記事を参考にさせていただきました
http://www.mulle-kybernetik.com/artikel/Optimization/opti.html
http://homepage.mac.com/mkino2/spec/optimize/index.html
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEPrivateMutableArray.h"


@interface CEPrivateMutableArray ()
{
    id *_pointers;
    NSUInteger _size;
    NSUInteger _nPointers;
}

@end

@implementation CEPrivateMutableArray


- (id)initWithCapacity:(NSUInteger)inSize
{
    [super init];

    _pointers = malloc( sizeof(id) * inSize);
    _nPointers = 0;
    _size = inSize;

    return( self);
}


- (void)dealloc
{
    NSUInteger i;
   
    for (i = 0; i < _nPointers; i++) {
        [_pointers[ i] release];
    }

    free(_pointers);

    [super dealloc];
}


- (void)grow
{
    NSUInteger newsize;

    if ((newsize = _size + _size) < _size + 4) {
        newsize = _size + 4;
    }
    if (!(_pointers = realloc(_pointers, newsize * sizeof(id)))) {
        [NSException raise:NSMallocException
                    format:@"%@ can't grow from %lu to %lu entries", self, (unsigned long)_size, (unsigned long)newsize];
    }
    _size = newsize;
}


- (void)addObject:(id)inObject
{
    if (!inObject) {
        [NSException raise:NSInvalidArgumentException format:@"null pointer"];
    }
    if (_nPointers >= _size) {
        [self grow];
    }
    self->_pointers[self->_nPointers++] = [inObject retain];
}


- (NSUInteger)count
{
    return (_nPointers);
}


- (id)objectAtIndex:(NSUInteger)inIndex
{
    if (inIndex >= _nPointers) {
        [NSException raise:NSInvalidArgumentException 
                    format:@"index %lu out of bounds %lu", (unsigned long)inIndex, (unsigned long)_nPointers];
    }

    return (_pointers[inIndex]);
}

- (void)addObjectsFromArray:(CEPrivateMutableArray *)inArray
{
    if (!inArray) { return; }

    for (id object in inArray) {
        [self addObject:object];
    }
}

@end
