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

#import "MLChimpKitKeys.h"
#import "MLViewController.h"

//------------------------------------------------------------------------------
#pragma mark - MLViewController private
//------------------------------------------------------------------------------

@interface MLViewController()

@property (nonatomic, strong) NSMutableArray* addresses;
@property (nonatomic, strong) NSMutableSet* processedAddresses;
@property BOOL processingAddressQueue;

@property (nonatomic, strong) ChimpKit* chimpKit;

@end

//------------------------------------------------------------------------------

@implementation MLViewController

//------------------------------------------------------------------------------
#pragma mark - MLViewController implementation
//------------------------------------------------------------------------------

- (id) init
{
	// Normally the NIB resource loading system will look for ~iPad or
	// ~iPhone when loading a specified controller nib, however for some
	// reason, perhaps because the NIBs have been ported forward from an
	// early Xcode project version, this behaviour is not occuring.
	// So, do a little work to figure out which NIB to use ourselves.
	BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	NSString* nibName = (isPad ? @"MLViewController~iPad" : @"MLViewController~iPhone");
	
	// now create the controller with the correct NIB
	self = [ super initWithNibName: nibName bundle: nil ];
    
	if (self != nil)
    {
        self.addresses = [[ NSMutableArray alloc ] initWithCapacity: 10 ];
        self.processedAddresses = [[ NSMutableSet alloc ] initWithCapacity: 10 ];
    }
	
    return self;
}

//------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [ super viewDidLoad ];
    [ self loadAddresses ];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [ super viewWillAppear: animated ];
    [ self.tableView reloadData ];
}

//------------------------------------------------------------------------------

- (void) viewDidAppear: (BOOL) animated
{
    [ super viewDidAppear: animated ];
	[ self.addressField becomeFirstResponder ];
}

//------------------------------------------------------------------------------

- (BOOL) isEmailAddress: (NSString*) string
{
    // non nil
    if (string == nil || string.length == 0)
    {
        return NO;
    }
    
    // contains @
    NSArray* tokens = [ string componentsSeparatedByString: @"@" ];
    if (tokens.count != 2)
    {
        return NO;
    }
    
    // second token contains at least one .
    tokens = [[ tokens objectAtIndex: 1 ] componentsSeparatedByString: @"." ];
    if (tokens.count < 2)
    {
        return NO;
    }

    // last token of x.x is at least two characters long
    if ([[ tokens objectAtIndex: 1 ] length ] < 2)
    {
        return NO;
    }
    
    // if this far valid address
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - Private methods
//------------------------------------------------------------------------------

- (void) shakeView: (UIView*) view
{
	// prep the view before animation
    view.transform = CGAffineTransformMakeTranslation(-4.0, 0);
	
	// shake it back and forth
	[ UIView animateWithDuration: 0.1
						   delay: 0
						 options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAutoreverse
					  animations: ^
	{
		view.transform = CGAffineTransformMakeTranslation(4.0, 0);
	}
					  completion: ^(BOOL finished)
	{
		view.transform = CGAffineTransformIdentity;
	} ];
}

//------------------------------------------------------------------------------
#pragma mark - Overloaded methods
//------------------------------------------------------------------------------

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	// touching anywhere outside of the keyboard
	// or the address text field will hide the keyboard
    [ self.addressField resignFirstResponder ];
}

//------------------------------------------------------------------------------
#pragma mark - Processing addresses
//------------------------------------------------------------------------------

- (void) startAddressQueue
{
    // create a mail chimp connection if necessary
    if ( self.chimpKit == nil)
    {
        self.chimpKit = [[ ChimpKit alloc ] initWithDelegate: self
												   andApiKey: kChimpKitAPIKey ];
        [ ChimpKit setTimeout: 15 ];
    }
    
    // don't process if already processing
    if ( self.chimpKit != nil && self.processingAddressQueue == NO)
    {
        [ self processAddressQueue ];
    }
}

//------------------------------------------------------------------------------
         
- (void) processAddressQueue
{
    // nothing to do if no address left
    if ( self.addresses == nil || self.addresses.count == 0)
    {
        [[ UIApplication sharedApplication ] setNetworkActivityIndicatorVisible: NO ];
        return;
    }
    
    // make sure chimp kit is ready
    if (self.chimpKit == nil)
    {
        return;
    }

    // mark as processing
    self.processingAddressQueue = YES;
    
    // find the next address to process
    NSString* address = self.addresses.lastObject;

    // build a request dictionary
    // this will use the last address in the list
    NSDictionary* params = @{ @"id" : kChimpKitListID,
							  @"email_address" : address,
							  @"double_optin" : @"false",
							  @"update_existing" : @"true" };

    // send off the request
    [ self.chimpKit callApiMethod: @"listSubscribe" withParams: params ];
    
    // show some network activity
    [[ UIApplication sharedApplication ] setNetworkActivityIndicatorVisible: YES ];
}

//------------------------------------------------------------------------------

- (void) stopAddressQueue
{
	// close the chimp kit
    if (self.chimpKit != nil)
    {
        self.processingAddressQueue = NO;
        self.chimpKit.delegate = nil;
		self.chimpKit = nil;
    }
	
	// save any remaining addresses
	[ self saveAddresses ];
}

//------------------------------------------------------------------------------
#pragma mark - Serializing addresses
//------------------------------------------------------------------------------

- (void) loadAddresses
{
    NSArray* savedAddresses = [[ NSUserDefaults standardUserDefaults ] objectForKey: @"SavedAddresses" ];
    if (savedAddresses != nil && savedAddresses.count > 0)
    {
        [ self.addresses addObjectsFromArray: savedAddresses ];
    }
}

//------------------------------------------------------------------------------

- (void) saveAddresses
{
    if (self.addresses != nil && self.addresses.count > 0)
    {
        [[ NSUserDefaults standardUserDefaults ] setObject: self.addresses forKey: @"SavedAddresses" ];
		[[ NSUserDefaults standardUserDefaults ] synchronize ];
    }
    
    else
    {
        [[ NSUserDefaults standardUserDefaults ] setObject: nil forKey: @"SavedAddresses" ];
		[[ NSUserDefaults standardUserDefaults ] synchronize ];
    }
}

//------------------------------------------------------------------------------
#pragma mark - ChimpKitDelegate
//------------------------------------------------------------------------------

- (void) ckRequestSucceeded: (ChimpKit*) ckRequest
{
    // mark as not processing
    self.processingAddressQueue = NO;
    
    // add the address to the processed list
    [ self.processedAddresses addObject: self.addresses.lastObject ];
    
    // remove the last address
	// remember that the address are processed last to first
    [ self.addresses removeLastObject ];
    
    // update the table
    NSIndexPath* path = [ NSIndexPath indexPathForRow: self.addresses.count inSection: 0 ];
    NSArray* paths = [ NSArray arrayWithObject: path ];
    [ self.tableView deleteRowsAtIndexPaths: paths withRowAnimation: UITableViewRowAnimationFade ];
    
    // process the next item
    [ self processAddressQueue ];
}

//------------------------------------------------------------------------------

- (void) ckRequestFailed: (ChimpKit*) ckRequest andError: (NSError*) error
{
	// dump out the error
	NSLog(@"ChimpKit request failed: %@", error.debugDescription);

    // mark as not processing
    self.processingAddressQueue = NO;
    
    // stop network activity
    [[ UIApplication sharedApplication ] setNetworkActivityIndicatorVisible: NO ];
}

//------------------------------------------------------------------------------
#pragma mark - UITextFieldDelegate
//------------------------------------------------------------------------------

- (void) alertView: (UIAlertView*) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
    // YES, join mailing list
	if (buttonIndex == 1)
    {
        // add the address to the queue and reload the table
        [ self.addresses insertObject: self.addressField.text atIndex: 0 ];
        NSIndexPath* indexPath = [ NSIndexPath indexPathForRow: 0 inSection: 0 ];
        NSArray* indexPaths = [ NSArray arrayWithObject: indexPath ];
        [ self.tableView insertRowsAtIndexPaths: indexPaths withRowAnimation: UITableViewRowAnimationTop ];
        
        // start the mailchimp queue processor
        [ self startAddressQueue ];
        
        // clear the address field
        self.addressField.text = nil;
		
		// save all the addresses
		[ self saveAddresses ];
    }
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource
//------------------------------------------------------------------------------

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.addresses.count;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) tableView: (UITableView*) tableView cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
    // dequeue a cell if possible
    UITableViewCell* cell = [ tableView dequeueReusableCellWithIdentifier: @"QueuedAddressTableViewCell" ];
    
    // otherwise create a new cell
    if (cell == nil)
    {
        cell = [[ UITableViewCell alloc ] initWithStyle: UITableViewCellStyleDefault
										reuseIdentifier: @"QueuedAddressTableViewCell" ];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [ UIColor darkGrayColor ];
    }

    // fill in the email address
    cell.textLabel.text = self.addresses[ indexPath.row ];

    // done
    return cell;
}

//------------------------------------------------------------------------------
#pragma mark - UITextFieldDelegate
//------------------------------------------------------------------------------

- (void) textFieldDidEndEditing: (UITextField*) textField
{
    // always clear the text field when done editing
    textField.text = nil;
}

//------------------------------------------------------------------------------

- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    // make sure the address has not recently been added
    // shake the textfield and show the warning
    if ([ self isEmailAddress: textField.text ] == NO ||
        [ self.addresses containsObject: textField.text ] ||
        [ self.processedAddresses containsObject: textField.text ])
    {
        [ self shakeView: textField ];
        return NO;
    }
    
    // prompt to confirm joining the list
    NSString* message = [ NSString stringWithFormat: @"By tapping 'Join' you are confirming that '%@' should be subscribed to this email list.", textField.text ];
    UIAlertView* alertView = [[ UIAlertView alloc ] initWithTitle: @"Confirm Subscription"
														  message: message
														 delegate: self
												cancelButtonTitle: @"Cancel"
												otherButtonTitles: @"Join", nil ];
    [ alertView show ];
    
    // done
    return YES;
}

//------------------------------------------------------------------------------

@end
