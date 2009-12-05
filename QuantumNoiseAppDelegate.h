//
//  QuantumNoiseAppDelegate.h
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNMainWindowController.h"
#import "SS_PrefsController.h"

@interface QuantumNoiseAppDelegate : NSObject <NSApplicationDelegate> 
{
	QNMainWindowController *mainWindowController;
	SS_PrefsController *preferencesWindowController;
}

/*!
 @brief Opens the main window
 @discussion will create new window if theres no controller / else it will reopen the existing window
*/
- (IBAction) openMainWindow: (id) sender;
- (IBAction) openPreferencesWindow: (id) sender;

@end
