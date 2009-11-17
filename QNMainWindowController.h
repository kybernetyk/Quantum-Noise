//
//  MainWindowController.h
//  QuantumNoise
//
//  Created by jrk on 08.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNLeftSidebarViewController.h"
#import "QNDownloadsViewController.h"
#import "QNDownloadManagerDelegateProtocol.h"

@interface QNMainWindowController : NSWindowController <QNDownloadManagerDelegateProtocol>
{
	IBOutlet NSView *leftSidebarView;
	IBOutlet NSView *rightContentView;
	IBOutlet NSToolbarItem *pauseResumeButton;
	
	
	QNLeftSidebarViewController *leftSidebarViewController;
	QNDownloadsViewController *currentDownloadsViewController;
	
	NSMutableDictionary *downloadsViewControllerCache;
	NSOperationQueue *unrarOperationQueue;
}

//starts the download manager at all
//is called automatically
- (IBAction) startDownloading: (id) sender;

//our pause/resume button
- (IBAction) pauseResumeDownloading: (id) sender;

//opens the add new links sheet
- (IBAction) addNewLinks: (id) sender;

//will remove all finished and failed download bundles and their associated downloads
- (IBAction) cleanupDownloads: (id) sender;
@end
