//
//  QNAddDownloadLinksWindowController.m
//  DummyDownload
//
//  Created by jrk on 15/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNAddDownloadLinksWindowController.h"
#import "NSString+Additions.h"
#import "QNLinkExtractor.h"

#pragma mark -
#pragma mark private setters
@interface QNAddDownloadLinksWindowController () //yep, no category name for real privat accessors. see: http://theocacao.com/document.page/516
@property (readwrite, copy) NSArray *links;
@property (readwrite, copy) NSString *passwordHint;
@end


#pragma mark -
#pragma mark implementation
@implementation QNAddDownloadLinksWindowController
@synthesize links;
@synthesize passwordHint;
@synthesize parseForLinks;

- (void) dealloc
{
	[links release];
	[passwordHint release];
	
	LOG_LOCATION();
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	//message our delegate that we're done
	//or maybe dont
	
	//autorelease the controller as we are not keeping any reference to it in the app's main window
//	[self autorelease];
	//yeah we're managing that in our app controller as this is a sheet
	//the autorelease behaviour is wanted in application windows (like the main window) but not in managed sheet windows
}

#pragma mark -
#pragma mark button event handlers
- (IBAction) abortButton: (id) sender
{
	[self setLinks: nil];
	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kAddDownloadLinksSheetReturnCodeAbort];
}

- (IBAction) continueButton: (id) sender
{
	NSMutableArray *linkArray = [NSMutableArray array];
	
	if ([self parseForLinks])
	{
		NSString *urlToParse = [linkInputTextField stringValue];

		if ([urlToParse containsString: @"irfree.com" ignoringCase: YES])
			[self setPasswordHint:@"irfree.com"];
		
	/*	[linkArray addObjectsFromArray: 
		 [QNLinkExtractor linksExtractedFromWebsite: urlToParse linkShouldContainString: @"rapidshare.com"]];*/
		
		[linkArray addObjectsFromArray: 
		 [QNLinkExtractor sortedLinksFromWebsite: urlToParse linkShouldContainString: @"rapidshare.com/files/"]];
		
	}
	else
	{
		NSArray *tempArray = [[linkInputTextField stringValue] componentsSeparatedByCharactersInSet:
						  [NSCharacterSet characterSetWithCharactersInString:@" ,\n\r\t"]];
	
		NSMutableArray *contArray = [NSMutableArray array];
	
		for (NSString *link in tempArray)
		{
			if ([link containsString:@"http://"])
				[contArray addObject: link];
		}
		
		[linkArray addObject: contArray];
	}
	
	

	//no need to copy but anyways
	[self setLinks: [NSArray arrayWithArray: linkArray]];
	
	//[[self window] orderOut: sender];
	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kAddDownloadLinksSheetReturnCodeContinue];
	
}



@end
