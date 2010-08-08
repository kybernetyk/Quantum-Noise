//
//  QNLinkExtractor.m
//  linkextractor
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNLinkExtractor.h"
#import "NSString+Additions.h"
#import "RegexKitLite.h"

@implementation QNLinkExtractor
+ (NSArray *) urlsFromWebsite: (NSString *) siteURI
{
	NSString *strSite = [NSString stringWithContentsOfURL: [NSURL URLWithString: siteURI]];
	if (!strSite)
		return nil;
	
	NSArray *urls = [strSite componentsMatchedByRegex: @"https?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\-\\.]*(\\?\\S+)?)?)?"];

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
		{	
			NSLog(@"adding: %@", url);
			[tempSet addObject: url]; 
			
		}
	}
	
	return [tempSet allObjects];

}


+ (NSArray *) sortedLinksFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain
{
	NSArray *links = [self linksExtractedFromWebsite: siteURI linkShouldContainString: shouldContain];

	/*
	 we got a list of N links. chances are that these links do not belong all to the same bundle.
	 so we take the base name of each link's file (basename: rs.com/nnnn/a.release.name.partN.rar -> a.release.name)
	 compute the md5 of this base name and group the links by this md5 value.
	 
	 */

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	for (NSString *link in links)
	{
		NSLog(@"path base: %@",[link pathBaseFilename]);
		NSString *hashValue = [link pathBaseHashValue];
		
		NSMutableArray *omegaArray = [dict objectForKey: hashValue];
		if (!omegaArray)
		{
			omegaArray = [NSMutableArray arrayWithObject: link];
			[dict setObject: omegaArray forKey: hashValue];
		}
		else 
		{
			[omegaArray addObject: link];
		}
	}


	/*
	 now we will create an array of arrays from our dict dictionary and return it.
	 
	 we also sort the links alphabetically within each bundle.
	*/
	NSMutableArray *ret = [NSMutableArray array];
	int i = 0;
	for (NSNumber *key in dict)
	{
		NSArray *arr = [dict objectForKey: key];
		arr = [arr sortedArrayUsingSelector: @selector(localizedCompare:)];
		[ret addObject: arr];
	}
	return [NSArray arrayWithArray: ret];
}


+ (NSArray *) sortedLinksFromString: (NSString *) aString 
{	
	//NSArray *links = [aString componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@" ,\n\r\t"]];
	NSArray *links = [aString componentsMatchedByRegex: @"https?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\-\\.]*(\\?\\S+)?)?)?"];
	
	/*
	 we got a list of N links. chances are that these links do not belong all to the same bundle.
	 so we take the base name of each link's file (basename: rs.com/nnnn/a.release.name.partN.rar -> a.release.name)
	 compute the md5 of this base name and group the links by this md5 value.
	 
	 */
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	for (NSString *link in links)
	{
		NSLog(@"path base: %@",[link pathBaseFilename]);
		NSString *hashValue = [link pathBaseHashValue];
		
		NSMutableArray *omegaArray = [dict objectForKey: hashValue];
		if (!omegaArray)
		{
			omegaArray = [NSMutableArray arrayWithObject: link];
			[dict setObject: omegaArray forKey: hashValue];
		}
		else 
		{
			[omegaArray addObject: link];
		}
	}
	
	
	/*
	 now we will create an array of arrays from our dict dictionary and return it.
	 
	 we also sort the links alphabetically within each bundle.
	 */
	NSMutableArray *ret = [NSMutableArray array];
	int i = 0;
	for (NSNumber *key in dict)
	{
		NSArray *arr = [dict objectForKey: key];
		arr = [arr sortedArrayUsingSelector: @selector(localizedCompare:)];
		[ret addObject: arr];
	}
	return [NSArray arrayWithArray: ret];
}


//old xml parsing. will only work for html sites - not for plain text pages containing links. so we dropped it
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
