#import "AppDelegate.h"
#import "EAGLView.h"

@implementation lesson07AppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
	glView.animationInterval = 1.0 / kFPS;
	[glView startAnimation];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 5.0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / kFPS;
}

- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
