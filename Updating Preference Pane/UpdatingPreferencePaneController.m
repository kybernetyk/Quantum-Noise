#import "UpdatingPreferencePaneController.h"

@implementation UpdatingPreferencePaneController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[UpdatingPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"UpdatingPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Updating";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"Updating_Prefs"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Updating Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}


@end
