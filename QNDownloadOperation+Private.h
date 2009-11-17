/*
 *  QNDownloadOperation+Private.h
 *  Private QNDownloadOperation methods and property setters
 *
 *  Created by jrk on 12/10/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

#pragma mark -
#pragma mark Private Category
@interface QNDownloadOperation (Private)
- (size_t) curlWriteDataToDiskCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks;
- (size_t) curlHeaderCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks;
- (int) curlProgressCallbackWithDownloadedBytes: (double) bytesDownloaded andTotalBytesToDownload: (double) totalBytes;
- (BOOL) performFileDownload;
- (BOOL) setupProxy;
- (BOOL) setupDownloadPathForFilename: (NSString *) filename;
- (BOOL) finalizeDownload;
- (void) main; //entry point. will be called by the parent NSOperationQueue

- (NSError *) errorWithDescription: (NSString *) errorDescription code: (NSInteger) errorCode andErrorLevel: (NSInteger) errorLevel;
@end

#pragma mark -
#pragma mark session loop parts category
@interface QNDownloadOperation (SessionLoop)
- (BOOL) sessionloop_setupSession;
- (BOOL) sessionloop_beginDownloadSession;
- (BOOL) sessionloop_doDownload;
- (BOOL) sessionloop_cleanupSession;
- (BOOL) sessionloop_endDownloadSession;

- (BOOL) performSelectorSequence: (NSArray *) selectorNames abortOnError: (BOOL) shouldAbortOnError;
@end 
