//
//  QNDownloadManager.m
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadManager.h"
#import "QNDownloadManager+Private.h"
#import "QNDownloadOperation.h"
#import "QNRapidshareComDownloadOperation.h"
#import "QNDownloadOperation+Factory.h"
#import "DDInvocationGrabber.h"
#import "NSObject+DDExtensions.h"



@implementation QNDownloadManager
@synthesize maxConcurrentDownloads;
@synthesize delegate;
@synthesize downloadQueue;
@synthesize overallDownloadSpeed;
@synthesize overallDownloadProgress;
@synthesize maxDownloadSpeed;
@synthesize selectedDownloads;
@synthesize isPaused;
@synthesize isRunning;

#pragma mark -
#pragma mark singleton
//singleton allocation using GCD
+ (id) sharedManager
{
	static dispatch_once_t pred;
	static QNDownloadManager *sharedManager = nil;
	
	dispatch_once(&pred, ^{ sharedManager = [[self alloc] init]; });
	return sharedManager;
}

#pragma mark -
#pragma mark init/dealloc
- (id) init
{
	self = [super init];
	downloadQueue = [[NSMutableArray alloc] init];
	operationQueue = [[NSOperationQueue alloc] init];

	isRunning = NO;
	isPaused = NO;
	
	//queue must halt!
	//[operationQueue setMaxConcurrentOperationCount: 2];
	[operationQueue setSuspended: YES];
	
	//must be after opQueue creation!!!!
	[self setMaxConcurrentDownloads: 2];
	
	[self loadState];
	
	//select all
	[self selectAllDownloads];
	
	NSLog(@"operations in queue: %@",[operationQueue operations]);
	
	return self;
}

- (void) dealloc
{
	NSLog(@"warning: dealloc of singleton!");
	LOG_LOCATION();
	exit(99);
	
	[downloadQueue release];
	[operationQueue release];
	[super dealloc];
}

#pragma mark -
#pragma mark selection managment
/*
	you can select all or a subset of the manager's download operations
	and access this selection through the 'selectedDownloads'
	property.
 
	you can query the download manager for statistics like downloadprogress of a selection
 
	selections are the hoff
*/

- (void) reloadSelection //reloads the current selectios
{
	LOG_LOCATION();
	NSLog(@"%i!",currentSelectionType);
	
	if (currentSelectionType == kQNDownloadManagerSelectionTypeAllDownloads)
		[self selectAllDownloads];

	if (currentSelectionType == kQNDownloadManagerSelectionTypeBundle)
		[self selectDownloadsInBundle: selectedBundle];
	
	
	if (currentSelectionType == kQNDownloadManagerSelectionTypeFinished)
		[self selectFinishedDownloads];
	if (currentSelectionType == kQNDownloadManagerSelectionTypeUnfinished)
		[self selectUnfinishedDownloads];


}

/*
	sets the downloadquque as the selected downloads
	selects all downloads registered with the manager
*/
- (void) selectAllDownloads
{
	[self setSelectedDownloads: downloadQueue];

	currentSelectionType = kQNDownloadManagerSelectionTypeAllDownloads;
	
	//message delegate of selection change!
}

/*
	selects all downloads which belong to the given bundle
 
*/
- (void) selectDownloadsInBundle: (QNDownloadBundle *) bundle
{
	NSArray *sel = [self downloadOperationsForDownloadBundle: bundle];
	[self setSelectedDownloads: sel];

	currentSelectionType = kQNDownloadManagerSelectionTypeBundle;

	[selectedBundle release];
	selectedBundle = [bundle retain];
	
	//message delegate of selection change!
}


- (void) selectFinishedDownloads
{
	NSMutableArray *tempArray = [NSMutableArray array];
	
	for (QNDownloadOperation *operation in downloadQueue)
	{
		if ([operation progress] >= 1.0)
		{
			[tempArray addObject: operation];
		}
	}

	
	currentSelectionType = kQNDownloadManagerSelectionTypeFinished;
	[self setSelectedDownloads: tempArray];
}

- (void) selectUnfinishedDownloads
{
	NSMutableArray *tempArray = [NSMutableArray array];
	
	for (QNDownloadOperation *operation in downloadQueue)
	{
		if ([operation progress] < 1.0)
		{
			[tempArray addObject: operation];
		}
	}
	
	currentSelectionType = kQNDownloadManagerSelectionTypeUnfinished;
	[self setSelectedDownloads: tempArray];
}


//impelement reload selection method
//for quick reloading of the current selection


#pragma mark -
#pragma mark queue managment
/*
 enqueues an URI to the download queue
 
 creates a QNDownloadOperation from the given URI.
 this download operation will be eventuelly executed by the manager's
 operationqueue.
 */
- (void) enqueueURI: (NSString *) downloadURI
{
	for (QNDownloadOperation *operation in downloadQueue)
	{
		if ([downloadURI isEqualToString: [operation URI]])
		{
			NSLog(@"warning! the URI %@ is in the download list already!", downloadURI);
			LOG_LOCATION();
			return;
		}
			
	}
	QNDownloadOperation *downloadOperation = [QNDownloadOperation downloadOperationForURI: downloadURI];
	[downloadOperation setDelegate: self];

	[downloadQueue addObject: downloadOperation];
	
	if (![downloadOperation hasBeenExecuted])
	{	
		[operationQueue addOperation: downloadOperation];
	}
	
	if (isPaused)
		[downloadOperation setIsPaused: YES];	
	
		
	
	[self saveState];
	[self reloadSelection];
}

/* takes an array of URIs and passes each to enqueueURI: */
- (void) enqueueURIs: (NSArray *) arrayWithURIs
{
	for (NSString *url in arrayWithURIs)
		[self enqueueURI: url];
}
/* takes the URIs from a bundle and passes it to enqueueURIs: */
- (void) enqueueDownloadBundle: (QNDownloadBundle *) downloadBundle
{
	[self enqueueURIs: [downloadBundle URIs]];
}

- (void) removeDownloadOperation: (QNDownloadOperation *) operationToRemove
{
	@synchronized (downloadQueue)
	{
		NSArray *dQueue = [NSArray arrayWithArray: downloadQueue];
	
		for (QNDownloadOperation *op in dQueue)
		{
			if ([[op URI] isEqualToString: [operationToRemove URI]])
			{
			/*check to see if the operation is in the current selection 
			  if so set it to all selection . (or update it if all downloads were selected)
			 
			  otherwise the outside user of the manager could get out of sync data.
			 */

				[op cancel];
				[downloadQueue removeObject: op];

				if ([selectedDownloads containsObject: operationToRemove])
				{
					[self selectAllDownloads];
				}
			
			}
		}
	}
	[self saveState];
	[self reloadSelection];
}

#pragma mark -
#pragma mark public control
- (void) startDownloading
{
	[operationQueue setSuspended: NO];
	isRunning = YES;
}

- (void) pauseDownloading
{
	for (QNDownloadOperation *op in downloadQueue)
	{
		//if ([op isExecuting])
		[op setIsPaused: YES];
	}
	isPaused = YES;
}

- (void) resumeDownloading
{
	for (QNDownloadOperation *op in downloadQueue)
	{
		[op setIsPaused: NO];
	}
	isPaused = NO;
}

- (void) stopDownloading
{
	//[operationQueue setMaxConcurrentOperationCount: 0];
	//[operationQueue setSuspended: YES];
	[operationQueue cancelAllOperations];
	isRunning = NO;
}

#pragma mark -
#pragma mark Properties
/*
	sets the number of maximal concurrent NSOperations the
	NSOperationQueue will run at a time.
 
*/
- (void) setMaxConcurrentDownloads:(NSUInteger) newMax
{
	if (!operationQueue)
	{
		NSLog(@"No operation Queue!");
		LOG_LOCATION();
		exit(234);
	}
	
	[self willChangeValueForKey: @"maxConcurrentDownloads"];
	maxConcurrentDownloads = newMax;
	[self didChangeValueForKey: @"maxConcurrentDownloads"];
	[operationQueue setMaxConcurrentOperationCount: maxConcurrentDownloads];
	 
}

/*
	returns an array of QNDowloadOperations that are
	executed by the operationqueue at the time of this call.
 
	don't rely on this. this list could have already changed
	when you get the pointer. multithreading is EVIL
 
*/
- (NSArray *) currentlyExecutedDownloadOperations
{
	NSMutableArray *temp = [NSMutableArray array];

	for (QNDownloadOperation *op in [operationQueue operations])
		if ([op isExecuting])
			[temp addObject: op];
	
	return [NSArray arrayWithArray: temp]; 
}

/*
 sets the maximum overall download speed for the manager
 and applys it to all active downloads.
 single downloadlimit = managerlimit / numofcurrentdownloads;
*/
- (void) setMaxDownloadSpeed:(NSInteger) speed
{
	maxDownloadSpeed = speed;
	[self applyDownloadSpeedLimitToActiveDownloads];
}

#pragma mark -
#pragma mark state
/*
 loads the download manager state from a .plist from disk.
 it contains all previously added (and not removed) downloads
 and their invidual state.
*/
- (void) loadState
{
	NSLog(@"download manager loading state. %@",SOURCE_LOCATION);
//	LOG_LOCATION();
	
	//NSArray *loadArray = [NSArray arrayWithContentsOfFile: @"/downloads.plist"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *loadArray = [defaults objectForKey: @"QNDownloadManagerState"]; // [defaults setObject: saveArray forKey: @"QNDownloadManagerState"];

	if (!loadArray)
		return;
	
	for (NSDictionary *downloadDict in loadArray)
	{
		NSString *URI						=		[downloadDict objectForKey: @"URI"];
		NSString *fileName					=		[downloadDict objectForKey: @"fileName"];
		NSString *temporaryDownloadFilename =		[downloadDict objectForKey: @"temporaryDownloadFilename"];
	//	NSString *status					=		[downloadDict objectForKey: @"status"];
		
		double progress						=		[[downloadDict objectForKey: @"progress"] doubleValue];
		double speed						=		[[downloadDict objectForKey: @"speed"] doubleValue];
		double receivedBytes				=		[[downloadDict objectForKey: @"receivedBytes"] doubleValue];
		double fileSize						=		[[downloadDict objectForKey: @"fileSize"] doubleValue];
		
		BOOL hasBeenExecuted				=		[[downloadDict objectForKey: @"hasBeenExecuted"] boolValue];
		
		QNDownloadOperation *downloadOperation = [QNDownloadOperation downloadOperationForURI: URI];
		[downloadOperation setDelegate: self];

		[downloadOperation setURI: URI];
		[downloadOperation setFileName: fileName];
		[downloadOperation setTemporaryDownloadFilename: temporaryDownloadFilename];

		//let us "reset" the packages that were not downloaded comepletly.
		//later let's resume them. now we gonna restart them as the currently saved
		//"resume" information is inaccurate. 
/*		if ([status isEqualToString: @"Downloading"])
		{
			[downloadOperation setStatus: @"Idle"];
			[downloadOperation setProgress: 0.0];
			[downloadOperation setDownloadSpeed: 0.0];
			[downloadOperation setReceivedBytes: 0.0];
			[downloadOperation setDownloadSpeed: 0.0];
		}
		else */
			
		
		
		//operation not finished
		if (progress < 1.0)
		{
			[downloadOperation setStatus: kQNDownloadStatusIdle];
			[downloadOperation setProgress: 0.0];
			[downloadOperation setDownloadSpeed: 0.0];
			[downloadOperation setReceivedBytes: 0.0];
			[downloadOperation setDownloadSpeed: 0.0];
			hasBeenExecuted = NO;
		}
		else 
		{
			[downloadOperation setStatus: kQNDownloadStatusSuccess];
			[downloadOperation setProgress: progress];
			[downloadOperation setDownloadSpeed: speed];
			[downloadOperation setReceivedBytes: receivedBytes];
			
	/*		QNDownloadBundle *bundle = [[QNDownloadBundleManager sharedManager] downloadBundleForURI: URI];
			if (bundle)
			{
				
			}*/
		}



		[downloadOperation setFileSize: fileSize];
		[downloadOperation setHasBeenExecuted: hasBeenExecuted];			
		[downloadQueue addObject: downloadOperation];
		

		if (!hasBeenExecuted)
			[operationQueue addOperation: downloadOperation];
		
	}
}

/* saves the download manager's state to disk.
   will iterate through all managed download operations
   and get their individual state to save it.
*/
- (void) saveState
{
	NSLog(@"download manager saving state. %@",SOURCE_LOCATION);
	//LOG_LOCATION();

	NSMutableArray *saveArray = [NSMutableArray array];
	
	@synchronized (downloadQueue)
	{
		for (QNDownloadOperation *op in downloadQueue)
		{
			NSDictionary *dict = [op dictionaryRepresentation];
			[saveArray addObject: dict];
		}
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: saveArray forKey: @"QNDownloadManagerState"];
}

#pragma mark -
#pragma mark bundle querying
- (NSArray *) downloadOperationsForFilename: (NSString *) filename
{
	NSPredicate *pre = [NSPredicate predicateWithFormat: @"fileName IN $FILE_LIST"];
	NSPredicate *pre2 = [pre predicateWithSubstitutionVariables:  
						 [NSDictionary dictionaryWithObject: [NSArray arrayWithObject: filename] forKey:@"FILE_LIST"]];
	NSArray *foundOps = [downloadQueue filteredArrayUsingPredicate: pre2];
	return foundOps;
	
}

/*
	returns the downloadoperaion-objects which have the given URIs associated
	to them.

 	return value: NSArray of QNDowloadOperation
*/
- (NSArray *) downloadOperationsForURIList: (NSArray *) uris
{
	NSPredicate *pre = [NSPredicate predicateWithFormat: @"URI IN $URI_LIST"];
	NSPredicate *pre2 = [pre predicateWithSubstitutionVariables:  [NSDictionary dictionaryWithObject:uris forKey:@"URI_LIST"]];
	NSArray *foundOps = [downloadQueue filteredArrayUsingPredicate: pre2];
	return foundOps;
}

/*
	returns all the downloadoperation-objects which belong to the given bundle.
 
	return value: NSArray of QNDowloadOperation
*/
- (NSArray *) downloadOperationsForDownloadBundle: (QNDownloadBundle *) bundle
{
	return [self downloadOperationsForURIList: [bundle URIs]];
}

/*
	returns the download progress for a given bundle.
	return value: float between 0.0 - 1.0
*/
- (float) downloadProgressForDownloadBundle: (QNDownloadBundle *) bundle
{
	NSArray *ops = [self downloadOperationsForDownloadBundle: bundle];
	
	return [self downloadProgressForDownloadOperationsList: ops];
}

/*
	returns the download progress for the current selection of downloads
 
 	return value: float between 0.0 - 1.0
*/
- (float) downloadProgressForSelectedDownloads
{

	return [self downloadProgressForDownloadOperationsList: [self selectedDownloads]];
}

#pragma mark -
#pragma mark private
- (float) downloadProgressForDownloadOperationsList: (NSArray *) operations
{
	float cont = (float)[operations count];
	if (cont <= 0.0)
		return 0.0;
	
	float accumulatedProgress = 0.0;
	
	for (QNDownloadOperation *op in operations)
	{
		accumulatedProgress += [op progress];
	}
	return (accumulatedProgress / cont);
}

- (void) updateOverallDownloadProgress
{

	[self setOverallDownloadProgress: [self downloadProgressForDownloadOperationsList: downloadQueue]];
}

- (void) updateOverallDownloadSpeed
{
	float cont = (float)[[self currentlyExecutedDownloadOperations] count];
	if (cont <= 0.0)
		return;
	
	float accumulatedSpeed = 0.0;
	
	for (QNDownloadOperation *op in [self currentlyExecutedDownloadOperations])
	{
		accumulatedSpeed += [op downloadSpeed];
	}
	
	[self setOverallDownloadSpeed: accumulatedSpeed];
}

- (void) applyDownloadSpeedLimitToActiveDownloads
{
	NSArray *currentlyExecutedDownloadOperations = [self currentlyExecutedDownloadOperations];

	if ([currentlyExecutedDownloadOperations count] > 0)
	{
		NSInteger singlespeed = maxDownloadSpeed / [currentlyExecutedDownloadOperations count];

		for (QNDownloadOperation *op in currentlyExecutedDownloadOperations)
			[op setMaxDownloadSpeedLimit: singlespeed];
	}
	
}

#pragma mark -
#pragma mark DownloadOperation delegate
- (void) downloadOperationDownloadProgressDidChange: (QNDownloadOperation *) aDownloadOperation
{
	[self updateOverallDownloadProgress];

	//make sure all downloads follow the speed limit
	//you can't just rely on onetime events to apply this
	//as the nsoperation queue can "lag"
	//so we apply this every time we can. it's cheap anyways
	[self applyDownloadSpeedLimitToActiveDownloads];
	
	
	
	
	
	[[delegate dd_invokeOnMainThreadAndWaitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM]
	 downloadManager: self downloadOperationDownloadProgressDidChange: aDownloadOperation];
	

}

- (void) downloadOperationDownloadSpeedDidChange: (QNDownloadOperation *) aDownloadOperation
{
	[self updateOverallDownloadSpeed];

	
	[[delegate dd_invokeOnMainThreadAndWaitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM]
	 downloadManager: self downloadOperationDownloadSpeedDidChange: aDownloadOperation];

}

- (void) downloadOperationDidStart: (QNDownloadOperation *) aDownloadOperation
{
	[self applyDownloadSpeedLimitToActiveDownloads];
}

- (void) downloadOperationDidFinish: (QNDownloadOperation *) aDownloadOperation
{
	[self saveState];

	[[delegate dd_invokeOnMainThreadAndWaitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM]
	 downloadManager: self downloadOperationDidFinish: aDownloadOperation];

}

- (void) downloadOperationStatusDidChange: (QNDownloadOperation *) aDownloadOperation
{
	
	[[delegate dd_invokeOnMainThreadAndWaitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM]
	 downloadManager: self downloadOperationStatusDidChange: aDownloadOperation];

}


@end
