/*!
    @header QNDownloadManager
	@author Jaroslaw Szpilewski
	@copyright Jaroslaw Szpilewski
	@discussion Header File containing the QNDownloadManager class and categories
*/

//  QNDownloadManager.h
//  DummyDownload
//
//  Created by jrk on 19.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//
//  TODO:
//		- operation resetting
//			(create a new operation, copy the original op's URI to the new one,
//			 replace the old operation with the new one)

#import <Cocoa/Cocoa.h>
#import "QNDownloadOperation.h"
#import "QNDownloadBundle.h"
#import "QNDownloadOperation.h"
#import "QNDownloadManagerDelegateProtocol.h"

#define kQNDownloadManagerSelectionTypeAllDownloads 1
#define kQNDownloadManagerSelectionTypeBundle 2
#define kQNDownloadManagerSelectionTypeUnfinished 3
#define kQNDownloadManagerSelectionTypeFinished 4

/*!
 @coclass QNDowloadOperation
 
 @brief	QNDownloadManager is a download manager that maintains a NSOperationQueue with QNDownloadOperations. 
 
 @discussion The QNDownloadManager is generally accessed as a Singleton with [QNDownloadManager sharedManager] 
 but can also be instanciated like any other object if you need a private local instance.
 
 QNDownloadManager will call it's delegate methods on the application's main thread. But it's not considered
 thread safe.

 */
@interface QNDownloadManager : NSObject <QNDownloadOperationDelegateProtocol>
{
	NSMutableArray *downloadQueue; //queue with waiting urls to be downloaded
	
	id <QNDownloadManagerDelegateProtocol> delegate;
	
	NSOperationQueue *operationQueue;
	
	NSUInteger maxConcurrentDownloads;
	
	float overallDownloadProgress;
	float overallDownloadSpeed;
	
	NSInteger maxDownloadSpeed;

	NSArray *selectedDownloads;
	
	
	unsigned int time1;
	unsigned int time2;

	BOOL isPaused;
	BOOL isRunning;
	
	NSInteger currentSelectionType;
	QNDownloadBundle *selectedBundle;
}

#pragma mark -
#pragma mark properties
/*!
 @brief is the download manager pausing all downloads or not?
 */
@property (readonly, assign) BOOL isPaused;

/*
 @brief is the download manager running (threads scheduling, etc?)
 */
@property (readonly, assign) BOOL isRunning;

/*!
 @brief the delegate that conforms to the QNDownloadManagerDelegateProtocol protocol
*/
@property (readwrite, assign) id <QNDownloadManagerDelegateProtocol> delegate;

/*!
 @brief The number of concurrent downloads the download manager will run simultaneously.
 @discussion This value will be handled over to NSOperationQueue setMaxConcurrentOperationCount:
*/
@property (readwrite, assign) NSUInteger maxConcurrentDownloads;

/*!
 @brief The maximum bandwidth the download manager may use.
 @discussion Each download operation will be limited to X kbit/s for X = maxDownloadSpeed/N 
 where N is the number of currently running downloads.
 */
@property (readwrite, assign) NSInteger maxDownloadSpeed;

/*!
 @brief returns the overall download progress for the download manager's managed operations
*/
@property (readonly, assign) float overallDownloadProgress;

/*!
 @brief returns the average bandwidth consumption of the download manager.
*/
@property (readonly, assign) float overallDownloadSpeed;


/*!
 @brief returns an array (copy) of operations that were previously selected by the user.
 @discussion The selected Downloads can be changed with selectAllDownloads: or selectDownloadsInBundle:
 There are other properties that work with the selection mechanism. like downloadProgressForSelectedDownloads
 
 this array is a copy but it's not a deep copy. so you could fuck up the download operations of the manager.
 yeah it's bad design and i'm a bad coder. but DONT FUCK UP!
*/
@property (readonly, copy) NSArray *selectedDownloads;

/*!
 @brief returns a copy of the current downloadQueue.
 @discussion yeah, it's a copy so you won't fuck up anything. but beware: it's not a deep copy so you can
 fuck up the download operations it contains. please don't fuck up!
*/
@property (readonly, copy) NSArray *downloadQueue; //copy of the download queue

#pragma mark -
#pragma mark singleton access
/*! @functiongroup singleton access */
/*!
 @brief returns the sharedManager
 @discussion if you want a local private download manager just alloc/init QNDownloadManager
 @result singleton instance
*/
+ (QNDownloadManager *) sharedManager;

#pragma mark -
#pragma mark queue managment
/*! @functiongroup queue managment */
/*!
 @brief enqueues the resource specified by the first argument for download
 @discussion will create internally an QNDownloadOperation and enqueue it into the NSOperationQueue.
 @param downloadURI an NSString containing the URI of the resource to download
 */
- (void) enqueueURI: (NSString *) downloadURI;

/*!
 @brief enqueues the resources specified in the passed array
 @discussion will create internally N QNDownloadOperations and enqueue them into the NSOperationQueue.
 @param arrayWithURIs an array containing NSStrings which specify the URI of the resource to download
 */
- (void) enqueueURIs: (NSArray *) arrayWithURIs;

/*!
 @brief enqueues the resources specified in the passed downloadBundle
 @discussion will create internally N QNDownloadOperations and enqueue them into the NSOperationQueue.
 @param downloadBundle an QNDownloadBundle object which contains the URIs of the resources to download
 */
- (void) enqueueDownloadBundle: (QNDownloadBundle *) downloadBundle;

#pragma mark -
#pragma mark download control
/*! @functiongroup download control */
/*!
 @brief starts the NSOperationQueue and the associated download operations
*/
- (void) startDownloading;

/*!
 @brief pauses the download operations
 @discussion will set the max download speed of each operation to 100bit/s which will keep their connection 
 alive but also consume virtually no bandwidth
 */
- (void) pauseDownloading;

/*!
 @brief resumes downlod operations after pauseDownloading was called
 @discussion restores the prevoius download speed to alle running operations
 */
- (void) resumeDownloading;

/*!
 @brief stops the download queue and disconnects any running operation
 @discussion this will kill any download operation. you should only call this if you want to quit the app
 because there is no easy restore of the mess this method creates.
 */
- (void) stopDownloading;

#pragma mark -
#pragma mark operation queryieng
/*! @functiongroup operation querieng */
/*!
 @brief returns all downloadOperations that are associated with the given filename
 @param filename the filename that the wanted download operations are associated with 
 @result Returns a NSArray of QNDownloadOperation or nil if no operations were found.
*/
- (NSArray *) downloadOperationsForFilename: (NSString *) filename;

- (void) removeDownloadOperation: (QNDownloadOperation *) operationToRemove;

/*!
 @brief returns all downloadOperations that are associated with the given download bundle
 @param bundle the bundle that the wanted download operations are associated with 
 @result Returns a NSArray of QNDownloadOperation or nil if no operations were found.
 */
- (NSArray *) downloadOperationsForDownloadBundle: (QNDownloadBundle *) bundle;

#pragma mark -
#pragma mark selection managment
/*! @functiongroup selection managment */
- (void) reloadSelection; //reloads the current selection

/*!
 @brief select all downloads the manager knows about for further manipulation
*/
- (void) selectAllDownloads; //selects all 

/*!
 @brief select all finished downloads the manager knows about for further manipulation
 */
- (void) selectFinishedDownloads;

/*!
 @brief select all unfinished downloads the manager knows about for further manipulation
 */
- (void) selectUnfinishedDownloads;


/*!
 @brief select all downloads in the given bundle for further manipulation
 @param bundle the bundle you want to select
 */
- (void) selectDownloadsInBundle: (QNDownloadBundle *) bundle;

/*!
 @brief returns the progress for the currently selected download operations
 @discussion selections are changed with selectAllDownloads: and selectDownloadsInBundle:
 @result float between 0.0 and 1.1
 */
- (float) downloadProgressForSelectedDownloads;

/*!
 @brief returns the download progress (0.0 .. 1.0) for the given download bundle
 @param bundle the download bundle you want the progress for
 @result float between 0.0 and 1.1
 */
- (float) downloadProgressForDownloadBundle: (QNDownloadBundle *) bundle;

#pragma mark -
#pragma mark state managment
/*! @functiongroup state managment */
/*!
 @brief will load the previously saved state from disk.
 @discussion in the state all information of all known downloads are stored. eg. if they were downloaded,
 if the download was successfull, etc. This is called on the init of the download manager and you typically
 don't need to call this.
 */
- (void) loadState;

/*!
 @brief will save the current state to disk
 @discussion this is typically called when your application will quit. for all other cases (when downloads were added/finished/removed) the
 download manager will save its state autmatically.
 */
- (void) saveState;

@end
