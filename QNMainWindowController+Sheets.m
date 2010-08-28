/*
 this file contains the implementation of the main window's action sheet handlers
*/

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



@implementation QNMainWindowController (sheets)


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
		
		NSArray *sortedArray = [sortArray sortedArrayUsingSelector: @selector(localizedCompare:)];
		for (NSString *key in sortedArray)
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


@end