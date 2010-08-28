//
//  MainWindowController.m
//  QuantumNoise
//
//  Created by jrk on 08.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNMainWindowController.h"
#import "QNLeftSidebarViewController.h"
#import "QNLeftSidebarItem.h"
#import "QNLeftSidebarItemTypeDefinitions.h"

#import "QNDownloadManager.h"
#import "QNDownloadBundleManager.h"
#import "QNDownloadBundle.h"

#import "QNAddDownloadLinksWindowController.h"
#import "QNCreateNewDownloadBundleWindowController.h"

#import "QNUnrarOperation.h"
#import "NSString+Additions.h"

@implementation QNMainWindowController
#define kMinOutlineViewSplit	100.0f

#pragma mark ctor/dtor
- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow: window];
	if (self)
	{	
		downloadsViewControllerCache = [[NSMutableDictionary alloc] init];
		[[QNDownloadManager sharedManager] setDelegate: self];
	}
	return self;
}

- (void) dealloc
{
	NSLog(@"MainWindowController dealloc");
	//stop observing
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[leftSidebarViewController release];
	leftSidebarViewController = nil;
	

	[downloadsViewControllerCache release];
	
	
	[super dealloc];
}

#pragma mark window delegate 
- (void)windowDidLoad
{
	/*
	 register ourself to receive changes in the user defaults
	 */
	NSUserDefaultsController *defc = [NSUserDefaultsController sharedUserDefaultsController];
	[defc addObserver: self forKeyPath: @"values.maxBandwidthUsage" options: NSKeyValueObservingOptionNew context: @"maxBandwidthUsage"];
	[defc addObserver: self forKeyPath: @"values.maxConcurrentDownloadOperations" options: NSKeyValueObservingOptionNew context: @"maxConcurrentDownloadOperations"];
	
	
	//build window title
	NSString *title =  [NSString stringWithFormat: @"%@ %@ (Codename: %@)",
						[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], 
						[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
						[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Codename"]];
	[[self window] setTitle: title];
	
	
	//create the left sidebar view
	//it will reload its selection state from user defaults
	//and then create the appropriate right side view (by messaging us back that its selection did change. see delegate methods)
	leftSidebarViewController = [[QNLeftSidebarViewController alloc] initWithNibName:@"LeftSidebarView" bundle: nil];
	[leftSidebarViewController setDelegate: self];
	[leftSidebarView addSubview: [leftSidebarViewController view]];
	[[leftSidebarViewController view] setFrame: [leftSidebarView bounds]];

	NSArray *myDatasource = [self dataSourceForLeftSidebar];
	[leftSidebarViewController setContents: myDatasource];
	[leftSidebarViewController reloadContent];

	//create the unrar operation queue
	unrarOperationQueue = [[NSOperationQueue alloc] init];
	[unrarOperationQueue setMaxConcurrentOperationCount: 1];

	//autostart downloading
//	[self pauseResume ...

}

#pragma mark -
#pragma mark KVO observing (for user defaults)
/* we observe the user defaults controller to act when the user changes maxBandwidthUsage or maxConcurrentDownloadOperations */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSString *contextString = (NSString *)context;
	
	if ([contextString isEqualToString: @"maxBandwidthUsage"])
	{
		NSLog(@"setting new dl limit to: %i kbit/s",[[NSUserDefaults standardUserDefaults] integerForKey: @"maxBandwidthUsage"]);
		[[QNDownloadManager sharedManager] setMaxDownloadSpeed: [[NSUserDefaults standardUserDefaults] integerForKey: @"maxBandwidthUsage"] * 1000];
		return;
	}
	
	if ([contextString isEqualToString: @"maxConcurrentDownloadOperations"])
	{
		NSLog(@"setting new max concurrent DLs to: %i",[[NSUserDefaults standardUserDefaults] integerForKey:@"maxConcurrentDownloadOperations"]);
		[[QNDownloadManager sharedManager] setMaxConcurrentDownloads: [[NSUserDefaults standardUserDefaults] integerForKey:@"maxConcurrentDownloadOperations"]];
		return;
	}
	
	[super observeValueForKeyPath:keyPath
						 ofObject:object
						   change:change
						  context:context];
}


#pragma mark Left Sidebar View Controller Delegate
- (void) leftSidebarViewController: (QNLeftSidebarViewController *) aController selectedItemsChangedTo: (NSSet *) selectedItems
{
//TODO: this method is too long. we should cut it down. and remove the hard coded branching stuff

	if ([selectedItems count] == 0)
	{
//		NSLog (@"LOL NO SELECTED ITEMS!");
		[[currentDownloadsViewController view] removeFromSuperview];
		[currentDownloadsViewController release];
		currentDownloadsViewController = nil;
		return;
	}
		
	if (![[[selectedItems allObjects] objectAtIndex: 0] title])
	{
//		NSLog(@"NO TITLE ITEM LOL");
		return;
	}
	
	[[currentDownloadsViewController view] removeFromSuperview];
	[currentDownloadsViewController release];
	
	//did the user a folder icon in the sidebar?
	//if so let's show him all the downloads
	if ([[[[selectedItems allObjects] objectAtIndex: 0] type] isEqualToString: kQNFolderType])
	{
		if ([[[[selectedItems allObjects] objectAtIndex: 0] title] isEqualToString: @"Active Downloads"])
		{
			//NSLog(@"right controller: Active Downloads");
			[[QNDownloadManager sharedManager] selectUnfinishedDownloads];
			QNDownloadsViewController *cachedController = [downloadsViewControllerCache objectForKey: @"Active Downloads"];
			if (!cachedController)
			{
				currentDownloadsViewController = [[QNDownloadsViewController alloc] initWithNibName:@"DownloadsView" bundle: nil];
				[downloadsViewControllerCache setObject: currentDownloadsViewController forKey: @"Active Downloads"];
			}
			else 
			{
				currentDownloadsViewController = [cachedController retain];
			}
		}
		
		if ([[[[selectedItems allObjects] objectAtIndex: 0] title] isEqualToString: @"Finished Downloads"])
		{
			//NSLog(@"right controller: Finished Downloads");
			[[QNDownloadManager sharedManager] selectFinishedDownloads];
			QNDownloadsViewController *cachedController = [downloadsViewControllerCache objectForKey: @"Finished Downloads"];
			if (!cachedController)
			{
				currentDownloadsViewController = [[QNDownloadsViewController alloc] initWithNibName:@"DownloadsView" bundle: nil];
				[downloadsViewControllerCache setObject: currentDownloadsViewController forKey: @"Finished Downloads"];
			}
			else 
			{
				currentDownloadsViewController = [cachedController retain];
			}
		}

	
		if ([[[[selectedItems allObjects] objectAtIndex: 0] title] isEqualToString: @"All Downloads"])
		{
			//NSLog(@"right controller: All Downloads");
			[[QNDownloadManager sharedManager] selectAllDownloads];
			QNDownloadsViewController *cachedController = [downloadsViewControllerCache objectForKey: @"All Downloads"];
			if (!cachedController)
			{
				currentDownloadsViewController = [[QNDownloadsViewController alloc] initWithNibName:@"DownloadsView" bundle: nil];
				[downloadsViewControllerCache setObject: currentDownloadsViewController forKey: @"All Downloads"];
			}
			else 
			{
				currentDownloadsViewController = [cachedController retain];
			}
		}
		
	}
	else 
	{	
		QNDownloadBundle *bundle = [[QNDownloadBundleManager sharedManager] downloadBundleForTitle: [[[selectedItems allObjects] objectAtIndex: 0] title]];
		[[QNDownloadManager sharedManager] selectDownloadsInBundle: bundle];
	
		QNDownloadsViewController *cachedController = [downloadsViewControllerCache objectForKey: [bundle title]];
		if (!cachedController)
		{
			currentDownloadsViewController = [[QNDownloadsViewController alloc] initWithNibName:@"DownloadsView" bundle: nil];
			[downloadsViewControllerCache setObject: currentDownloadsViewController forKey: [bundle title]];
		}
		else
		{
			currentDownloadsViewController = [cachedController retain];
		}
	}

	[[QNDownloadManager sharedManager] reloadSelection];
	[currentDownloadsViewController setDataSource: [[QNDownloadManager sharedManager] selectedDownloads]];
	[currentDownloadsViewController reloadContent];	//update the view to the current state
	[rightContentView addSubview: [currentDownloadsViewController view]];
	[[currentDownloadsViewController view] setFrame: [rightContentView bounds]];
}

- (NSArray *) dataSourceForLeftSidebar
{
	//all
	QNLeftSidebarItem *root = [QNLeftSidebarItem leftSidebarItemWithTitle: @"All Downloads" andType: kQNFolderType];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	for (QNDownloadBundle *bundle in [bundleManager managedDownloadBundles])
	{
		QNLeftSidebarItem *item = [QNLeftSidebarItem leftSidebarItemWithTitle: [bundle title] andType: kQNLeafType];
		//[item setUserData: bundle]; don't rely on this!
		NSLog(@"adding bundle: %@",[bundle title]);
		[root addChildItem: item];
	}
	
	//active
	QNLeftSidebarItem *root2 = [QNLeftSidebarItem leftSidebarItemWithTitle: @"Active Downloads" andType: kQNFolderType];
	for (QNDownloadBundle *bundle in [bundleManager managedDownloadBundles])
	{
		if ([bundle downloadProgress] >= 1.0)
			continue;
		
		QNLeftSidebarItem *item = [QNLeftSidebarItem leftSidebarItemWithTitle: [bundle title] andType: kQNLeafType];
		//[item setUserData: bundle]; don't rely on this!
		[root2 addChildItem: item];
	}
	
	
	//finished
	QNLeftSidebarItem *root3 = [QNLeftSidebarItem leftSidebarItemWithTitle: @"Finished Downloads" andType: kQNFolderType];
	for (QNDownloadBundle *bundle in [bundleManager managedDownloadBundles])
	{
		if ([bundle downloadProgress] < 1.0)
			continue;
		
		QNLeftSidebarItem *item = [QNLeftSidebarItem leftSidebarItemWithTitle: [bundle title] andType: kQNLeafType];
		//[item setUserData: bundle]; don't rely on this!
		[root3 addChildItem: item];
	}
	QNLeftSidebarItem *spacerRow = [QNLeftSidebarItem leftSidebarItemWithTitle:@"\n" andType:kQNHeaderType];
	
	return [NSArray arrayWithObjects: root,spacerRow,root2,spacerRow,root3, nil];
}

#pragma mark - Split View Delegate
// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMin + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
/*- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	return proposedMax - kMinOutlineViewSplit*4;
}*/

// -------------------------------------------------------------------------------
//	splitView:resizeSubviewsWithOldSize:
//
//	Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if ([splitView isVertical])
	{
		NSRect newFrame = [splitView frame]; // get the new size of the whole splitView
		NSView *left = [[splitView subviews] objectAtIndex:0];
		NSRect leftFrame = [left frame];
		NSView *right = [[splitView subviews] objectAtIndex:1];
		NSRect rightFrame = [right frame];
		
		CGFloat dividerThickness = [splitView dividerThickness];
		
		leftFrame.size.height = newFrame.size.height;
		
		rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
		rightFrame.size.height = newFrame.size.height;
		rightFrame.origin.x = leftFrame.size.width + dividerThickness;
		
		[left setFrame:leftFrame];
		[right setFrame:rightFrame];
	}
/*	else //we don't have a horizontal split (yet)
	{	
		//[splitView adjustSubviews];
		//return;
		
		NSRect newFrame = [splitView frame]; // get the new size of the whole splitView
		NSView *top = [[splitView subviews] objectAtIndex:0];
		NSRect topFrame = [top frame];
		
		NSView *bottom = [[splitView subviews] objectAtIndex:1];
		NSRect bottomFrame = [bottom frame];
		
		CGFloat dividerThickness = [splitView dividerThickness];
		
		topFrame.size.width = newFrame.size.width;
		
		bottomFrame.size.height = newFrame.size.height - topFrame.size.height - dividerThickness;
		bottomFrame.size.width = newFrame.size.width;
		bottomFrame.origin.y = topFrame.size.height + dividerThickness;
		
		[top setFrame:topFrame];
		[bottom setFrame:bottomFrame];
	}*/
}

#pragma mark -
#pragma mark button handlers
- (IBAction) pauseResumeDownloading: (id) sender
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	
	if (![downloadManager isRunning])
	{
		[self checkForCompleteBundlesAndProcessThem];
		[downloadManager startDownloading];
		
		[pauseResumeButton setLabel: @"Pause"];
		[pauseResumeButton setImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
		[pauseResumeButton setToolTip: @"Pause all downloads"];
		
		return;
	}
	
	if ([downloadManager isPaused])
	{	
		[downloadManager resumeDownloading];
		[pauseResumeButton setLabel: @"Pause"];
		[pauseResumeButton setImage: [NSImage imageNamed: @"NSIconViewTemplate"]];
		[pauseResumeButton setToolTip: @"Pause all downloads"];
	}
	else
	{	
		[downloadManager pauseDownloading];
		[pauseResumeButton setLabel: @"Resume"];
		[pauseResumeButton setImage: [NSImage imageNamed: @"NSGoRightTemplate"]];
		[pauseResumeButton setToolTip: @"Resume paused downloads"];
	}

}

- (IBAction) cleanupDownloads: (id) sender
{
	NSArray *managedDownloadBundles = [NSArray arrayWithArray: [[QNDownloadBundleManager sharedManager] managedDownloadBundles]];
	
	for (QNDownloadBundle *bundle in managedDownloadBundles)
	{
		NSLog(@"checking download progress for bundle: %@ -> %f",bundle, [bundle downloadProgress]);

		//we don't want to interrupt extracting operations
		if ([bundle isExtracting])
			continue;
				
		//our bundle is finished. let's cleanup
		if ([bundle downloadProgress] >= 1.0)
		{	
			[[QNDownloadBundleManager sharedManager] removeDownloadBundle: bundle];
			continue;
		}

		
		//let's see if any of our bundle's download operations has encountered a fatal error.
		//if so let's remove the bundle
		for (QNDownloadOperation *op in [[QNDownloadManager sharedManager] downloadOperationsForDownloadBundle: bundle])
		{
			if ([op operationError])
			{
				if ([[[[op operationError] userInfo] objectForKey: @"errorLevel"] integerValue] == kQNDownloadOperationErrorFatal)
				{
					NSLog(@"deleting bundle %@ because of error %@ in operation %@",bundle, [op operationError], op);
					[[QNDownloadBundleManager sharedManager] removeDownloadBundle: bundle];
					break;
				}
			}
		}
	}
	
	[self synchronizeViewsWithManagers];
}



@end
