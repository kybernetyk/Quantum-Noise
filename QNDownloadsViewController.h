//
//  QNDownloadsViewController.h
//  QuantumNoise
//
//  Created by jrk on 20/10/09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QNDownloadsViewController : NSViewController 
{
	NSArray *dataSource;
	IBOutlet NSTableView *tableView;
}
@property (readwrite, copy) NSArray *dataSource;
@property (readwrite, retain) IBOutlet NSTableView *tableView;

- (void) reloadContent;

@end
