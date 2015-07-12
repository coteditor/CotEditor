/*
 ==============================================================================
 CEDocument+Authopen
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-06-29 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEDocument.h"


// ------------------------------------------------------------------------------
// This category is Sandbox incompatible.
// They had been used until CotEditor 2.1.4 (2015-07) which is the last non-sandbox version.
// Currently not in use, and should not be used.
// We keep this just for a record.
// You can remove these if you feel it's really needless.
// ------------------------------------------------------------------------------

@interface CEDocument (Authopen)

/// Try reading data at the URL using authopen (Sandobox incompatible)
- (nullable NSData *)forceReadDataFromURL:(nonnull NSURL *)url __attribute__((unavailable("Sandbox incompatible")));

/// Try writing data to the URL using authopen (Sandobox incompatible)
- (BOOL)forceWriteToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation __attribute__((unavailable("Sandbox incompatible")));

@end
