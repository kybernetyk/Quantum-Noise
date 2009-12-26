//
//  NSString+Search.h
//  DummyDownload
//
//  Created by jrk on 24/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (SearchingAdditions)

- (BOOL) containsString:(NSString *)aString;
- (BOOL) containsString:(NSString *)aString ignoringCase:(BOOL)flag;

- (NSString *) md5;
- (NSString *) pathBaseFilename; //base filename for warez links

- (NSString *) pathBaseHashValue; // [[self pathBaseFilename] md5]

@end
