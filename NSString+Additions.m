//
//  NSString+Search.m
//  DummyDownload
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "NSString+Additions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (SearchingAdditions)

- (BOOL)containsString:(NSString *)aString 
{
    return [self containsString:aString ignoringCase:NO];
}

- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag 
{
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    return [self rangeOfString:aString options:mask].length > 0;
}

- (NSString *) pathBaseFilename //base filename for warez links
{
	//NSArray *comps = [self pathComponents];
	
//	NSLog(@"%@",comps);
//	NSLog(@"last item: %@",[comps lastObject]);
//	NSLog(@"path ext: %@",[self pathExtension]);
	
	NSRange range;
	range.location = 0;
	range.length = [[self lastPathComponent] length];
	
	NSString *title = [[self lastPathComponent] stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".%@",[self pathExtension]]
																		  withString:@""
																			 options: NSCaseInsensitiveSearch
																			   range: range
					   ];
	//omg that's so lame
	//we need REGEXP MAN!
	for (int i = 9; i >= 0; i--)
	{
		range.length = [title length];
		title = [title stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".part0%i", i]
												 withString: @""
													options: NSCaseInsensitiveSearch
													  range: range
				 
				 ];
	}
	
	for (int i = 255; i >= 0; i--)
	{
		range.length = [title length];
		title = [title stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@".part%i", i]
												 withString: @""
													options: NSCaseInsensitiveSearch
													  range: range
				 
				 ];
		
	//	NSLog(@"%@",title);
	}
	
	return title;
}

- (NSString *) md5
{
	const char *cStr = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5( cStr, strlen(cStr), result );
	
	return [NSString 
			stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1],
			result[2], result[3],
			result[4], result[5],
			result[6], result[7],
			result[8], result[9],
			result[10], result[11],
			result[12], result[13],
			result[14], result[15]
			];
	
}


- (NSString *) pathBaseHashValue
{
	return [[self pathBaseFilename] md5];
}

/*- (NSInteger) omegaValue
{
	if ([self lengthOfBytesUsingEncoding: NSUTF8StringEncoding] <= 0)
		return 0;
	
	const char *cstr = [[self zetaFactor] cStringUsingEncoding: NSUTF8StringEncoding];
	
	//NSLog(@"%@",[[self pathComponents] lastObject]);
	
	NSInteger sum = 0;
	int i = 0;
	for (i = 0; i < [[self zetaFactor] lengthOfBytesUsingEncoding: NSUTF8StringEncoding]; i++)
	{
		sum += cstr[i];
	}
	
	return sum;
	
}*/

@end