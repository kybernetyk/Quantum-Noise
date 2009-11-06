/*!
    @header QNDownloadManagerDelegateProtocol
	@author Jaroslaw Szpilewski
	@copyright Jaroslaw Szpilewski
    @abstract Contains the protocol definitions of the QNDownloadManagerDelegateProtocol
*/

/*
 *  QNDownloadManagerDelegateProtocol.h
 *  DummyDownload
 *
 *  Created by jrk on 4/10/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

@class QNDownloadOperation;
@class QNDownloadManager;

/*!
    @protocol
    @abstract    The delegate protocol a QNDownloadManager delegate must implement.
*/
@protocol QNDownloadManagerDelegateProtocol

/*!
 @abstract Will be called when a download operation's download progress changed.
 @discussion This will be called on the application's main thread
*/
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadProgressDidChange: (QNDownloadOperation *) aDownloadOperation;

/*!
 @abstract Will be called when a download operation's download speed changed.
 @discussion This will be called on the application's main thread
 */
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadSpeedDidChange: (QNDownloadOperation *) aDownloadOperation;

/*!
 @abstract Will be called when a download operation finished.
 @discussion This will be called on the application's main thread
 */
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDidFinish: (QNDownloadOperation *) aDownloadOperation;

/*!
 @abstract Will be called when a download operation's download status changed.
 @discussion This will be called on the application's main thread
 */
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationStatusDidChange: (QNDownloadOperation *) aDownloadOperation;

@end
