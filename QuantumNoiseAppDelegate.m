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

- (void) registerUserDefaults
{
	NSUserDefaults *defs = [[NSUserDefaults alloc] init];
	
	[defs setBool: YES forKey: @"createDirectoriesForBundles"];
	[defs setInteger: 4 forKey: @"maxConcurrentDownloadOperations"];
	
	NSDictionary *rapidshare = [NSDictionary dictionaryWithObjectsAndKeys: @"1839287", @"username",
								@"OYNjH8YziW",@"password",
								nil];
	
	NSDictionary *hosters = [NSDictionary dictionaryWithObject: rapidshare forKey: @"rapidshare.com"];
	[defs setObject: hosters forKey: @"supportedHosters"];
	
	/*
	NSDictionary *hosters = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"supportedHosters"];
	NSDictionary *rapidshare = [hosters objectForKey: @"rapidshare"];
	
	if (!rapidshare)
	{
		[self setStatus: @"Login Failed: No Credentials Found for Rapidshare.com"];
		
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		
		return NO;
	}
	
	
	NSString *username = [rapidshare objectForKey: @"username"];
	NSString *password =  [rapidshare objectForKey: @"password"];
	
	NSString *username = @"1839287";
	NSString *password =  @"OYNjH8YziW";
*/	
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: [defs dictionaryRepresentation]];
	
	[defs release];

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
