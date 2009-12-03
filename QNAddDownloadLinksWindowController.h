//
//  QNAddDownloadLinksWindowController.h
//  DummyDownload
//
//  Created by jrk on 15/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kAddDownloadLinksSheetReturnCodeAbort 0
#define kAddDownloadLinksSheetReturnCodeContinue 1


@interface QNAddDownloadLinksWindowController : NSWindowController 
{
	IBOutlet NSTextField *linkInputTextField;
	
	BOOL parseForLinks;
	
	NSArray *links;
	NSString *passwordHint; //if we can guess a pass we should give a hint <3
}

@property (copy, readonly) NSArray *links;
@property (copy, readonly) NSString *passwordHint;
@property (readwrite) BOOL parseForLinks;

- (IBAction) abortButton: (id) sender;
- (IBAction) continueButton: (id) sender;

@end
