#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface GeneralPreferencePaneController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet NSView *prefsView;
    
}

@end
