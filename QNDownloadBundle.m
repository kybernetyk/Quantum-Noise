//
//  QNDownloadBundle.m
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadBundle.h"
#import "QNDownloadManager.h"

@implementation QNDownloadBundle
#pragma mark -
#pragma mark properties
@synthesize title;
@synthesize archivePassword;
@synthesize URIs;
@synthesize hasBeenExtracted;
@synthesize isExtracting;

#pragma mark -
#pragma mark initializer
- (id) initWithTitle: (NSString *) aTitle
{
	self = [super init];
	[self setTitle: aTitle];
	URIs = [[NSMutableArray alloc] init];
	
	return self;
}

- (id) initWithTitle: (NSString *) aTitle andURIs: (NSArray *) someURIs
{
	self = [self initWithTitle: aTitle];
	for (NSString *uri in someURIs)
		[self addURI: uri];
	
	return self;
}

- (id) initWithTitle: (NSString *) aTitle andArchivePassword: (NSString *) aPassword
{
	self = [self initWithTitle: aTitle];
	[self setArchivePassword: aPassword];
	
	return self;
}

- (id) initWithTitle: (NSString *) aTitle ArchivePassword: (NSString *) aPassword andURIs: (NSArray *) someURIs
{
	self = [self initWithTitle: aTitle andURIs: someURIs];

	//if password ie empty let's nil it
	if ([aPassword isEqual:@""])
		[self setArchivePassword: nil];
	else
		[self setArchivePassword: aPassword];
	
	return self;
}

#pragma mark -
#pragma mark dealloc
- (void) dealloc
{
	[URIs release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"<QNDownloadBundle 0x%x>\n\ttitle = %@;\n\tpassword = %@;\n\tURIs = %@",
			self, 
			[self title],
			[self archivePassword],
			[self URIs]
			];
}

#pragma mark -
#pragma mark implementation
- (void) addURI: (NSString *) uri
{
	[URIs addObject: [NSString stringWithString: uri]];
}

- (BOOL) containsURI: (NSString *) URI
{
	NSPredicate *pre = [NSPredicate predicateWithFormat: @"SELF IN $URI_LIST"];
	NSPredicate *pre2 = [pre predicateWithSubstitutionVariables:  [NSDictionary dictionaryWithObject:URIs forKey:@"URI_LIST"]];

	return [pre2 evaluateWithObject: URI];
}

- (float) downloadProgress
{
	return [[QNDownloadManager sharedManager] downloadProgressForDownloadBundle: self];
}

- (NSDictionary *) dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (title)
		[dict setObject: [NSString stringWithString: title] forKey:@"Title"];
	if (archivePassword)
		[dict setObject: [NSString stringWithString: archivePassword] forKey:@"Password"];
	if (URIs)
		[dict setObject: URIs forKey: @"URIs"];
	
	[dict setObject: [NSNumber numberWithBool: hasBeenExtracted] forKey: @"hasBeenExtracted"];
	
	return [NSDictionary dictionaryWithDictionary: dict];
	
}

@end
