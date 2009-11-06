//
//  QuantumNoiseAppDelegate.h
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QNMainWindowController.h"

@interface QuantumNoiseAppDelegate : NSObject <NSApplicationDelegate> 
{
	QNMainWindowController *mainWindowController;
}

/*!
 @brief Opens the main window
 @discussion will create new window if theres no controller / else it will reopen the existing window
*/
- (IBAction) openMainWindow: (id) sender;

@end
