//
//  QNRapidshareComDownloadOperation.h
//  DummyDownload
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNDownloadOperation.h"

@interface QNRapidshareComDownloadOperation : QNDownloadOperation 
{
	NSMutableData *receivedData;    //received login data from rapidshare
	NSString *rsCookie;             //our cookie string saving our login state
}

- (NSString *) errorStringForRapidshareErrorPage: (NSString *) errorPageHtmlString;

@end
