//
//  QNBundleManager.h
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNDownloadBundle.h"

@interface QNDownloadBundleManager : NSObject 
{
	NSMutableArray *managedDownloadBundles;
}

@property (readonly) NSArray *managedDownloadBundles;

//singleton
+ (QNDownloadBundleManager *) sharedManager;


//creates a bundle and registers it
- (id) downloadBundleWithTitle: (NSString *) title ArchivePassword: (NSString *) password andURIs: (NSArray *) URIs;

- (QNDownloadBundle *) downloadBundleForURI: (NSString *) uri;
- (QNDownloadBundle *) downloadBundleForTitle: (NSString *) title;

//will remove the download bundle from the bundlemanager
//AND all associated downloadoperations from the downloadmanager
- (void) removeDownloadBundle: (QNDownloadBundle *) bundleToRemove;

- (void) loadState;
- (void) saveState;

@end
