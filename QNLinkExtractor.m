//
//  QNLinkExtractor.m
//  linkextractor
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNLinkExtractor.h"
#import "NSString+Search.h"
#import "RegexKitLite.h"

@implementation QNLinkExtractor
+ (NSArray *) urlsFromWebsite: (NSString *) siteURI
{
	NSString *strSite = [NSString stringWithContentsOfURL: [NSURL URLWithString: siteURI]];
	if (!strSite)
		return nil;
	//strSite = [strSite stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	
	NSArray *urls = [strSite componentsMatchedByRegex: @"https?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\-\\.]*(\\?\\S+)?)?)?"];
//	NSArray *urls = [theString componentsMatchedByRegex: @"((https?|ftp|gopher|telnet|file|notes|ms-help):((//)|(\\\\))+[\\w\\d:#@%/;$()~_?\\+-=\\\\.&]*)"];

	NSLog(@"%@",urls);
	return urls;
	
	
}

+ (NSArray *) linksExtractedFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain
{
	NSArray *urls = [self urlsFromWebsite: siteURI];
	
	NSMutableSet *tempSet = [NSMutableSet set];
	
	for (NSString *url in urls)
	{
		if ([url containsString: shouldContain ignoringCase: YES])
			[tempSet addObject: url]; 
	}
	
	return [tempSet allObjects];

}

+ (NSArray *) sortedLinksFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain
{
	NSArray *links = [self linksExtractedFromWebsite: siteURI linkShouldContainString: shouldContain];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	//let's sort our links by their OMEGA values
	//and return an array of arrays. each array is a bundle
	for (NSString *link in links)
	{
		//NSLog(@"Ω of %@ = %i",link, [link omegaValue]);
		//NSInteger omega = [link omegaValue];
		
		NSString *hashValue = [link pathBaseHashValue];
//		NSLog(@"phi of %@: %@",link, phi);
		
		NSMutableArray *omegaArray = [dict objectForKey: hashValue/*[NSNumber numberWithInteger: omega]*/];
		if (!omegaArray)
		{
			omegaArray = [NSMutableArray arrayWithObject: link];
			[dict setObject: omegaArray forKey: hashValue /*[NSNumber numberWithInteger: omega]*/];
		}
		else 
		{
			[omegaArray addObject: link];
		}
	}

	NSMutableArray *ret = [NSMutableArray array];
	
	int i = 0;
	for (NSNumber *key in dict)
	{
		NSLog(@"%i array: %@",i++, [dict objectForKey: key]);
		[ret addObject: [dict objectForKey: key]];
	}
	
	return [NSArray arrayWithArray: ret];
	
}


/*+ (NSArray *) linksExtractedFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain
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
*/
@end
