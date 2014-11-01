/*
 ==============================================================================
 NSData+MD5
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-07 by 1024jp
 encoding="UTF-8"
 
 ------------
 This category is from the following blog article by iOS Developer Tips.
 We would like to thank for sharing this helpful tip.
 http://iosdevelopertips.com/core-services/create-md5-hash-from-nsstring-nsdata-or-file.html
 Copyright iOSDeveloperTips.com All rights reserved.
 ------------------------------------------------------------------------------
 
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

#import "NSData+MD5.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSData (MD5)

- (NSString*)MD5
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(self.bytes, self.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
