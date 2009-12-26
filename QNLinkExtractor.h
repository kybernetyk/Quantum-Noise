//
//  QNLinkExtractor.h
//  linkextractor
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QNLinkExtractor : NSObject 
{

}

/*
 extracts html links (a href ... the part in href="<LINK>"), checks if they contain the
 string given in shouldContain and returns them if so 

*/
+ (NSArray *) urlsFromWebsite: (NSString *) siteURI;
+ (NSArray *) linksExtractedFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain;
+ (NSArray *) sortedLinksFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain;

@end
