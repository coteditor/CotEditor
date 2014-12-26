/*
 ==============================================================================
 CEEncodingManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-09-24 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
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

@import Foundation;


// notifications
/// Posted when current encoding list menu items is ready to build
extern NSString *const CEEncodingListDidUpdateNotification;


@interface CEEncodingManager : NSObject

@property (readonly, nonatomic, copy) NSArray *encodingMenuItems;


// singleton
+ (CEEncodingManager *)sharedManager;

@end
