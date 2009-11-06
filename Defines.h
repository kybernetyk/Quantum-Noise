/*
 *  Defines.h
 *  DummyDownload
 *
 *  Created by jrk on 22/9/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

//our download op statis
#define kQNDownloadStatusDownloading @"Downloading"
#define kQNDownloadStatusPaused @"Paused"
#define kQNDownloadStatusIdle @"Idle"
#define kQNDownloadStatusSuccess @"Succeeded"

//should be CURL verbose?
#define CURL_VERBOSE 0

//should the thread wait for the delegate thread to complete
//the message?
//default NO
#define DOWNLOAD_OPERATION_THREAD_SHOULD_WAIT_FOR_DELEGATE_PERFORM NO

//our location in the source :)
#include <string.h>
#define THIS_FILE ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)
#define SOURCE_LOCATION [NSString stringWithFormat:@"(File: %s Line: %i Method: %s)",THIS_FILE,__LINE__, __PRETTY_FUNCTION__]
#define LOG_LOCATION(); NSLog(@"%@", SOURCE_LOCATION);