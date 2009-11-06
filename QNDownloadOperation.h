/*!
    @header QNDownloadOperation
    @author	Jaroslaw Szpilewski
	@copyright Jaroslaw Szpilewski
	@abstract Contains the QNDownloadOperation base class definitions
*/



//
//  QNDownloadOperation.h
//  DummyDownload
//
//
//	Download Operation using libCurl for downloading
//
//	ToDO:
//	- FUCKING ERROR HANDLING (WTF HAPPENS IF THE INTERNETZ GOES HOFF?)
//	- NSError error handling instead of BOOL
//	- operation resetting.
//  Created by jrk on 20.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <curl/curl.h>
#import "QNDownloadOperation.h"
#import "QNDownloadOperationDelegateProtocol.h"
#include <sys/time.h>

/*!
	@classdesign Multithreaded threadsafe.
    @abstract    A download operation to download a file and save it to disk.
    @discussion  This is a class inherited from NSOperation and is executed in its own thread. 
	All delegate methods will be called on the application's main thread.
 
	QNDownloadOperation uses libcurl for network access.
*/
@interface QNDownloadOperation : NSOperation
{
	CURL *curlHandle;
	NSFileHandle *temporaryDownloadHandle;
	
	//properties
	NSString *URI;
	NSString *fileName;
	NSString *temporaryDownloadFilename;
	NSString *status;
	
	double progress;
	double downloadSpeed;
	double receivedBytes;
	double fileSize;
	
	id <QNDownloadOperationDelegateProtocol> delegate;

	//has the operation been executed?
	BOOL hasBeenExecuted;
	
	//did an error occur?
	NSError *operationError;
	

	//this is our generall received data
	//it is used by the login modules to save the login pages
	//and parse them for success
	//don't forget to release and set to nil after you're done with it! (ESPECIALLY DONT FORGET TO SET TO NIL NIL NIL NIL!!!!)
	//NSMutableData *receivedData;
	
	NSInteger maxDownloadSpeedLimit;
	
	BOOL isPaused; //is the download paused? (limiting speed to ~ 0kbit/s)
	
	
	//
	NSMutableData *myDataCache;
	
	//these vars are used to limit our delegate update frequency (to save redraws of UI)
	unsigned int speedUpdateDelegateTimer;
	unsigned int progressUpdateDelegateTimer;
}

#pragma mark -
#pragma mark properties
@property (readwrite, assign) id delegate;
@property (readwrite,copy) NSString *URI;
@property (readwrite,copy) NSString *status;
@property (readwrite, copy) NSString *temporaryDownloadFilename;
@property (readwrite, copy) NSString *fileName;

@property (readwrite,assign) double progress;
@property (readwrite,assign) double downloadSpeed;
@property (readwrite,assign) double fileSize;
@property (readwrite,assign) double receivedBytes;
@property (readwrite, assign) NSInteger maxDownloadSpeedLimit;

@property (readwrite, assign) BOOL isPaused;

@property (readwrite, assign) BOOL hasBeenExecuted;
@property (readwrite, retain) NSError *operationError;

#pragma mark -
#pragma mark initializer
/*! @functiongroup Initializer */
/*!
 @brief the designated initializer returning a QNDownloadOperation for a given URI.
 @param aURI A NSString with the URI location of a resource to download.
*/
- (id) initWithURI: (NSString *) aURI;

#pragma mark -
#pragma mark serialization
/*! @functiongroup Serialization */
/*!
 @brief returns a NSDictionary with all important properties and their values.
 @discussion this is used for serialization and you normally should not need to call this ever.
*/
- (NSDictionary *) dictionaryRepresentation;

@end




