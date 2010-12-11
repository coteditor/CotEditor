/* =============================================================================
	FILE:		UKFileWatcher.h
	PROJECT:	Filie
    
    COPYRIGHT:  (c) 2005 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
    
    LICENSES:   GPL, Modified BSD

	REVISIONS:
		2005-02-25	UK	Created.
   ========================================================================== */

/*
    This is a protocol that file change notification classes should adopt.
    That way, no matter whether you use Carbon's FNNotify/FNSubscribe, BSD's
    kqueue or whatever, the object being notified can react to change
    notifications the same way, and you can easily swap one out for the other
    to cater to different OS versions, target volumes etc.
*/

// -----------------------------------------------------------------------------
//  Protocol:
// -----------------------------------------------------------------------------

@protocol UKFileWatcher

-(void) addPath: (NSString*)path;
-(void) removePath: (NSString*)path;

-(id)   delegate;
-(void) setDelegate: (id)newDelegate;

@end

// -----------------------------------------------------------------------------
//  Methods delegates need to provide:
// -----------------------------------------------------------------------------

@interface NSObject (UKFileWatcherDelegate)

-(void) watcher: (id<UKFileWatcher>)kq receivedNotification: (NSString*)nm forPath: (NSString*)fpath;

@end


// Notifications this sends:
//  (object is the file path registered with, and these are sent via the workspace notification center)
#define UKFileWatcherRenameNotification				@"UKKQueueFileRenamedNotification"
#define UKFileWatcherWriteNotification              @"UKKQueueFileWrittenToNotification"
#define UKFileWatcherDeleteNotification				@"UKKQueueFileDeletedNotification"
#define UKFileWatcherAttributeChangeNotification    @"UKKQueueFileAttributesChangedNotification"
#define UKFileWatcherSizeIncreaseNotification		@"UKKQueueFileSizeIncreasedNotification"
#define UKFileWatcherLinkCountChangeNotification	@"UKKQueueFileLinkCountChangedNotification"
#define UKFileWatcherAccessRevocationNotification	@"UKKQueueFileAccessRevocationNotification"

