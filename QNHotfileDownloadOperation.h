//
//  QNHotfileDownloadOperation.h
//  QuantumNoise
//
//  Created by jrk on 24/7/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QNDownloadOperation.h"


@interface QNHotfileDownloadOperation : QNDownloadOperation
{
	//NSMutableData *receivedData;    //tmp storage for received data (header/login stuff only)
}
//- (size_t) hotfileLoginWriteDataCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks;
@end
