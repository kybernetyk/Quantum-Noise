//
//  QuantumNoiseAppDelegate.m
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QuantumNoiseAppDelegate.h"
#import "QNDownloadManager.h"
#import "QNDownloadBundleManager.h"
#import "PFMoveApplication.h"

@implementation QuantumNoiseAppDelegate

- (IBAction) openMainWindow: (id) sender
{
	if (!mainWindowController)
		mainWindowController = [[QNMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	
	
	//[[mainWindowController window] center];
	[[mainWindowController window] makeKeyAndOrderFront: self];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Offer to the move the Application if necessary.
	// Note that if the user chooses to move the application,
	// this call will never return. Therefore you can suppress
	// any first run UI by putting it after this call.
	
	PFMoveToApplicationsFolderIfNecessary();
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[self openMainWindow: self];
}

@end
