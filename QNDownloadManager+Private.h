/*
 *  QNDownloadManager+Private.h
 *  Private QNDownloadManager methods and property setters
 *
 *  Created by jrk on 12/10/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

#pragma mark -
#pragma mark private methods
@interface QNDownloadManager (Private)
- (void) updateOverallDownloadProgress;
- (void) updateOverallDownloadSpeed;
- (void) applyDownloadSpeedLimitToActiveDownloads;
- (NSArray *) downloadOperationsForURIList: (NSArray *) uris;
- (float) downloadProgressForDownloadOperationsList: (NSArray *) operations;
- (NSArray *) currentlyExecutedDownloadOperations; //gets the download operations that are currently executed by the nsoperationqueue
@end

#pragma mark -
#pragma mark private setters
@interface QNDownloadManager () //yep, no category name for real privat accessors. see: http://theocacao.com/document.page/516
@property (readwrite, copy) NSArray *selectedDownloads;
@property (readwrite, assign) float overallDownloadProgress;
@property (readwrite, assign) float overallDownloadSpeed;
@end

