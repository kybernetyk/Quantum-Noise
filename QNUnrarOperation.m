//
//  QNUnrarOperation.m
//  DummyDownload
//
//  Created by jrk on 23/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNUnrarOperation.h"


@implementation QNUnrarOperation
@synthesize rarfile;
@synthesize progress;
@synthesize delegate;
@synthesize returnCode;

- (id) initWithFilename: (NSString *) rarFileToUnrar andPassword: (NSString *) rarPassword
{
	self = [super init];
	
	rarfile = [[NSString stringWithString: rarFileToUnrar] retain];

	if (rarPassword)
		password = [[NSString stringWithString: rarPassword] retain];
	return self;
}

- (void) dealloc
{
	[rarfile release];
	[password release];
	
	[super dealloc];
}


//hier wird unser unrar stdout geprintet
//man koennte ihn auch mal parsen unso
//weil da kommt ab und zu wrong password, wenn mans falsch eingeben tut
- (void)printTaskOutput:(NSNotification *)aNotification
{
	NSString *outputString;
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if (data && [data length])
	{
		outputString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

		//unrar's output seperated by a whitespace
		NSArray *arr = [outputString componentsSeparatedByString:@" "];

		//predicate to see if the string contains a '%'
		NSPredicate *apred = [NSPredicate predicateWithFormat: @"'%' IN SELF"];
		
		//check if the string is part of unrar's progress
		//and convert that to a NSInteger
		for (NSString *part in arr)
		{
			BOOL bPartContainsAPercentSign = [apred evaluateWithObject: part];
			if (bPartContainsAPercentSign)
			{
				//we get sometimes 2 updates for one progress by unrar (ie 2x 5% ...)
				//don't send that to our delegate
				if ([self progress] != [part intValue])
				{	
					[self setProgress: [part intValue]];

					[delegate performSelectorOnMainThread: @selector(unrarOperationProgressDidChange:)
											   withObject: self 
											waitUntilDone: NO];
					

					break;
				}
			}
		}
		
		NSLog(@"%@",outputString);
		//NSLog(@"%i",[outputString intValue]);
		[outputString release];

		[[aNotification object] readInBackgroundAndNotify];
	}
}

- (void) main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[delegate performSelectorOnMainThread: @selector(unrarOperationDidStart:)
							   withObject: self 
							waitUntilDone: NO];
	
	
	if (![self isCancelled])
	{
//		nice 20 *unrar gedoens*
		NSPipe *taskPipe = [NSPipe pipe];
		if (!taskPipe)
		{
			[self setReturnCode: -666];
		}
		NSTask *aTask = [[NSTask alloc] init];
		
		[aTask setStandardOutput:taskPipe];
		[aTask setStandardError:taskPipe];
		
		NSMutableArray *arguments = [NSMutableArray array];

		//20 (von nice)
		[arguments addObject: @"-n 20"];
		
		NSString *unrarpath = [[NSBundle mainBundle] pathForResource: @"unrar" ofType: nil];
		
		//unrar binary path
		[arguments addObject: unrarpath];
		
		//x extract command
		[arguments addObject: @"x"];
		
		//overwrite existing files
		[arguments addObject: @"-o+"];
		
		//do not query password
		[arguments addObject: @"-p-"];
		
		//append password if there's one
		if (password)
		{
			[arguments addObject: [NSString stringWithFormat: @"-p%@",password]];
		}

		
		//our rarfile argument
		[arguments addObject: rarfile];
		
		//output directory
		NSMutableArray *dirArray = [NSMutableArray arrayWithArray: [rarfile pathComponents]];
		[dirArray removeLastObject];
		NSString *outputDir = [dirArray componentsJoinedByString: @"/"]; //tut ein / vors erste element. teh suck :( 
		//NSLog(@"output dir = %@",outputDir);
		[arguments addObject: outputDir];
		
		
		[aTask setArguments: arguments];
		[aTask setLaunchPath:@"/usr/bin/nice"];
		
		
		NSLog(@"extracting %@ with password %@ to path %@",rarfile, password, outputDir);
		
		[[taskPipe fileHandleForReading] readInBackgroundAndNotify];
		
		[[NSNotificationCenter defaultCenter] addObserver: self 
												 selector: @selector(printTaskOutput:) 
													 name: NSFileHandleReadCompletionNotification 
												   object:[[aTask standardOutput] fileHandleForReading]];
		
		
		[aTask launch];
		[aTask waitUntilExit];
		int status = [aTask terminationStatus];
		[self setReturnCode: status];
		
		if (status != 0)
			[self setProgress: -1.0];
		else 
		{
			[self setProgress: 100];
			[delegate performSelectorOnMainThread: @selector(unrarOperationProgressDidChange:)
									   withObject: self 
									waitUntilDone: NO];
		}


		[[NSNotificationCenter defaultCenter] removeObserver: self 
														name: NSFileHandleReadCompletionNotification 
													  object: [[aTask standardOutput] fileHandleForReading]];
	
		[aTask release];
	}
	[delegate performSelectorOnMainThread: @selector(unrarOperationDidEnd:)
							   withObject: self 
							waitUntilDone: NO];
	
	
	[pool release];
}

@end
