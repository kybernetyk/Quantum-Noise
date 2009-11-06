//
//  QNDownloadsViewController.m
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadsViewController.h"
#import "QNDownloadManager.h"
#import "QNDownloadBundleManager.h"
#import "QNDownloadBundle.h"
#import "QNDownloadOperation.h"


@implementation QNDownloadsViewController
@synthesize dataSource;
@synthesize tableView;

- (void) dealloc
{
	NSLog(@"content view dealloc!");
	[dataSource release];
	[super dealloc];
}

- (void) reloadContent
{
	LOG_LOCATION();
	[tableView reloadData];
}

#pragma mark table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [dataSource count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	//QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	//QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	QNDownloadOperation *op = [dataSource objectAtIndex: rowIndex];
	if ([[aTableColumn identifier] isEqualToString: @"url"])
	{	
			return [[op fileName] lastPathComponent];
	}

	if ([[aTableColumn identifier] isEqualToString: @"progress"])
	{
			return [NSString stringWithFormat:@"%.2f %% (%.2f/%.2fmb)", 
					([op progress] * 100.0f),
					([op receivedBytes] / 1000000.0),
					([op fileSize] / 1000000.0)];	
	}
		
	if ([[aTableColumn identifier] isEqualToString: @"speed"])
		return [NSString stringWithFormat:@"%.2f kbit/s", [op downloadSpeed]];
	
	if ([[aTableColumn identifier] isEqualToString: @"status"])
		return [NSString stringWithString: [op status]];
	//else return the best value in the world
	return @"THE HOFF";
}

/*- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	QNDownloadManager *downloadManager = [QNDownloadManager sharedManager];
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	NSTableView *table = [aNotification object];
	
	if ([table tag] == kTagBundlesTable && [table selectedRow] >= 0)
	{
		
		
		NSInteger index = [table selectedRow];
		
		if (index == 0)
		{
			//[downloadManager selectDownloadsInBundle: [bundleManager downloadBundleForTitle: @"Crash"]];
			[downloadManager selectAllDownloads];
			[downloadTable reloadData];
			[self updateUIElements];
			
		}
		else 
		{
			[downloadManager selectDownloadsInBundle: [[bundleManager managedDownloadBundles] objectAtIndex: (index-1)]];
			[downloadTable reloadData]; 
			[self updateUIElements];
		}
		
		
	}
}*/


@end
