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

@implementation QNMainWindowController (Helper)

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



@end