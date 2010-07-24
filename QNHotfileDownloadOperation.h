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
	NSMutableData *receivedData;    //received login data from rapidshare
	NSString *hfCookie;             //our cookie string saving our login state
}

@end
