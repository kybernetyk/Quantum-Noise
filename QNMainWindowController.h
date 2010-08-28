/*!
 @header MainWindowController
 @author	Jaroslaw Szpilewski
 @copyright Jaroslaw Szpilewski
 @abstract Controller for the Main Window
 */

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
#import "QNUnrarOperationDelegateProtocol.h"

/*!
 our main window controller.
 */
@interface QNMainWindowController : NSWindowController
{
	IBOutlet NSView *leftSidebarView;
	IBOutlet NSView *rightContentView;
	IBOutlet NSToolbarItem *pauseResumeButton;
	
	
	QNLeftSidebarViewController *leftSidebarViewController;			//our left sidebar
	QNDownloadsViewController *currentDownloadsViewController;		//currently active right side view controller
	
	NSMutableDictionary *downloadsViewControllerCache;				//cache for right side views.
	NSOperationQueue *unrarOperationQueue;							//operation queue for unrars
}

- (void) synchronizeViewsWithManagers;

/*!
 pauses/resumes the download manager (or starts if it has not been run yet)
 */
- (IBAction) pauseResumeDownloading: (id) sender;

/*!
 will remove all finished and failed download bundles and their associated downloads
 */
- (IBAction) cleanupDownloads: (id) sender;
@end


@interface QNMainWindowController (DownloadManagerDelegate) <QNDownloadManagerDelegateProtocol> //see +DownloadManaderDelegate.m
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadProgressDidChange: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDownloadSpeedDidChange: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationDidFinish: (QNDownloadOperation *) aDownloadOperation;
- (void) downloadManager: (QNDownloadManager *) theDownloadManager downloadOperationStatusDidChange: (QNDownloadOperation *) aDownloadOperation;
@end;

@class QNUnrarOperation;
@interface QNMainWindowController (UnrarDelegate) <QNUnrarOperationDelegateProtocol> //see +UnrarDelegate.m
- (void) unrarOperationDidStart: (QNUnrarOperation *) anUnrarOperation;
- (void) unrarOperationProgressDidChange: (QNUnrarOperation *) anUnrarOperation;
- (void) unrarOperationDidEnd: (QNUnrarOperation *) anUnrarOperation;
@end


@class QNAddDownloadLinksWindowController;
@class QNCreateNewDownloadBundleWindowController;
@interface QNMainWindowController (sheets) //see +Sheets.m
/*!
 initiates the add links dialog
 */
- (IBAction) addNewLinks: (id) sender;

- (void) addLinksSheetDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode addLinksController: (QNAddDownloadLinksWindowController *) controller;
- (void) createNewDownloadBundleSheetWithLinks: (NSArray *) links andPasswordHint: (NSString *) passwordHint;
- (void) createDownloadBundleSheetDidEnd:(NSWindow *)sheet returnCode: (NSInteger)returnCode createBundleController: (QNCreateNewDownloadBundleWindowController *) controller;
@end

@class QNDownloadBundle;
@interface QNMainWindowController (Helper)
- (void) setValue: (id) value forKey: (id) key forAllOperationsInBundle: (QNDownloadBundle *) bundle;
- (void) checkForCompleteBundlesAndProcessThem;
@end


