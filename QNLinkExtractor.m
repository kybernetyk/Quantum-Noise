//
//  QNLinkExtractor.m
//  linkextractor
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNLinkExtractor.h"


@implementation QNLinkExtractor

+ (NSArray *) linksExtractedFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain
{
	NSError *error;	
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL: [NSURL URLWithString: siteURI] 
																   options: NSXMLDocumentTidyHTML 
																	 error: &error];
	[document autorelease];
	
	NSMutableArray *resultArray = [NSMutableArray array];
	
	if (document) 
	{
		NSArray *result = [document objectsForXQuery:@"for $a in //a return $a" constants:nil error:&error];
		if (result)
		{
			for (NSXMLElement *element in result)
			{
				NSString *s = [[element attributeForName: @"href"] stringValue];
				
				if (s)
					[resultArray addObject: [NSString stringWithString: s]];
			}
		}
		else 
		{
			return nil;
		}

	}
	else 
	{
		return nil;
	}
	NSPredicate *pred = [NSPredicate predicateWithFormat: @"%@ IN SELF", shouldContain];
	NSArray *links = [resultArray filteredArrayUsingPredicate: pred];
	return [NSArray arrayWithArray: links];
}

@end
