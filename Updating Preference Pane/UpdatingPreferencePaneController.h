#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface UpdatingPreferencePaneController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet NSView *prefsView;
    
}

@end
