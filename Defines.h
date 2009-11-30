/*
 *  Defines.h
 *  DummyDownload
 *
 *  Created by jrk on 22/9/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

//our download operation status strings
#define kQNDownloadStatusDownloading @"Downloading"
#define kQNDownloadStatusPaused @"Paused"
#define kQNDownloadStatusIdle @"Idle"
#define kQNDownloadStatusSuccess @"Succeeded"

//our download operation error levels
//the error level describes if the download can be 
//retried (kQNDownloadOperationErrorRecoverable || kQNDownloadOperationErrorDontKnow ) 
//or if the error was fatal
//and the operation can not be reset (like 404 file not found)
#define kQNDownloadOperationErrorRecoverable 1
#define kQNDownloadOperationErrorDontKnow 2
#define kQNDownloadOperationErrorFatal 3

//should CURL be verbose?
#define CURL_VERBOSE 0

//should the thread wait for the delegate thread to complete
//the message?
//default NO
#define DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM NO

//helper macros for NSLog() 
//our location in the source :)
#include <string.h>
#define THIS_FILE ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)
#define SOURCE_LOCATION [NSString stringWithFormat:@"(File: %s Line: %i Method: %s)",THIS_FILE,__LINE__, __PRETTY_FUNCTION__]
#define LOG_LOCATION(); NSLog(@"%@", SOURCE_LOCATION);