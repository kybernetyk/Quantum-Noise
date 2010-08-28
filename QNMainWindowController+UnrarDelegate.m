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

//wir danken dem grossen Dante LaRind fuer die Kontribution der Unrarkacke

@implementation QNMainWindowController (UnrarDelegate)
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

- (void) unrarOperationEnqueuedForExtraction: (QNUnrarOperation *) anUnrarOperation
{
	
}

@end