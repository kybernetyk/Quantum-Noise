//
//  QNBundleManager.m
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadBundleManager.h"
#import "QNDownloadManager.h"
#import "QNDownloadOperation.h"

@implementation QNDownloadBundleManager
@synthesize managedDownloadBundles;

#pragma mark singleton
/*static QNDownloadBundleManager *sharedBundleManager = nil;

+ (QNDownloadBundleManager *) sharedManager
{
    @synchronized(self) 
	{
        if (sharedBundleManager == nil) 
		{
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedBundleManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) 
	{
        if (sharedBundleManager == nil) 
		{
            sharedBundleManager = [super allocWithZone:zone];
            return sharedBundleManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}
*/

+ (id) sharedManager
{
	static dispatch_once_t pred;
	static QNDownloadBundleManager *sharedManager = nil;
	
	dispatch_once(&pred, ^{ sharedManager = [[self alloc] init]; });
	return sharedManager;
}


#pragma mark implementation
- (id) init
{
	self = [super init];
	managedDownloadBundles = [[NSMutableArray alloc] init];
	[self loadState];
	return self;
}

- (void) dealloc
{
	NSLog(@"waring dealloc of singleton!");
	LOG_LOCATION();
	exit(98);
	
	[managedDownloadBundles release];
	[super dealloc];
}

- (void) loadState
{
	NSLog(@"Bundle Manager loading state. %@",SOURCE_LOCATION);
//	LOG_LOCATION();
	
	//NSArray *loadArray = [NSArray arrayWithContentsOfFile: @"/bundles.plist"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *loadArray = [defaults objectForKey: @"QNDownloadBundleManagerState"]; //[defaults setObject: saveArray forKey: @"QNDownloadBundleManagerState"];
	if (!loadArray)
		return;
	
	for (NSDictionary *bundleDict in loadArray)
	{
		NSString *title = [bundleDict objectForKey: @"Title"];
		NSString *password = [bundleDict objectForKey: @"Password"];
		NSArray *URIs = [bundleDict objectForKey: @"URIs"];
		BOOL hasBeenExtracted = [[bundleDict objectForKey:@"hasBeenExtracted"] boolValue];
		
		QNDownloadBundle *ret = [[[QNDownloadBundle alloc] initWithTitle: title 
														 ArchivePassword: password 
																 andURIs: [NSArray arrayWithArray: URIs]] autorelease];
		[ret setHasBeenExtracted: hasBeenExtracted];
		[managedDownloadBundles addObject: ret];
	}
}

- (void) saveState
{
	NSLog(@"Bundle Manager saving state. %@",SOURCE_LOCATION);
	//LOG_LOCATION();
	
	NSMutableArray *saveArray = [NSMutableArray array];
	for (QNDownloadBundle *bundle in managedDownloadBundles)
	{
		NSDictionary *dict = [bundle dictionaryRepresentation];
		[saveArray addObject: dict];
	}
	//[saveArray writeToFile:@"/bundles.plist" atomically: YES];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: saveArray forKey: @"QNDownloadBundleManagerState"];

}

- (id) downloadBundleWithTitle: (NSString *) title ArchivePassword: (NSString *) password andURIs: (NSArray *) URIs
{
	title = [title lowercaseString];
	
	//check if we got this bundle already?
	for (QNDownloadBundle *bundle in managedDownloadBundles)
	{
		if ([[[bundle title] lowercaseString] isEqualToString: [title lowercaseString]])
		{
			NSLog(@"Bundle exists already! adding links to existing bundle");
			LOG_LOCATION();
			
			QNDownloadBundle *dlb = [self downloadBundleForTitle: [title lowercaseString]];
			
			for (NSString *uri in URIs)
				[dlb addURI: [uri lowercaseString]];

			[self saveState];
			return dlb;
		}
	}
	
	
	QNDownloadBundle *ret = [[[QNDownloadBundle alloc] initWithTitle: title ArchivePassword: password andURIs: [NSArray arrayWithArray: URIs]] autorelease];
	
	[managedDownloadBundles addObject: ret];
	[self saveState];
	return ret;
}

- (QNDownloadBundle *) downloadBundleForURI: (NSString *) uri
{
	uri = [uri lowercaseString];
	for (QNDownloadBundle *bundle in managedDownloadBundles)
		if ([bundle containsURI: uri])
			return bundle;
	
	return nil;
}

- (QNDownloadBundle *) downloadBundleForTitle: (NSString *) title
{
	title = [title lowercaseString];
	for (QNDownloadBundle *bundle in managedDownloadBundles)
		if ([[[bundle title] lowercaseString] isEqualToString: [title lowercaseString]])
			return bundle;
	
	return nil;
}


- (void) removeDownloadBundle: (QNDownloadBundle *) bundleToRemove
{
	//copy of our actual array because we may not alter an iterated array
	@synchronized (managedDownloadBundles)
	{
		NSArray *managedBundles = [NSArray arrayWithArray: managedDownloadBundles];
	
		for (QNDownloadBundle *bundle in managedBundles)
		{
			if ([[[bundle title] lowercaseString] isEqualToString: [[bundleToRemove title] lowercaseString]])
			{	
				for (QNDownloadOperation *op in [[QNDownloadManager sharedManager] downloadOperationsForDownloadBundle: bundle])
				{
					[[QNDownloadManager sharedManager] removeDownloadOperation: op];
				}

				[managedDownloadBundles removeObject: bundle];
			}
		}
	}
	[self saveState];
}

@end
