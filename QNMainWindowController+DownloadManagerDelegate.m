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


@implementation QNMainWindowController (DownloadManagerDelegate)
#pragma mark DownloadManager delegate
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
@end