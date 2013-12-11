// ******************************************************************************/
// The MIT License (MIT)
//
// Copyright (c) 2013 Hermiteer Publishing
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ******************************************************************************/

#import "MLAppDelegate.h"

//------------------------------------------------------------------------------
#pragma mark - MLAppDelegate
//------------------------------------------------------------------------------

@implementation MLAppDelegate

//------------------------------------------------------------------------------

- (BOOL) application: (UIApplication*) application didFinishLaunchingWithOptions: (NSDictionary*) launchOptions
{
	// create the main view controller
    self.viewController = [[ MLViewController alloc ] init ];

	// create a window and attach the view controller to it
	self.window = [[ UIWindow alloc ] initWithFrame: [[ UIScreen mainScreen ] bounds ]];
    self.window.rootViewController = self.viewController;
    [ self.window makeKeyAndVisible ];
    
	// listen for changes in reachability
    [[ NSNotificationCenter defaultCenter ] addObserver: self
											   selector: @selector(reachabilityChanged:)
												   name: kReachabilityChangedNotification
												 object: nil ];
    
    // start monitoring for internet reachablity
	self.internetReachability = [ Reachability reachabilityForInternetConnection ];
	[ self.internetReachability startNotifier ];
    
	// if the device is already internet reachable
	// then the internetReachability notifier may not fire
	// so schedule the selector to be called, if it is
	// not reachable, no work will be done
	[ self performSelector: @selector(reachabilityChanged)
				withObject: nil
				afterDelay: 5.0 ];
    
    // done
    return YES;
}

//------------------------------------------------------------------------------

- (void) applicationDidEnterBackground: (UIApplication*) application
{
    [ self.viewController stopAddressQueue ];
    [ self.internetReachability stopNotifier ];
}

//------------------------------------------------------------------------------

- (void) applicationWillEnterForeground: (UIApplication*) application
{
    // start monitoring for internet reachability
    [ self.internetReachability startNotifier ];
    
	// if the device is already internet reachable
	// then the internetReachability notifier may not fire
	// so schedule the selector to be called, if it is
	// not reachable, no work will be done
	[ self performSelector: @selector(reachabilityChanged)
				withObject: nil
				afterDelay: 5.0 ];
}

//------------------------------------------------------------------------------

- (void) applicationWillTerminate: (UIApplication*) application
{
	// stop observing reachability changes
	[[ NSNotificationCenter defaultCenter ] removeObserver: self ];
	
	// stop monitoring
    [ self.internetReachability stopNotifier ];
	self.internetReachability = nil;
}

//------------------------------------------------------------------------------
#pragma mark - Overloaded methods
//------------------------------------------------------------------------------

- (BOOL) isInternetReachable
{
    return ([ self.internetReachability currentReachabilityStatus ] != NotReachable);
}

//------------------------------------------------------------------------------
#pragma mark - Reachability notifications
//------------------------------------------------------------------------------

- (void) reachabilityChanged
{
    if (self.isInternetReachable == YES)
    {
        [ self.viewController startAddressQueue ];
    }
}

//------------------------------------------------------------------------------

- (void) reachabilityChanged: (NSNotification*) note
{
	Reachability* reachability = [ note object ];
	if (reachability == self.internetReachability)
	{
		[ self reachabilityChanged ];
	}
}

//------------------------------------------------------------------------------

@end
