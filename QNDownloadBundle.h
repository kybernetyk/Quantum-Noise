//
//  QNDownloadBundle.h
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QNDownloadBundle : NSObject 
{
	NSString *title;
	NSString *archivePassword;
	NSMutableArray *URIs;
	
	BOOL	isExtracting;
	BOOL	hasBeenExtracted;	//has the bundle been handled to the extract0r after completition?
}

@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSString *archivePassword;
@property (readwrite, assign) BOOL hasBeenExtracted;
@property (readwrite, assign) BOOL isExtracting;

@property (readonly) NSArray *URIs;

- (id) initWithTitle: (NSString *) aTitle;
- (id) initWithTitle: (NSString *) aTitle andURIs: (NSArray *) someURIs;

- (id) initWithTitle: (NSString *) aTitle andArchivePassword: (NSString *) aPassword;
- (id) initWithTitle: (NSString *) aTitle ArchivePassword: (NSString *) aPassword andURIs: (NSArray *) someURIs;

- (void) addURI: (NSString *) uri;

- (BOOL) containsURI: (NSString *) URI;

//not implemented yet
//waiting for download manager singleton!
- (float) downloadProgress;

//dictionary representation for saving
- (NSDictionary *) dictionaryRepresentation;

@end
