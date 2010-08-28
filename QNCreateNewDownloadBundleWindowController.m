//
//  QNCreateNewDownloadBundleWindowController.m
//  DummyDownload
//
//  Created by jrk on 15/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNCreateNewDownloadBundleWindowController.h"
#import "QNDownloadBundleManager.h"
#import "NSString+Additions.h"

#pragma mark -
#pragma mark implementation
@implementation QNCreateNewDownloadBundleWindowController
@synthesize links;
@synthesize bundleTitle;
@synthesize bundleArchivePassword;

#pragma mark -
#pragma mark init/dealloc
/*- (NSString *) bundleTitleForLink: (NSString *) link
{
	NSArray *comps = [link pathComponents];
	
	NSLog(@"%@",comps);
	NSLog(@"last item: %@",[comps lastObject]);
	NSLog(@"path ext: %@",[link pathExtension]);
	
	NSRange range;
	range.location = 0;
	range.length = [[link lastPathComponent] length];
	
	NSString *title = [[link lastPathComponent] stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".%@",[link pathExtension]]
																			   withString:@""
																				  options: NSCaseInsensitiveSearch
																					range: range
					   ];
	
	//omg that's so lame
	//we need REGEXP MAN!
	for (int i = 0; i < 255; i++)
	{
		range.length = [title length];
		title = [title stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".part%i", i]
												 withString: @""
													options: NSCaseInsensitiveSearch
													  range: range
				 
				 ];
	}
	
	return title;
}*/

- (void) dealloc
{
	[links release];
	[bundleTitle release];
	[bundleArchivePassword release];
	
	LOG_LOCATION();
	[super dealloc];
}

/*
 why setting up bindings programmatically?
 because it's fucking unclear with the IB and you could forget WHY THE FUCKING MAGIC IS HAPPENING!
*/
- (void) windowDidLoad
{
	if (links && [links count] > 0)
	{
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool: YES] forKey: @"NSContinuouslyUpdatesValueBindingOption"];
		
		//set up bindings so that the view will get changes of our properties
		//this is only one way! for biderectional read http://www.ericmethot.com/code/cocoa/bidirectional-bindings/
		//but that would be 
		[bundleNameTextField bind:@"stringValue" toObject: self withKeyPath:@"bundleTitle" options: options];
		[archivePasswordTextField bind:@"stringValue" toObject: self withKeyPath:@"bundleArchivePassword" options: options];
		
		
		//lets extract a name for our bundle from the first link
		NSString *firstLink = [[links objectAtIndex: 0] objectAtIndex: 0];
		
		if ([links count] > 1)
		{	
			[self setBundleTitle: @"<Multiple>"];
		}
		else
		{	//set this new title
			[self setBundleTitle: [firstLink pathBaseFilename]];	
		}
		
	}

}

- (void)windowWillClose:(NSNotification *)notification
{
	//message our delegate that we're done
	//or maybe dont
	
	//autorelease the controller as we are not keeping any reference to it in the app's main window
	//	[self autorelease];
	//yeah we're managing that in our app controller as this is a sheet
	//the autorelease behaviour is wanted in application windows (like the main window) but not in managed sheet windows
	
	//let's get rid off the bindings
	[bundleNameTextField unbind: @"stringValue"];
	[archivePasswordTextField unbind: @"stringValue"];
}

#pragma mark -
#pragma mark button handler
- (IBAction) addButton: (id) sender
{
	QNDownloadBundleManager *bundleManager = [QNDownloadBundleManager sharedManager];
	
	for (NSArray *bundleArray in [self links])
	{
		NSArray *_links = [NSArray arrayWithArray: bundleArray];
		NSString *title = [[[_links objectAtIndex: 0] pathBaseFilename] lowercaseString];
		
		//check if bundle exists and ask user what to do
		QNDownloadBundle *testBundle = [bundleManager downloadBundleForTitle: title];
	
		if (testBundle)
		{
			NSAlert *al = [NSAlert alertWithMessageText: @"Bundle exists already" 
										  defaultButton:@"Add To Existing Bundle" 
										alternateButton: @"Cancel" 
											otherButton: nil 
							  informativeTextWithFormat: [NSString stringWithFormat: @"A bundle with the name %@ exists already. Would you like to add the links to the existing bundle?",title]];
			NSInteger response = [al runModal];
			
			if (response == NSAlertAlternateReturn) //let's cancel the operation
				return;
		}

	}
	
	[self setBundleTitle: [[bundleNameTextField stringValue] lowercaseString]];
	if ([[archivePasswordTextField stringValue] length] > 0)
		[self setBundleArchivePassword: [archivePasswordTextField stringValue]];
	else 
		[self setBundleArchivePassword: nil];

	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kCreateDownloadBundleSheetReturnCodeContinue];
}

- (IBAction) cancelButton: (id) sender
{
	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kCreateDownloadBundleSheetReturnCodeAbort];
}


#pragma mark -
#pragma mark table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSArray *totalArry = [[[NSArray alloc] init] autorelease];
	for (NSArray *subarry in links)
		totalArry = [totalArry arrayByAddingObjectsFromArray: subarry];
	
	return [totalArry count];
//	return [[links objectAtIndex: 0] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSArray *totalArry = [[[NSArray alloc] init] autorelease];
	for (NSArray *subarry in links)
		totalArry = [totalArry arrayByAddingObjectsFromArray: subarry];
	
	if ([[aTableColumn identifier] isEqualToString:@"url"])
		return [totalArry objectAtIndex: rowIndex];
	
/*	if ([[aTableColumn identifier] isEqualToString:@"url"])
		return [[links objectAtIndex: 0] objectAtIndex: rowIndex];*/
	
	if ([[aTableColumn identifier] isEqualToString:@"bundle"])
		return [[totalArry objectAtIndex: rowIndex] pathBaseFilename];
	
	return @"WTF?";
}

@end
