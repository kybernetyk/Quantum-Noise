//
//  QNLinkExtractor.h
//  linkextractor
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 a class with class methods to extract http-links from given sources.
 */
@interface QNLinkExtractor : NSObject 
{

}

/*!
 @abstract will parse a given website for http(s) URLs containing a given string.
 @discussion this is the method you want to call from outside. anything other is low level
 @return returns an "array of array". each sub array contains links for a bundle
 */
+ (NSArray *) sortedLinksFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain;



+ (NSArray *) urlsFromWebsite: (NSString *) siteURI;
+ (NSArray *) linksExtractedFromWebsite: (NSString *) siteURI linkShouldContainString: (NSString *) shouldContain;

@end
