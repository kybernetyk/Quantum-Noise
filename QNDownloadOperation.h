/*!
    @header QNDownloadOperation
    @author	Jaroslaw Szpilewski
	@copyright Jaroslaw Szpilewski
	@abstract Contains the QNDownloadOperation base class definitions
	@discussion QNDownloadOperation (and its children) is a NSOperation inherited object that will perform only one task:
				download a file to disk. it will take care of special premium hoster apis (like rapidshare).
 
	Known bugs: This operation will use up too much CPU if many concurrent operations are run with a high download speed (> 3megabyte/s). I will try a reimplementation with a different download lib instead of libcurl.
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
//	- operation resetting.

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
	NSFileHandle *temporaryDownloadHandle;	//filehandle to the temporary download-file on disk
	
	//properties
	NSString *URI;							//the URI (the http://-link of the resource this operation will download)
	NSString *fileName;						//the final filename on disk where the user will find the downloaded file
	NSString *temporaryDownloadFilename;    //filename of the temporary download-file on disk
	NSString *status;						//status string that will be displayed by the user interface
	
	double progress;						//download progress from 0.0 to 1.0
	double downloadSpeed;					//download speed in kilobit/s
	double receivedBytes;					//ammount of already received bytes from the download
	double fileSize;						//the estimated filesize of the fully downloaded file
	
	BOOL isPaused;							//is the download paused? (limiting speed to ~ 0.01kbit/s)
	
	
	BOOL hasBeenExecuted;					//YES if this operation was executed already (so we don't requeue it on restart)
	
	NSError *operationError;				//contains an extended error description on fail. (or nil if there was no error)
	

	NSInteger maxDownloadSpeedLimit;		//the maximum bandwidth this operation may use. (in kilobit/s)
	
	
	id <QNDownloadOperationDelegateProtocol> delegate; //our delegate
	
	
	
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




