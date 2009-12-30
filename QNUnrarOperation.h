//
//  QNUnrarOperation.h
//  DummyDownload
//
//  Created by jrk on 23/9/09.
//  Copyright 2009 flux forge. All rights reserved.
//
//	contributors:
//	jrk
//	prattel

#import <Cocoa/Cocoa.h>
#import "QNUnrarOperationDelegateProtocol.h"

@interface QNUnrarOperation : NSOperation 
{
	NSString *rarfile;
	NSString *password;
	id <QNUnrarOperationDelegateProtocol> delegate;
	NSInteger progress;
	NSInteger returnCode;
}

@property (readonly, copy) NSString *rarfile;

@property (readwrite, assign) NSInteger progress;
@property (readwrite, assign) NSInteger returnCode;
@property (readwrite, assign) id delegate;

- (id) initWithFilename: (NSString *) rarFileToUnrar andPassword: (NSString *) rarPassword;

@end
