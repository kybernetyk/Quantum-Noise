//
//  QNAddDownloadLinksWindowController.m
//  DummyDownload
//
//  Created by jrk on 15/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNAddDownloadLinksWindowController.h"
#import "NSString+Search.h"

#pragma mark -
#pragma mark private setters
@interface QNAddDownloadLinksWindowController () //jap, () muss so sein ... is halt n hack >.< von http://theocacao.com/document.page/516
@property (readwrite, copy) NSArray *links;
@property (readwrite, copy) NSString *passwordHint;
@end


#pragma mark -
#pragma mark implementation
@implementation QNAddDownloadLinksWindowController
@synthesize links;
@synthesize passwordHint;

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
	NSArray *tempArray = [[linkInputTextField stringValue] componentsSeparatedByCharactersInSet:
						  [NSCharacterSet characterSetWithCharactersInString:@" ,\n\r\t"]];
	
	NSMutableArray *linkArray = [NSMutableArray array];
	for (NSString *link in tempArray)
	{
		if ([link containsString:@"http://"])
			[linkArray addObject: link];
	}
	
	[self setPasswordHint:@"irfree.com"];

	//no need to copy but anyways
	[self setLinks: [NSArray arrayWithArray: linkArray]];
	
	//[[self window] orderOut: sender];
	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kAddDownloadLinksSheetReturnCodeContinue];
	
}



@end
