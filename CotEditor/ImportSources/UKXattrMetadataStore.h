//
//  UKXattrMetadataStore.h
//  BubbleBrowser
//	LICENSE: MIT License
//
//  Created by Uli Kusterer on 12.03.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

/*
	This is a wrapper around The Mac OS X 10.4 and later xattr API that lets
	you attach arbitrary metadata to a file. Currently it allows querying and
	changing the attributes of a file, as well as retrieving a list of attribute
	names.
	
	It also includes some conveniences for storing/retrieving UTF8 strings,
	and objects as XML property lists in addition to the raw data.
	
	NOTE: keys (i.e. xattr names) are strings of 127 characters or less and
	should be made like bundle identifiers, e.g. @"de.zathras.myattribute".
*/

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
// -----------------------------------------------------------------------------
//	Class declaration:
// -----------------------------------------------------------------------------

@interface UKXattrMetadataStore : NSObject
{
	
}

+(NSArray*)		allKeysAtPath: (NSString*)path traverseLink:(BOOL)travLnk;

// Store UTF8 strings:
+(void)				setString: (NSString*)str forKey: (NSString*)key
						atPath: (NSString*)path traverseLink:(BOOL)travLnk;
+(id)				stringForKey: (NSString*)key atPath: (NSString*)path
						traverseLink:(BOOL)travLnk;

// Store raw data:
+(void)				setData: (NSData*)data forKey: (NSString*)key
						atPath: (NSString*)path traverseLink:(BOOL)travLnk;
+(NSMutableData*)	dataForKey: (NSString*)key atPath: (NSString*)path
						traverseLink:(BOOL)travLnk;

// Store objects: (Only can get/set plist-type objects for now)â
+(void)				setObject: (id)obj forKey: (NSString*)key atPath: (NSString*)path
						traverseLink:(BOOL)travLnk;
+(id)				objectForKey: (NSString*)key atPath: (NSString*)path
						traverseLink:(BOOL)travLnk;

@end

#endif /*MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4*/
