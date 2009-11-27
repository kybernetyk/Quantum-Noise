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

@implementation QuantumNoiseAppDelegate

- (IBAction) openMainWindow: (id) sender
{
	if (!mainWindowController)
		mainWindowController = [[QNMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	
	
	//[[mainWindowController window] center];
	[[mainWindowController window] makeKeyAndOrderFront: self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[self openMainWindow: self];
}

@end
