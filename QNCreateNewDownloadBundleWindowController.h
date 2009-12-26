//
//  QNCreateNewDownloadBundleWindowController.h
//  DummyDownload
//
//  Created by jrk on 15/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNDownloadBundle.h"

#define kCreateDownloadBundleSheetReturnCodeAbort 0
#define kCreateDownloadBundleSheetReturnCodeContinue 1


@interface QNCreateNewDownloadBundleWindowController : NSWindowController 
{
	NSArray *links;

	NSString *bundleTitle;
	NSString *bundleArchivePassword;
	
	
	IBOutlet NSTextField *bundleNameTextField;
	IBOutlet NSTextField *archivePasswordTextField;
}
@property (readwrite, copy) NSArray *links;
@property (readwrite, copy) NSString *bundleTitle;
@property (readwrite, copy) NSString *bundleArchivePassword;

//- (NSString *) bundleTitleForLink: (NSString *) link;

- (IBAction) addButton: (id) sender;
- (IBAction) cancelButton: (id) sender;

@end
