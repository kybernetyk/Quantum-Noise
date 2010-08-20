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
		
		//TODO: make this cool and pretty. not lame like nao
		//like iterate the hosters and get a match pattern from the userdefaults
		//but who cares lol
		BOOL isRSactive = NO;
		BOOL isHFactive = NO;
		
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];

		if (([[def objectForKey: @"rapidShareCom_username"] length] > 0) && ([[def objectForKey: @"rapidShareCom_password"] length] > 0))
			isRSactive = YES;
		if (([[def objectForKey: @"hotfileCom_username"] length] > 0) && ([[def objectForKey: @"hotfileCom_password"] length] > 0))
			isHFactive = YES;
		
		if (isRSactive)
			[linkArray addObjectsFromArray: [QNLinkExtractor sortedLinksFromWebsite: urlToParse linkShouldContainString: @"rapidshare.com/files/"]];

		if (isHFactive)
			[linkArray addObjectsFromArray: [QNLinkExtractor sortedLinksFromWebsite: urlToParse linkShouldContainString: @"hotfile.com/dl/"]];
		
		
	}
	else
	{
		[linkArray addObjectsFromArray:
		 [QNLinkExtractor sortedLinksFromString: [linkInputTextField stringValue]]];
		
/*		NSArray *tempArray = [[linkInputTextField stringValue] componentsSeparatedByCharactersInSet:
						  [NSCharacterSet characterSetWithCharactersInString:@" ,\n\r\t"]];
	
		NSMutableArray *contArray = [NSMutableArray array];
	
		for (NSString *link in tempArray)
		{
			if ([link containsString:@"http://"])
				[contArray addObject: link];
		}*/
		
		//[linkArray addObject: contArray];
	}
	
	//lets make the filenames uniqe
	//TODO: create somehow unique temporary filenames/endfilenames for the files
	//		but the server will send us a filename that will overwrite the unique name
	//		so we make the filenames unique :[
	
	NSLog(@"link array: %@",linkArray);

	NSMutableArray *endArray = [NSMutableArray array];
	//we get an array of arrays from the extractor. each array represents one bundle
	//we will go through each bundle and throw out links that point to the same filename
	for (NSArray *bundleArray in linkArray)
	{
		NSMutableArray *temp = [NSMutableArray array];
		NSMutableDictionary *uniquenessBaby = [NSMutableDictionary dictionaryWithCapacity: 32];
		for (NSString *link in bundleArray)
		{
			NSLog(@"beficke: %@",link);
			NSString *filename = [link pathBaseFilename];

			if ([[uniquenessBaby objectForKey: filename] boolValue])
				continue;
			[temp addObject: [NSString stringWithString: link]];
			[uniquenessBaby setObject: [NSNumber numberWithBool: YES] forKey: filename];
			
		}
		[endArray addObject: temp];
	}
	
	//no need to copy but anyways
	[self setLinks: [NSArray arrayWithArray: endArray]];
	
	//[[self window] orderOut: sender];
	[[self window] close];
	[NSApp endSheet: [self window] returnCode: kAddDownloadLinksSheetReturnCodeContinue];
	
}



@end
