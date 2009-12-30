//
//  QuantumNoiseAppDelegate.m
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QuantumNoiseAppDelegate.h"
#import "QNLinkExtractor.h"
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

- (IBAction) openPreferencesWindow: (id) sender
{
	if (preferencesWindowController)
	{
		[preferencesWindowController showPreferencesWindow];
		return;
	}
	
	// Determine path to the sample preference panes
     NSString *pathToPanes = [[NSString stringWithFormat:@"%@/Contents/Resources/", [[NSBundle mainBundle] bundlePath]]
								 stringByStandardizingPath];
	
	preferencesWindowController = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes bundleExtension:@"bundle"];
	
	// Set which panes are included, and their order.
	[preferencesWindowController setPanesOrder:[NSArray arrayWithObjects:@"General",@"Updating", @"A Non-Existent Preference Pane", nil]];
	// Show the preferences window.
	[preferencesWindowController showPreferencesWindow];

}

- (void) registerUserDefaults
{
	/*
	 yes, we save the rs.com credentials in plain text.
	 TODO: use security.framework functions to store credentials in the key chain
	 */
	NSDictionary *userDefs = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithBool: YES], @"createDirectoriesForBundles",
							  [NSNumber numberWithInt: 4], @"maxConcurrentDownloadOperations",
							  [NSNumber numberWithInt: 0],@"maxBandwidthUsage",
							  [NSNumber numberWithBool: NO], @"proxyEnabled",
							  @"1839287",@"rapidShareCom_username",
							  @"OYNjH8YziW",@"rapidShareCom_password",
							  nil];
	
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: userDefs];
	
	
	
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Offer to the move the Application if necessary.
	// Note that if the user chooses to move the application,
	// this call will never return. Therefore you can suppress
	// any first run UI by putting it after this call.
	PFMoveToApplicationsFolderIfNecessary();
	
	[self registerUserDefaults];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[self openMainWindow: self];
}

@end
