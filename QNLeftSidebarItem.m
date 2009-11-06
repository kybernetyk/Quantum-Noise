//
//  SidebarItemObjectProxy.m
//  QuantumNoise
//
//  Created by jrk on 09.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNLeftSidebarItem.h"

@implementation QNLeftSidebarItem
@synthesize userData;
@synthesize title;
@synthesize type;
@synthesize childItems;
@synthesize isExpanded;
@synthesize parentItem;

- (id) initWithTitle: (NSString *) aTitle Type: (NSString *) aType andUserDataOrNil: (id) objectOrNil
{
	self = [super init];
	[self setTitle: aTitle];
	[self setType: aType];
	[self setUserData: objectOrNil];
	[self setParentItem: nil];
	return self;
}

+ (id) leftSidebarItemWithTitle: (NSString *) aTitle andType: (NSString *) aType
{
	return [[[self alloc] initWithTitle: aTitle Type: aType andUserDataOrNil: nil] autorelease];
}

+ (id) initWithTitle: (NSString *) aTitle Type: (NSString *) aType andUserDataOrNil: (id) objectOrNil
{
	return [[[self alloc] initWithTitle: aTitle Type: aType andUserDataOrNil: objectOrNil] autorelease];
}


- (void) dealloc
{
//	NSLog(@"QNLeftSidebarItem dealloc");
	//[representedDictionary release];
	//representedDictionary = nil;
	
	[userData release];
	userData = nil;
	
	[childItems release];
	childItems = nil;
	
	[title release];
	title = nil;
	
	[type release];
	type = nil;
	
	[parentItem release];
	parentItem = nil;
	
	[super dealloc];
}


- (void) addChildItem: (QNLeftSidebarItem *) item
{
	if (!childItems)
		childItems = [[NSMutableArray alloc] init];
	
	[childItems addObject: item];
	[item setParentItem: self];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"<0x%x %@> type: '%@' title: '%@' userdata: '%@' expanded: %i",self,[self class],[self type],[self title],[self userData],[self isExpanded]];
}

@end
