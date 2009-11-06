/*
 *  QNRapidshareComDownloadOperation+Private.h
 *  Private QNRapidshareComDownloadOperation methods and property setters
 *
 *  Created by jrk on 12/10/09.
 *  Copyright 2009 flux forge. All rights reserved.
 *
 */

@interface QNRapidshareComDownloadOperation (Private)
- (size_t) rapidshareLoginWriteDataCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks;
@end
