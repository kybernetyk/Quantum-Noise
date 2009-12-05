#import "GeneralPreferencePaneController.h"

@implementation GeneralPreferencePaneController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPreferencePaneController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"GeneralPreferencePaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"General";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"General_Prefs"]
        ] autorelease];
}


- (NSString *)paneToolTip
{
    return @"General Preferences";
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
