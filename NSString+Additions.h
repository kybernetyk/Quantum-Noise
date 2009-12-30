/*!
 @header NSString+Additions
 @author	Jaroslaw Szpilewski
 @copyright Jaroslaw Szpilewski
 @abstract Contains additions to NSString
 */



//
//  NSString+Additions.h
//  DummyDownload
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 NSString category for search operations
 */
@interface NSString (SearchingAdditions)

/*!
 returns if the string contains the substring aString.
 
 this is case sensitive!
 */
- (BOOL) containsString:(NSString *)aString;

/*!
 returns if the string contains the substring aString.
 
 you can chose to ignore case by setting the ignoringCase flag to YES
 */
- (BOOL) containsString:(NSString *)aString ignoringCase:(BOOL)flag;
@end

/*!
 category that adds hashing methods to NSString
 */
@interface NSString (HashingAdditions)

/*!
 md5 hash value for the string
 */
- (NSString *) md5;

/*!
 baseFilename for the string. (fop.bar.part1.rar return foo.bar)
 @discussion this is used for files that belong to the same bundle
 */
- (NSString *) pathBaseFilename; //base filename for warez links

/*!
 returns the md5 hash value of [self pathBaseFilename]
 */
- (NSString *) pathBaseHashValue; // [[self pathBaseFilename] md5]
@end
