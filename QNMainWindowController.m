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
/*- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"window will klose");
//	[self autorelease];
}
- (void)windowWillLoad
{

}
*/

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
	
	
	
	
	/*QNLeftSidebarItem *item = [QNLeftSidebarItem leftSidebarItemWithTitle: @"ein tierporn" andType: kQNLeafType];
	
	[root addChildItem: item];
	
	QNLeftSidebarItem *spacerRow = [QNLeftSidebarItem leftSidebarItemWithTitle:@"\n" andType:kQNHeaderType];

	QNLeftSidebarItem *root2 = [QNLeftSidebarItem leftSidebarItemWithTitle: @"Finished Downloads" andType: kQNFolderType];
	QNLeftSidebarItem *item2 = [QNLeftSidebarItem leftSidebarItemWithTitle: @"another tierporn" andType: kQNLeafType];
	
	[root2 addChildItem: item2];*/
	
	return [NSArray arrayWithObjects: root,spacerRow,root2,spacerRow,root3, nil];
}

- (void) synchronizeViewsWithManagers
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	//QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];

	[downloadManager reloadSelection];
	[currentDownloadsViewController setDataSource: [[QNDownloadManager sharedManager] selectedDownloads]];
	[currentDownloadsViewController reloadContent];
	
	[leftSidebarViewController setContents: [self dataSourceForLeftSidebar]];
	[leftSidebarViewController reloadContent];
}


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


#pragma mark DownloadOperation delegate
/*- (void) updateUIElements
{	
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	
	[progressBar setDoubleValue: [downloadManager downloadProgressForSelectedDownloads]];
	[overallProgressLabel setDoubleValue: [downloadManager downloadProgressForSelectedDownloads]];
	
	[kbitLabel setDoubleValue: [downloadManager overallDownloadSpeed]];
	
}
*/

- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadProgressDidChange: (QNDownloadOperation *) aDownloadOperation
{
	//make sure the operation is part of the current selection
	//and then reload the current right side table view
	if ([[currentDownloadsViewController dataSource] containsObject: aDownloadOperation])
		[[currentDownloadsViewController tableView] reloadDataForRowIndexes:  [NSIndexSet indexSetWithIndex: [[currentDownloadsViewController dataSource]  indexOfObject: aDownloadOperation]]  columnIndexes: [NSIndexSet indexSetWithIndex: 	[[currentDownloadsViewController tableView] columnWithIdentifier: @"progress"]]];
	
}

- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadSpeedDidChange: (QNDownloadOperation *) aDownloadOperation
{
	NSArray *dataSource = [currentDownloadsViewController dataSource];
	NSTableView *table = [currentDownloadsViewController tableView];
	
	//make sure the operation is part of the current selection
	//and then reload the current right side table view
	if ([dataSource containsObject: aDownloadOperation])
		[table reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: [dataSource indexOfObject: aDownloadOperation]]
								 columnIndexes: [NSIndexSet indexSetWithIndex: 	[table columnWithIdentifier: @"speed"]]];
}

- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDidFinish: (QNDownloadOperation *) aDownloadOperation
{
	NSLog(@"operation finished! %@",aDownloadOperation);

	//if we don't do this here the progress for the operation may show only 99.xx% in the UI and won't get updated anymore
	//as the operation stopped executing (and sending delegate messages)
	[self synchronizeViewsWithManagers];

	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	QNDownloadBundle *bundle = [bundleManager downloadBundleForURI: [aDownloadOperation URI]];

	float bundleprog = [bundle downloadProgress]; 
	//NSLog(@"progress for the bundle %@: %.2f %%",[bundle title], bundleprog * 100.0);
	if (bundleprog >= 1.0)
	{
		//extract all completed bundles
		[self checkForCompleteBundlesAndProcessThem];
	}
	
}

- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationStatusDidChange: (QNDownloadOperation *) aDownloadOperation
{
	NSArray *dataSource = [currentDownloadsViewController dataSource];
	NSTableView *table = [currentDownloadsViewController tableView];

	//make sure the operation is part of the current selection
	//and then reload the current right side table view
	if ([dataSource containsObject: aDownloadOperation])
	{
		[table reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: [dataSource indexOfObject: aDownloadOperation]]
								 columnIndexes: [NSIndexSet indexSetWithIndex: 	[table columnWithIdentifier: @"status"]]];
		
		[table reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: [dataSource indexOfObject: aDownloadOperation]]
								 columnIndexes: [NSIndexSet indexSetWithIndex: 	[table columnWithIdentifier: @"url"]]];
		
	}
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

#pragma mark -
#pragma mark add links sheet (step 1 of adding links)
- (IBAction) addNewLinks: (id) sender
{
	LOG_LOCATION();
	
	QNAddDownloadLinksWindowController *adlwc = [[QNAddDownloadLinksWindowController alloc] initWithWindowNibName:@"QNAddDownloadLinksWindow"];
	
	[NSApp beginSheet: [adlwc window] 
	   modalForWindow: [self window] 
		modalDelegate: self 
	   didEndSelector: @selector(addLinksSheetDidEnd:returnCode:addLinksController:)
		  contextInfo: adlwc];
}

- (void) addLinksSheetDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode addLinksController: (QNAddDownloadLinksWindowController *) controller
{
//	LOG_LOCATION();
	if (returnCode == kAddDownloadLinksSheetReturnCodeContinue)
	{	
		NSLog(@"sheet did end omfg! %@ with retcode %i",controller,returnCode);
		NSLog(@"controller retaincount: %i",[controller retainCount]);
		
		NSLog(@"%@",[controller links]);
		
		if ([[controller links] count] > 0)
			[self createNewDownloadBundleSheetWithLinks: [controller links] andPasswordHint: [controller passwordHint]];

		

		
		if ([[controller links] count] == 0)
		{
			NSLog(@"LOL NO LINKS!");
			LOG_LOCATION();
		}
		
	}
	
	[controller release];
}

#pragma mark -
#pragma mark create new bundle sheet (step 2 of adding links)
- (void) createNewDownloadBundleSheetWithLinks: (NSArray *) links andPasswordHint: (NSString *) passwordHint
{
//	LOG_LOCATION();
	QNCreateNewDownloadBundleWindowController *cndbwc = [[QNCreateNewDownloadBundleWindowController alloc] initWithWindowNibName: @"QNCreateNewDownloadBundleWindow"];
	
	[cndbwc setLinks: links];
	[cndbwc setBundleArchivePassword: passwordHint];
	
	[NSApp beginSheet: [cndbwc window] 
	   modalForWindow: [self window] 
		modalDelegate: self 
	   didEndSelector: @selector(createDownloadBundleSheetDidEnd:returnCode:createBundleController:)
		  contextInfo: cndbwc];
}

- (void) createDownloadBundleSheetDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode createBundleController: (QNCreateNewDownloadBundleWindowController *) controller
{
//	LOG_LOCATION();
	if (returnCode == kCreateDownloadBundleSheetReturnCodeContinue)
	{
		NSLog(@"we will add a new bundle: %@ with password %@ and links %@",[controller bundleTitle], [controller bundleArchivePassword],[controller links]);
		
		QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
		QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
		
		/*
		  sort the bundles alphabetically
		 
		 TODO: make the ugly sort hack go away and implement a custom sorting function or something
		 
		 what we do here is:
			1. we iterate through [controller links] to get the links for each bundle we will create.
			2. we compute the bundle name for each bundle by using the links pathBAseFilename.
			3. for each bundle to create we create a dictionary and store the bundle's title to a sort array.
			4. we sort the sort array alphabetically.
			5. now we created the bundles in order of the sorted array.
		 
			yep, it's ugly and hacky 
		 
		*/
		NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
		NSMutableArray *sortArray = [NSMutableArray array];
		
		for (NSArray *bundleArray in [controller links])
		{
			NSArray *links = [NSArray arrayWithArray: bundleArray];
			NSString *title = [[links objectAtIndex: 0] pathBaseFilename];
			
			/* WARNING: this will not work with multiple bundles from one big link list with multiple links */
			//TODO: make this work with multiple links
/*			if ([controller bundleTitle])
				bundleTitle = [NSString stringWithString: [controller bundleTitle]];*/
			
			NSString *pass = nil;
			if ([controller bundleArchivePassword])
				pass = [NSString stringWithString: [controller bundleArchivePassword]];
		
			NSMutableDictionary *bundleDict = [NSMutableDictionary dictionary];
			
			[bundleDict setObject: links forKey: @"links"];
			[bundleDict setObject: title forKey: @"title"];
			if (pass)
				[bundleDict setObject: pass forKey: @"pass"];
			
			
			[tempDict setObject: bundleDict forKey: title];
			[sortArray addObject: title];
		}
		
		sortArray = [sortArray sortedArrayUsingSelector: @selector(localizedCompare:)];
		for (NSString *key in sortArray)
		{
			NSMutableDictionary *bundleDict = [tempDict objectForKey: key];
			NSArray *links = [bundleDict objectForKey: @"links"];
			NSString *title = [bundleDict objectForKey: @"title"];
			NSString *pass = [bundleDict objectForKey: @"pass"];
			
			
			LOG_LOCATION();
			NSLog(@"making new bundle with: title: %@ - pass: %@",title,pass);
			
			QNDownloadBundle *bundle = [bundleManager downloadBundleWithTitle: title
															  ArchivePassword: pass
																	  andURIs: links];
			[downloadManager enqueueDownloadBundle: bundle];
			
		}
		
		[self synchronizeViewsWithManagers];

		
	}
	
	[controller release];
}

#pragma mark unrar delegate
- (void) unrarOperationDidStart: (QNUnrarOperation *) anUnrarOperation
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	NSLog(@"Extraction did start: %i",[anUnrarOperation progress]);
	NSString *statusString = [NSString stringWithFormat: @"Extracting (%i%%)",(int)([anUnrarOperation progress])];
	
	NSArray *ops = [downloadManager downloadOperationsForFilename: [anUnrarOperation rarfile]];
	if (ops)
	{
		for (QNDownloadOperation *op in ops)
		{
			QNDownloadBundle *bundle = [bundleManager downloadBundleForURI: [op URI]];
			
			/*	NSArray *opsToUpdate = [downloadManager downloadOperationsForDownloadBundle: bundle];
			 
			 for (QNDownloadOperation *opToUpdate in opsToUpdate)
			 {
			 [opToUpdate setStatus: statusString];
			 }*/
			
			[self setValue: statusString forKey: @"status" forAllOperationsInBundle: bundle];			
		}
		
	}
	
}

- (void) unrarOperationProgressDidChange: (QNUnrarOperation *) anUnrarOperation
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	NSLog(@"extraction progress: %i",[anUnrarOperation progress]);
	NSString *statusString = [NSString stringWithFormat: @"Extracting (%i%%)",(int)([anUnrarOperation progress])];
	
	NSArray *ops = [downloadManager downloadOperationsForFilename: [anUnrarOperation rarfile]];
	if (ops)
	{
		for (QNDownloadOperation *op in ops)
		{
			QNDownloadBundle *bundle = [bundleManager downloadBundleForURI: [op URI]];
			
			//	NSArray *opsToUpdate = [downloadManager downloadOperationsForDownloadBundle: bundle];
			[self setValue: statusString forKey: @"status" forAllOperationsInBundle: bundle];
			
			/*for (QNDownloadOperation *opToUpdate in opsToUpdate)
			 {
			 [opToUpdate setStatus: statusString];
			 }*/
			
		}
		
	}
	
	//[[[downloadManager downloadQueue] objectAtIndex: 0] setStatus: ];
	//[downloadTable reloadData];
}

- (void) setValue: (id) value forKey: (id) key forAllOperationsInBundle: (QNDownloadBundle *) bundle
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	
	NSArray *opsToUpdate = [downloadManager downloadOperationsForDownloadBundle: bundle];
	
	for (QNDownloadOperation *opToUpdate in opsToUpdate)
	{
		//[opToUpdate setStatus: statusString];
		[opToUpdate setValue: value forKey: key];
	}
	
	
}

- (void) unrarOperationDidEnd: (QNUnrarOperation *) anUnrarOperation
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	NSLog(@"unrar end with progress: %i",[anUnrarOperation progress]);
	
	NSString *statusString;
	
	if ([anUnrarOperation returnCode] == 0)
	{	
		statusString = [NSString stringWithFormat: @"Extracted (%i%%)",[anUnrarOperation progress]];
	}
	else 
		statusString = [NSString stringWithFormat: @"Extraction failed (unrar returncode: %i)",[anUnrarOperation returnCode]];
	
	NSArray *ops = [downloadManager downloadOperationsForFilename: [anUnrarOperation rarfile]];
	if (ops)
	{
		for (QNDownloadOperation *op in ops)
		{
			QNDownloadBundle *bundle = [bundleManager downloadBundleForURI: [op URI]];
			
			[self setValue: statusString forKey: @"status" forAllOperationsInBundle: bundle];
			[bundle setHasBeenExtracted: YES];
			[bundle setIsExtracting: NO];
		}
		
	}
	
	[downloadManager saveState];
	[bundleManager saveState];
	
}

//well let's call it checkForCompleteBundlesAndUnrarThem
//processing will be done maybe later through plugins ... lol
- (void) checkForCompleteBundlesAndProcessThem
{
	
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	for (QNDownloadBundle *bundle in [bundleManager managedDownloadBundles])
	{
		
		if ([downloadManager downloadProgressForDownloadBundle: bundle] >= 1.0  && ![bundle hasBeenExtracted] && ![bundle isExtracting])
		{
			NSLog(@"Adding bundle %@ to extraction!",[bundle title]);
			
			//make this a member of QNDownloadBundle
			
			
			QNDownloadOperation *op = [[downloadManager downloadOperationsForDownloadBundle: bundle] objectAtIndex: 0];
			NSLog(@"Extracting bundle %@",[bundle title]);
			
			//we will not extract anything other than rars. (and maybe zips later ... but i don't think so)
			if (![[[op fileName] pathExtension] containsString: @"rar" ignoringCase: YES])
			{
				NSLog(@"hey bob, %@ is not a rar file. I won't try this to unrar.", [op fileName]);
				continue; //check next bundle. we're in still in the for (..) loop
			}
				
			[self setValue: @"Queued for Extraction" forKey: @"status" forAllOperationsInBundle: bundle];
			
			QNUnrarOperation *unrarop = [[QNUnrarOperation alloc] 
										 initWithFilename: [op fileName]
										 andPassword: [bundle archivePassword]];
			[unrarop setDelegate: self];
			[bundle setIsExtracting: YES];
			[unrarop autorelease];
			[unrarOperationQueue addOperation: unrarop];
		}
	}
}


@end
