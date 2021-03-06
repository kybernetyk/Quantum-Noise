//
//  QNDownloadOperation+Factory.m
//  DummyDownload
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadOperation+Factory.h"
#import "NSString+Additions.h"
#import "QNDownloadOperation.h"
#import "QNRapidshareComDownloadOperation.h"
#import "QNHotfileDownloadOperation.h"

#pragma mark Factory
@implementation QNDownloadOperation (Factory)

/*
 will check for which hoster we want to download from
 and will return the right download operation instance
 
 if no known hoster is found a poor people's http download will be assumed
 and as the web is a fucking pile of communist crap the
 base class QNDownloadOperation will be returned
 
*/
+ (id) downloadOperationForURI: (NSString *) aURI
{
	NSURL *urlToCheck = [NSURL URLWithString: aURI];
	NSString *hostString = [urlToCheck host];
	
	//todo:
	//read in a plist
	//and look for the apropriate class
	//but for now we're hoff coding it!
	
	NSLog(@"which hoster for %@?",aURI);
	NSLog(@"host string: %@",[hostString lowercaseString]);
	
	id ret = nil;
	
	//uh oh rape it shaer!
	if ([[hostString lowercaseString] containsString: @"rapidshare.com" ignoringCase: YES])
	{	
		ret = [[[QNRapidshareComDownloadOperation alloc] initWithURI: aURI] autorelease];
	}
	else if ([[hostString lowercaseString] containsString: @"hotfile.com" ignoringCase: YES])
    {    
        ret = [[[QNHotfileDownloadOperation alloc] initWithURI: aURI] autorelease];
    }
    else
	{	//fall back to default handler
		ret = [[[QNDownloadOperation alloc] initWithURI: aURI] autorelease];
	}
		
	NSLog(@"using %@ for %@ (host %@)",[ret class], aURI, hostString);
	
	return ret;
}


@end

