/*!
    @header QNDownloadOperation+Factory
    @abstract   Header containing factory methods for QNDownloadOperation
	@author Jaroslaw Szpilewski
	@copyright Jaroslaw Szpilewski
 */

//
//  QNDownloadOperation+Factory.h
//  DummyDownload
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNDownloadOperation.h"


/*!
    @abstract Factory methods for QNDownloadOperation
*/
@interface QNDownloadOperation (Factory)

/*!
 @abstract creates a downloadOperation for the given URI
 @discussion The factory parses the URI and checks on which hoster the file is. It creates then the
 appropriate QNDownloadOperation subclass. for rapidshare.com links it will return QNRapidshareComDownloadOperation objects for example.
 */
+ (id) downloadOperationForURI: (NSString *) aURI;

@end
