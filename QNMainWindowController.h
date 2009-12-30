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

/*!
 our main window controller.
 */
@interface QNMainWindowController : NSWindowController <QNDownloadManagerDelegateProtocol>
{
	IBOutlet NSView *leftSidebarView;
	IBOutlet NSView *rightContentView;
	IBOutlet NSToolbarItem *pauseResumeButton;
	
	
	QNLeftSidebarViewController *leftSidebarViewController;			//our left sidebar
	QNDownloadsViewController *currentDownloadsViewController;		//currently active right side view controller
	
	NSMutableDictionary *downloadsViewControllerCache;				//cache for right side views.
	NSOperationQueue *unrarOperationQueue;							//operation queue for unrars
}

/*!
 pauses/resumes the download manager (or starts if it has not been run yet)
 */
- (IBAction) pauseResumeDownloading: (id) sender;

/*!
 initiates the add links dialog
 */
- (IBAction) addNewLinks: (id) sender;

/*!
 will remove all finished and failed download bundles and their associated downloads
 */
- (IBAction) cleanupDownloads: (id) sender;
@end
