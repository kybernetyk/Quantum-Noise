//
//  QNCurlDownloadOperation.m
//  DummyDownload
//
//	Download Operation using libCurl for downloading
//
//
//  Created by jrk on 20.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadOperation.h"
#import "QNDownloadOperation+Private.h"
#import <curl/curl.h>
#import <sys/time.h>
#import "NSString+Search.h"
#import <sys/time.h>


/* will return the current system time in milliseconds */
unsigned int SystemTimeInMilliSeconds (void)
{
	struct timeval v;
	gettimeofday(&v, 0);
	//long millis = (v.tv_sec * 1000) + (v.tv_usec / 1000);
	//return millis;
	
	return (v.tv_sec * 1000) + (v.tv_usec / 1000);
}



#pragma mark -
#pragma mark C99 curl callbacks
//header callback

size_t header_callback (void *buffer, size_t size, size_t nmemb, void *inSelf)
{
	QNDownloadOperation *me = (QNDownloadOperation *)inSelf;
	return [me curlHeaderCallbackWithDataPointer: buffer blockSize: size numberOfBlocks: nmemb];
}


//file writing callback
//called by curl when new data was downloaded
//will call the current DownloadOperation with this data
size_t write_data_callback (void *buffer, size_t size, size_t nmemb, void *inSelf)
{
	QNDownloadOperation *me = (QNDownloadOperation *)inSelf;
	return [me curlWriteDataToDiskCallbackWithDataPointer: buffer blockSize: size numberOfBlocks: nmemb];
}

//progress callback
//called by curl when the download progress changed
//will call current DownloadOperation with the new values
int progress_callback (void *inSelf, double dltotal, double dlnow, double ultotal, double ulnow)
{
	QNDownloadOperation *me = (QNDownloadOperation *)inSelf;
	return [me curlProgressCallbackWithDownloadedBytes: dlnow andTotalBytesToDownload: dltotal];
}



#pragma mark -
#pragma mark properties
@implementation QNDownloadOperation
@synthesize maxDownloadSpeedLimit;
@synthesize URI;
@synthesize status;
@synthesize progress;
@synthesize downloadSpeed;
@synthesize temporaryDownloadFilename;
@synthesize fileName;
@synthesize delegate;
@synthesize fileSize;
@synthesize receivedBytes;
@synthesize hasBeenExecuted;
@synthesize operationError;
@synthesize isPaused;


#pragma mark -
#pragma mark initializer
- (id) initWithURI: (NSString *) aURI
{
	self = [super init];
	
	curlHandle = curl_easy_init();
	curl_easy_setopt(curlHandle, CURLOPT_VERBOSE, CURL_VERBOSE);
	
	[self setURI: aURI];
	[self setProgress: 0.0];
	[self setDownloadSpeed: 0.0];
	[self setFileName: [aURI lastPathComponent]];
	[self setStatus: kQNDownloadStatusIdle];
//	[self setShouldKeepCopyOfDownloadInMemory: NO];
	
	//[self setupFilenames];
	
	//[self checkIfDownloadExistsAndSetupState];
	//[self cancel];
	
	return self;
}

- (void)dealloc
{
	NSLog(@"download operation dealloc");
	[URI release];
	[fileName release];
	[temporaryDownloadFilename release];
	[operationError release];
    [super dealloc];
}

#pragma mark -
#pragma mark implementation
- (NSDictionary *) dictionaryRepresentation
{
	/*		NSString *URI						=		[downloadDict objectForKey: @"URI"];
	 NSString *fileName					=		[downloadDict objectForKey: @"fileName"];
	 NSString *temporaryDownloadFilename =		[downloadDict objectForKey: @"temporaryDownloadFilename"];
	 NSString *status					=		[downloadDict objectForKey: @"status"];
	 
	 double progress						=		[[downloadDict objectForKey: @"progress"] doubleValue];
	 double speed						=		[[downloadDict objectForKey: @"speed"] doubleValue];
	 double receivedBytes				=		[[downloadDict objectForKey: @"receivedBytes"] doubleValue];
	 double fileSize						=		[[downloadDict objectForKey: @"fileSize"] doubleValue];
	 
	 BOOL hasBeenExecuted				=		[[downloadDict objectForKey: @"hasBeenExecuted"] boolValue];
	 
*/
	
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	@synchronized (self)
	{
		if (URI)
			[dict setObject: [NSString stringWithString: URI] forKey: @"URI"];
		if (fileName)
			[dict setObject: [NSString stringWithString: fileName] forKey: @"fileName"];
		if (temporaryDownloadFilename)
			[dict setObject: [NSString stringWithString: temporaryDownloadFilename] forKey: @"temporaryDownloadFilename"];
		if (status)
			[dict setObject: [NSString stringWithString: status] forKey: @"status"];


		[dict setObject: [NSNumber numberWithDouble: progress] forKey:  @"progress"];
		[dict setObject: [NSNumber numberWithDouble: downloadSpeed] forKey:  @"speed"];
		[dict setObject: [NSNumber numberWithDouble: receivedBytes] forKey:  @"receivedBytes"];
		[dict setObject: [NSNumber numberWithDouble: fileSize] forKey:  @"fileSize"];
	
		[dict setObject: [NSNumber numberWithBool: hasBeenExecuted] forKey:  @"hasBeenExecuted"];
	}
	

	return [NSDictionary dictionaryWithDictionary: dict];
	
}


- (NSString *) description
{
	return [NSString stringWithFormat:
			@"<DownloadOperation 0x%x>\n\turl = %@;\n\tprogress = %f;\n\tspeed = %f\n\tfilename = %@\n\ttempFile = %@\n\tstatus = %@\n\thasBeenExecuted = %i",
			self, 
			[self URI],
			[self progress],
			[self downloadSpeed],
			[self fileName],
			[self temporaryDownloadFilename],
			[self status],
			[self hasBeenExecuted]
			];
}



- (void) setStatus: (NSString *) newStatus
{	
	id temp = status;
	[self willChangeValueForKey: @"status"];
	status = [[NSString stringWithString: newStatus] retain];
	[self didChangeValueForKey: @"status"];
	[temp release];
	
	[delegate performSelectorOnMainThread: @selector(downloadOperationStatusDidChange:) 
							   withObject: self 
							waitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM];
}

//time in millisecods to wait between 2 consecutive delegate calls
#define kDelegateTimerThreshold 333 

- (void) setProgress: (double) newProgress
{
	[self willChangeValueForKey: @"progress"];
	progress = newProgress;
	[self didChangeValueForKey: @"progress"];
	

//	if (progressUpdateDelegateTimer != 0) 
//	{
		if (SystemTimeInMilliSeconds() - progressUpdateDelegateTimer < kDelegateTimerThreshold && progress < 1.0)
			return;
//	}
	progressUpdateDelegateTimer = SystemTimeInMilliSeconds();
	
	
	[delegate performSelectorOnMainThread: @selector(downloadOperationDownloadProgressDidChange:) 
							   withObject: self 
							waitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM];
}

- (void) setDownloadSpeed: (double) newSpeed
{
	[self willChangeValueForKey: @"downloadSpeed"];
	downloadSpeed = newSpeed;
	[self didChangeValueForKey: @"downloadSpeed"];
	
//	if (speedUpdateDelegateTimer != 0)
//	{
		if (SystemTimeInMilliSeconds() - speedUpdateDelegateTimer < kDelegateTimerThreshold)
			return;
//	}
	speedUpdateDelegateTimer = SystemTimeInMilliSeconds();
	
	
	[delegate performSelectorOnMainThread: @selector(downloadOperationDownloadSpeedDidChange:)
							   withObject: self 
							waitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM];
}

- (size_t) curlHeaderCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks
{

	NSData *d = [[NSData alloc] initWithBytes: data length: blockSize * numberOfBlocks];
	NSString *header = [[NSString alloc] initWithData: d encoding: NSUTF8StringEncoding];
	if ([header containsString:@"Content-Disposition: Attachment;" ignoringCase: YES])
	{
		NSRange start = [header rangeOfString:@"filename="];
		start.location = start.location + start.length;
		
		NSString *fname = [header substringFromIndex: start.location];
		fname = [fname stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		fname = [fname stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		
		if (![self setupDownloadPathForFilename: fname])
		{	
			[header release];
			header = nil;
			[d release];
			d = nil;
			return 0;
		}
		
	}
	[header release];
	[d release];
	
	return blockSize * numberOfBlocks;
}


/*
 this method is called by the C99 curl callback
	size_t write_data_callback (void *buffer, size_t size, size_t nmemb, void *inSelf)
 when curl downloaded new data. curl asks us to save the data to disk (or process it somehow else)
 
 the method will append the data to the temporary download file throgh a NSFileHandle.
 
 called by: curl C99 callback write_data_callback()
 
 returns the ammount of written bytes if the download should continue
 returns -1 if curl should cancel the download
 */
- (size_t) curlWriteDataToDiskCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks
{
	//wurde der thread gecancelled?
	if ([self isCancelled])
	{	
		[self setStatus:@"Error: Operation was cancelled!"];
		[self setHasBeenExecuted: YES];
		return -1;
	}
	
	//if no temporary file handles were created
	//no content-disposition attachement filename was received
	//lets setup our files
	//[self setupFilenames];
		
	if (!temporaryDownloadHandle)
	{	// Content-Disposition: Attachment; filename
		//curl_easy_getinfo(<#CURL *curl#>, <#CURLINFO info#>)
		
		temporaryDownloadHandle = [[NSFileHandle fileHandleForWritingAtPath: [self temporaryDownloadFilename]] retain];
		
	}

	NSData *d = [[NSData alloc] initWithBytes: data length: blockSize * numberOfBlocks];
	[temporaryDownloadHandle writeData: d];
	[d release];

	//ODER
	
/*	[myDataCache appendData: d];
	[d release];

	
	if (!myDataCache)
	{
		//we don't have an autoreleasepool in here!
		myDataCache = [[NSMutableData alloc] init];
	}

	[myDataCache appendData: d];
	[d release];
	
	//if our cache is above 2mb or we got the last block flush it
	if ([myDataCache length] > 0x3FFFFE || (blockSize * numberOfBlocks) != CURL_MAX_WRITE_SIZE)
	{
		//NSLog(@"writing %i bytes",[myDataCache length]);
		
		[temporaryDownloadHandle writeData: myDataCache];
		[myDataCache release];
		myDataCache = nil;
	}
*/	
	
	
	
	
	return blockSize * numberOfBlocks;
}

/*
 this method is called by the C99 curl callback
	int progress_callback (void *inSelf, double dltotal, double dlnow, double ultotal, double ulnow)
 when the download's progress changed. (e.g. new data was loaded)
 
 it will calculate the average download speed and the download progress in percent (0.0 - 1.0)
 the instance properties will be updated and the delegate will be messeged of the updates

 called by: curl C99 callback progress_callback()
 
 returns 0 if the download should continue
 returns 1 if curl should cancel the download
*/
- (int) curlProgressCallbackWithDownloadedBytes: (double) bytesDownloaded andTotalBytesToDownload: (double) totalBytes
{
	//wurde der thread gecancelled?
	if ([self isCancelled])
	{	
		[self setHasBeenExecuted: YES];
		[self setStatus:@"Error: Operation was cancelled!"];
		return 1;
	}
	
	/* todo:
	 die ganzen NSNumbers in native typen umbauen
	 */
/*	timingBytes += (bytesDownloaded - [self receivedBytes]);
	
	if (lastCallTime == 0.0)
	{
		lastCallTime = currentTimeInSeconds();
		timingBytes = 0.0;
	}
	else 
	{
		double now = currentTimeInSeconds();
		

		double diffSeconds = now - lastCallTime;
		//printf("diffsecs: %f\n",diffSeconds);

		if (diffSeconds >= 1.0)
		{
			double kb = (timingBytes/1000.0) / diffSeconds;

			[self setSpeed: kb];
			
			timingBytes = 0.0;
			lastCallTime =  currentTimeInSeconds();

		}
/*		if (diffSeconds >= 5.0)
		{
			timingBytes = 0.0;
			lastCallTime =  currentTimeInSeconds();
		}*/
		
//	}

//	CURLINFO_SPEED_DOWNLOAD
	
	double d = 0.0;
	curl_easy_getinfo(curlHandle, CURLINFO_SPEED_DOWNLOAD,&d);
	d = d / 1000.0;
	[self setDownloadSpeed: d];
	
	
	[self setReceivedBytes: bytesDownloaded];
	[self setFileSize:  totalBytes];
	
	double progress_ = 0.0;
	
	if (totalBytes != 0.0)
		progress_ = (1.0 / totalBytes) * bytesDownloaded;

	[self setProgress: progress_];
	
	//sind wir pausiert?
	if ([self isPaused])
	{
		curl_easy_setopt(curlHandle, CURLOPT_MAX_RECV_SPEED_LARGE, 100); //"pause" by limiting dl speed to almost 0
		
		if (![[self status] isEqualToString: kQNDownloadStatusPaused])
			[self setStatus: kQNDownloadStatusPaused];
	}
	else
	{
		curl_easy_setopt(curlHandle, CURLOPT_MAX_RECV_SPEED_LARGE, maxDownloadSpeedLimit);
		
		if (![[self status] isEqualToString: kQNDownloadStatusDownloading])
			[self setStatus: kQNDownloadStatusDownloading];
	}
	
	return 0;
}

- (void) setSpeed: (float) s
{
	NSLog(@"set speed float?");
	exit (101);
}



/*
	will download the file specified in the URI.

	called by: thread main:
 
	returns YES for fucking success
	returns NO for fail
 
	todo: 
		- NSError return with status code and shit and fuck
*/
- (BOOL) performFileDownload
{
	if (!curlHandle)
	{	
		[self setStatus: @"performFileDownload: No curl handle! Fatal!"];
		return NO;
	}

	//setup curl for http get
	curl_easy_setopt(curlHandle, CURLOPT_HTTPGET,1);
	curl_easy_setopt(curlHandle, CURLOPT_URL, [[self URI] UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);

	//
	//curl_easy_setopt(curlHandle, CURLOPT_MAX_RECV_SPEED_LARGE, 250000);
	//header
	curl_easy_setopt(curlHandle, CURLOPT_HEADERFUNCTION, header_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEHEADER, self);
	
	//file writing
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, write_data_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, self);
	
	//progress
	curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 0);
	curl_easy_setopt(curlHandle, CURLOPT_PROGRESSFUNCTION, progress_callback);
	curl_easy_setopt(curlHandle, CURLOPT_PROGRESSDATA, self);	
	
	CURLcode res = curl_easy_perform(curlHandle);
	
	NSLog(@"CURL DOWNLOAD RETURNED: %i = %s",res, curl_easy_strerror(res));
	
	if (res != CURLE_OK)
	{	
		//TODO: ein nserror in die klasse tun und gescheites handling bauen
		
		if (res != 23) //writing abort through handler return 0
			[self setStatus: [NSString stringWithFormat: @"Download Failed: %s", curl_easy_strerror(res)]];
		return NO;
	}
	
	return YES;	
}

/*
	will read the proxy from the configuration file
	and use it for the download
 
	lol lie, which config file? it's all hardcode baby!

 	called by: thread main:
 
	returns YES if a proxy was found and could be set
	returns NO if something went wrong

	TODO:
		- use the proxy to test if it works. return then the test result
*/
- (BOOL) setupProxy
{
	if (!curlHandle)
	{	
		[self setStatus: @"setupProxy: No curl handle! Fatal!"];
		return NO;
	}
	
	curl_easy_setopt(curlHandle, CURLOPT_PROXY, "localhost:8886");
	
	//Some proxies require user authentication before allowing a request, and you pass that information similar to this:
	//curl_easy_setopt(curlHandle, CURLOPT_PROXYUSERPWD, "user:password");
	
//	If you want to, you can specify the host name only in the CURLOPT_PROXY option, and set the port number separately with CURLOPT_PROXYPORT.
//	Tell libcurl what kind of proxy it is with CURLOPT_PROXYTYPE (if not, it will default to assume a HTTP proxy):
	curl_easy_setopt(curlHandle, CURLOPT_PROXYTYPE, CURLPROXY_SOCKS4);
	
	return YES;
}


/*
 this does soooooooooooo much:
	- build final filename from URI
	- build temp downlaod filename from URI
	- create the temporary download file
	- check if final file exists and FUCKING BAIL OUT IF SO
 
 called by: thread main:
 
 returns YES for okidoki
 returns NO for WTF SOMETHING IS WRONG
 
 todo:
	- NSError return handling shit and fuck
 
*/
//- (void) setupDownloadPathForFilename: (NSString *) filename
// should be called by header data handler with the filename retrieved
// from the content-disposition header
// or by the write download data handler if the path were not set (ie no content-disposition header was received)
- (BOOL) setupDownloadPathForFilename: (NSString *) filename
{
//	NSString *filename = [[URI pathComponents] lastObject];
	
	[self setStatus:@"Checking Files"];

	//release old handle
	[temporaryDownloadHandle closeFile];
	[temporaryDownloadHandle release];
	temporaryDownloadHandle = nil;
	
	//the shared manager is not thread safe and is main thread only
	//we are not on the main thread!
	NSFileManager *myThreadSafeFileManagerInstance = [[[NSFileManager alloc] init] autorelease];
	
	//kill old temp filename
	if ([myThreadSafeFileManagerInstance fileExistsAtPath: [self temporaryDownloadFilename]])
	{
		NSError *err;
		[myThreadSafeFileManagerInstance removeItemAtPath: [self temporaryDownloadFilename] error: &err];	
	}
	
	NSString *destinationFilename;
    NSString *homeDirectory=NSHomeDirectory();
	
	destinationFilename=[[homeDirectory stringByAppendingPathComponent:@"Downloads"]
						 stringByAppendingPathComponent:filename];
	
	[self setFileName: destinationFilename];
	destinationFilename = [destinationFilename stringByAppendingPathExtension: @"part"];
	[self setTemporaryDownloadFilename: destinationFilename];

	
	
	NSLog(@"filename: %@", [self fileName]);
	NSLog(@"tempfn: %@",[self temporaryDownloadFilename]);
	LOG_LOCATION();
	
	//check if there's a temporary file .. we could overwrite it later. or resume
	//but now lets just stop the download
	//if there's no file create an empty one for our filehandle
	if (![myThreadSafeFileManagerInstance fileExistsAtPath: [self temporaryDownloadFilename]])
	{	
		[myThreadSafeFileManagerInstance createFileAtPath: [self temporaryDownloadFilename] contents:[NSData dataWithBytes: 0 length: 0] attributes: nil];
	}
	else 
	{
		//for debugging lets kill it and create a new one
		NSError *err;
		[myThreadSafeFileManagerInstance removeItemAtPath: [self temporaryDownloadFilename] error: &err];
		[myThreadSafeFileManagerInstance createFileAtPath: [self temporaryDownloadFilename] contents:[NSData dataWithBytes: 0 length: 0] attributes: nil];
	}
	
	
	//check if the final file exists
	//if yes kill our download
	if ([myThreadSafeFileManagerInstance fileExistsAtPath: [self fileName]])
	{	
		NSLog(@"ERROR! Final file %@ exists already!",[self fileName]);
		
	//	- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error
		//let us set the files size as received byts #
		//and progress to 100%
		NSError *err;
		NSDictionary *fileInfo = [myThreadSafeFileManagerInstance attributesOfItemAtPath: [self fileName]
																				  error: &err];
		NSNumber *num = [NSNumber numberWithLongLong: [fileInfo fileSize]];
		double fsize = [num doubleValue];
		
		[self setFileSize: fsize];
		[self setReceivedBytes: fsize];

		[self setProgress: 1.0]; //we assume that the file was downloaded by the user
		[self setStatus: [NSString stringWithFormat: @"File Error: File %@ exists!", [[[self fileName] pathComponents] lastObject]]];
		return NO;
	}
	
	
	[self setStatus: kQNDownloadStatusDownloading];
	return YES;
}
/*
	Finalizes the download. eg.
	move the temporary download file to the final path
 
	called by: thread main:
 
	returns YES on success
	returns NO on failure
 
	TODO:
		- NSError return shit
 
*/
- (BOOL) finalizeDownload
{
	[self setStatus: @"Dwonload Finished"];
	NSLog(@"finalizing: moving %@ to %@",[self temporaryDownloadFilename],[self fileName]);
	[self setStatus: @"Finalizing"];
	
	NSError *err;

	//the shared manager is not thread safe and is main thread only
	//we are not on the main thread!
	NSFileManager *myThreadSafeFileManagerInstance = [[[NSFileManager alloc] init] autorelease];
	BOOL success = [myThreadSafeFileManagerInstance moveItemAtPath: [self temporaryDownloadFilename] toPath: [self fileName] error:&err];
	if (!success)
	{	
		[self setStatus: [NSString stringWithFormat: @"File Error: Failed (%@) (%@)",[err localizedDescription],[err localizedFailureReason]]];
		[self setProgress: 0.0];
		return NO;
	}
	else 
	{	
		//we're done!
		[self setProgress: 1.0];
		[self setStatus: kQNDownloadStatusSuccess];
		return YES;
	}
}


#pragma mark -
#pragma mark Session Loop Parts
// session loop parts
// this is the (old big) main: method split up in parts
// that can be reused by inherited download operations
// if they need to alter the download sequence


// initializes the auto release pool
// and messages the delegate of the beginning download session
- (BOOL) sessionloop_beginDownloadSession
{
	if (!curlHandle)
	{
		NSLog(@"OK THERES NO HANDLE!");
		exit(99);
	}
	

    if (![self isCancelled] && ![self hasBeenExecuted])
	{	
		[delegate performSelectorOnMainThread: @selector(downloadOperationDidStart:) 
								   withObject: self 
								waitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM];
		[self setStatus: @"Connecting"];
		return YES;
	}

	return NO;
		
}

// reads settings from the user defaults
// ans setups the proxy/download folder
- (BOOL) sessionloop_setupSession
{
	if ([self setupProxy])
	{
		//- (BOOL) setupFilenamesWithRootFilename: (NSString *fileName)
		NSString *filename = [[URI pathComponents] lastObject];
		
		if ([self setupDownloadPathForFilename: filename])
		{
			return YES;
		}
	}
	return NO;
}

// performs the actual download
- (BOOL) sessionloop_doDownload
{
	[self setStatus: kQNDownloadStatusDownloading];
	
	if ([self performFileDownload])
	{	
		return YES;
		
	}
	return NO;
}

// cleans up the mess we did
- (BOOL) sessionloop_cleanupSession
{
	//cleanup the mess
	curl_easy_cleanup(curlHandle);
	[temporaryDownloadHandle closeFile];
	[temporaryDownloadHandle release];
	
	
	//see if there are temp files left and kill them hard!
	NSFileManager *myThreadSafeFileManagerInstance = [[[NSFileManager alloc] init] autorelease];
	if ([myThreadSafeFileManagerInstance fileExistsAtPath: [self temporaryDownloadFilename]])
	{
		NSError *err;
		[myThreadSafeFileManagerInstance removeItemAtPath: [self temporaryDownloadFilename] error: &err];	
	}
	
	
	//message our delegate
	[self setHasBeenExecuted: YES];
	NSLog(@"DOWNLOAD OPERATION ENDED WITH STATUS: %@",[self status]);
	
	[delegate performSelectorOnMainThread: @selector(downloadOperationDidFinish:) 
							   withObject: self 
							waitUntilDone: DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM];	
	
	
	return YES;
}

// releases our pool
- (BOOL) sessionloop_endDownloadSession
{
	

	return YES;
}
#pragma mark -
#pragma mark The Session Loop

// iterates through the array of strings, creates a selector for each string
// calls the selector and if conditional is set to YES breaks execution if the selector returned 0
// if conditional is set to NO the iteration of the array continues till the end - no matter what a selector might return
//
// returns YES if all selectors returned YES
// returns NO if one of the selectors returned NO
//
// todo: change the ugly int casting from [self performSelector: ...] to a NSNumber
//		 for this the called selectors must be rewritten to return a NSNUmber
//
//		 change the array to a dictionary with selectorname + if the selector should abort the loop if it returns NO
//- (BOOL) performSelectorSequence: (NSArray *) selectorNames conditional: (BOOL) conditional
- (BOOL) performSelectorSequence: (NSArray *) selectorNames abortOnError: (BOOL) shouldAbortOnError
{
	BOOL performedFlawless = YES;
	
	for (NSString *methodName in selectorNames)
	{
		NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
		SEL the_selector = NSSelectorFromString( methodName );
		if (![self respondsToSelector: the_selector])
		{
			NSLog(@"OMG NO SELECTOR FOUND FOR [%@ %@]",[self class],methodName);
			exit(1001);
		}
		
		BOOL bContinue = [self performSelector: the_selector];
		
		/* check if the error-ivar was set and then abort if we should abort on error
		 now dummy code: */
		NSLog(@"perform [%@ %@] returned: %i",[self class],methodName,bContinue);
		if (!bContinue)
		{
			performedFlawless = NO;
			if (shouldAbortOnError)
			{	
				[localPool release];
				break;
			}
		}
		[localPool release];
	}
		
	return performedFlawless;
}

// creates a sequence of selectors that should be executed
// and runs it
- (void) main
{
	NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	
	//will break execution if one method returns NO
	NSArray *conditionalDownloadSequence = [NSArray arrayWithObjects: @"sessionloop_beginDownloadSession",
																		@"sessionloop_setupSession",
																		@"sessionloop_doDownload",
																		@"finalizeDownload",
																		nil];
	
	
	//will be executed no matter what the prior method returns
	NSArray *unconditionalDownloadSequence = [NSArray arrayWithObjects: @"sessionloop_cleanupSession",
																		@"sessionloop_endDownloadSession",
																		nil];
	
	[self performSelectorSequence: conditionalDownloadSequence abortOnError: YES];
	[self performSelectorSequence: unconditionalDownloadSequence abortOnError: NO];
	

	
	if (operationError)
	{
		NSLog(@"error has occured: %@",operationError);
		//tut evtl jeder host einen filename mitsenden beim download? damit setupFilenames: nicht so gay ist!
		//performSelectorSequence: abortOnError: !!!!
	}
	[thePool release];	
}



/*
	The main: thread worker.
 
	Does all the dirty work.
 
	called by: parent NSOperationQueue if this download operation is executed
 
	returns nada but will call the delegate on the main thread to inform it
	of the downloads state. see the QNDowloadQueueDelegateProtocol protocol for more
 
*/
/*- (void) main
{
	if (!curlHandle)
	{
		NSLog(@"OK THERES NO HANDLE!");
		exit(99);
	}
	
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if (![self isCancelled] && ![self hasBeenExecuted])
	{
//		- (void) downloadOperationDidStart: (QNDownloadOperation *) aDownloadOperation
		[delegate performSelectorOnMainThread:@selector(downloadOperationDidStart:) withObject: self waitUntilDone: YES];
		[self setStatus: @"Connecting"];

		BOOL continueWithDownload = YES;
	//	CURL *curl;
	//	CURLcode res;
		if ([self isCancelled])
		{	
			[self setHasBeenExecuted: YES];
			return;
		}
		//login
		continueWithDownload = [self setupProxy];

		if ([self isCancelled])
		{	
			[self setHasBeenExecuted: YES];
			return;
		}
		
		
		if (continueWithDownload)
		{	
			continueWithDownload = [self setupFilenames];
			if ([self isCancelled])
			{	
				[self setHasBeenExecuted: YES];
				return;
			}
			
			if (!continueWithDownload)
			{
				//[self setStatus:@"Filename Setup Error"];
				//set in [self setupFilenames]
			}
		}
		else 
		{		
			//[self setStatus: @"Proxy Setup Error"];
			//set in [self setupProxy]
		}

		
		if (continueWithDownload)
		{

			[self setStatus:@"Downloading"];		
			continueWithDownload = [self performFileDownload];
			if ([self isCancelled])
			{	
				[self setHasBeenExecuted: YES];
				return;
			}
				
			if (continueWithDownload)
			{
				[self setStatus: @"Dwonload Finished"];
			}
			else 
			{
				//[self setStatus: @"Curl Download Error"];
			}

		}
		
		if ([self isCancelled])
		{	
			[self setHasBeenExecuted: YES];
			return;
		}

		curl_easy_cleanup(curlHandle);
		[temporaryDownloadHandle closeFile];
		[temporaryDownloadHandle release];

		if (continueWithDownload)
			[self finalizeDownload];

		[self setHasBeenExecuted: YES];
		NSLog(@"DOWNLOAD OPERATION ENDED WITH STATUS: %@",[self status]);
		[delegate performSelectorOnMainThread:@selector(downloadOperationDidFinish:) withObject: self waitUntilDone: YES];
	}
	
	[self setHasBeenExecuted: YES];
	[pool release];
}
*/
@end
