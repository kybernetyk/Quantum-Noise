//
//  QNDownloadQueueDelegateProtocol.h
//  DummyDownload
//
//  Created by jrk on 20.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QNDownloadOperation;
@protocol QNDownloadOperationDelegateProtocol

- (void) downloadOperationDidStart: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadOperationDownloadProgressDidChange: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadOperationDownloadSpeedDidChange: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadOperationDidFinish: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadOperationStatusDidChange: (QNDownloadOperation *) aDownloadOperation;

@end
