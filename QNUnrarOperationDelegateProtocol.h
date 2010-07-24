/*
 *  QNUnrarOperationDelegateProtocol.h
 *  DummyDownload
 *
 *  Created by jrk on 24/9/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

@class QNUnrarOperation;
@protocol QNUnrarOperationDelegateProtocol

- (void) unrarOperationEnqueuedForExtraction: (QNUnrarOperation *) anUnrarOperation;
- (void) unrarOperationDidStart: (QNUnrarOperation *) anUnrarOperation;
- (void) unrarOperationProgressDidChange: (QNUnrarOperation *) anUnrarOperation;
- (void) unrarOperationDidEnd: (QNUnrarOperation *) anUnrarOperation;

@end
