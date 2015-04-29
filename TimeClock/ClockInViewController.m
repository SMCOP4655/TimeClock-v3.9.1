/*Copyright (c) <year> <copyright holders>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 Written by: Steve Pierre-Louis and Adrian Sanchez
 Spring 2015, Florida International University, COP 4655 Mobile Application Development
 
 */

#import "ClockInViewController.h"
#import "TCEmployees.h"
#import "TCEmployeeStore.h"
#import "EmployeeLogins.h"
#import "EmployeeLoginStore.h"
#import "TCImageStore.h"
#import "HistoryViewController.h"

@interface ClockInViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
UITextFieldDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) UIPopoverController *imagePickerPopover;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *idNumberField;
@property (weak, nonatomic) IBOutlet UITextField *roleField;

@property (weak, nonatomic) IBOutlet UITextField *statusField;

@property (weak, nonatomic) IBOutlet UITextField *signInDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *sigOutDateLabel;

@property (weak, nonatomic) NSDate *signInDate;
@property (weak, nonatomic) NSDate *signOutdate;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@property IBOutlet UILabel *lblLiveDate;
@property IBOutlet UILabel *lblLiveTime;
@property IBOutlet UIButton *btnClockIn;
@property IBOutlet UIButton *btnClockOut;

@property NSDate *currentTime;
@property NSTimer *updateTimer;

- (IBAction)takePicture:(id)sender;

@end

@implementation ClockInViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)path
                                                            coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.employeeLogin.itemKey
                 forKey:@"employeeLogin.itemKey"];
    
    // Save changes into item
    self.employeeLogin.firstName = self.firstNameField.text;
    self.employeeLogin.lastName = self.lastNameField.text;
    self.employeeLogin.idNumber = self.idNumberField.text;
    self.employeeLogin.role = self.roleField.text;
    self.employeeLogin.status = self.statusField.text;
    
    // Have store save changes to disk
    [[EmployeeLoginStore sharedStore] saveChanges];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *itemKey = [coder decodeObjectForKey:@"employeeLogin.itemKey"];
    
    for (EmployeeLogins *employeeLogin in [[EmployeeLoginStore sharedStore] allEmployeesLogins]) {
        if ([itemKey isEqualToString:employeeLogin.itemKey]) {
            self.employeeLogin = employeeLogin;
            break;
        }
    }
    [super decodeRestorableStateWithCoder:coder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create emloyee and employee login objects
    self.currentUser  = [[TCEmployeeStore sharedStore] getLoggedInEmployee];
    self.employeeLogin = [[EmployeeLoginStore sharedStore]createLoginWithID:self.currentUser.idNumber
                                                  and:self.currentUser.lastFourSSN];
    
    // You need a NSDateFormatter that will turn a date into a simple date string
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    // Set fields
    self.firstNameField.text = self.employeeLogin.firstName;
    self.lastNameField.text = self.employeeLogin.lastName;
    self.idNumberField.text = self.employeeLogin.idNumber;
    self.roleField.text = self.employeeLogin.role;
    self.statusField.text = self.employeeLogin.status;
    
    self.signInDateLabel.text = [dateFormatter stringFromDate:self.employeeLogin.signIn];
    self.sigOutDateLabel.text = [dateFormatter stringFromDate:self.employeeLogin.signOut];
   
    
    //check if employee has an
    NSString *itemKey = self.employeeLogin.itemKey;
    if (itemKey) {
        // Get image for image key from the image store
        UIImage *imageToDisplay = [[TCImageStore sharedStore] imageForKey:itemKey];
        
        // Use that image to put on the screen in imageView
        self.imageView.image = imageToDisplay;
    } else {
        // Clear the imageView
        self.imageView.image = nil;
    }
    
    [self updateTime];
    [self buttonStyle];
    [self clockedInState];
    [self hideShowTab];
}

// Hide or Show Supervisor-only tab(s)
- (void)hideShowTab
{
    
    TCEmployees *loggedInUser = [[TCEmployeeStore sharedStore] getLoggedInEmployee];

    if ([loggedInUser.role isEqualToString:@"Employee"]) {
        NSUInteger removeAllHistoryTab = 2; // Third tab
        NSUInteger removeUsersTab = 2; // Was Fourth tab, now Third tab
        NSMutableArray *controllersToKeep = [NSMutableArray arrayWithArray:self.tabBarController.viewControllers];
        [controllersToKeep removeObjectAtIndex:removeAllHistoryTab];
        [controllersToKeep removeObjectAtIndex:removeUsersTab];
        [self.tabBarController setViewControllers:controllersToKeep animated:YES];
    }
    if ([loggedInUser.role isEqualToString:@"Admin"]) {
        NSUInteger removeTimeClockTab = 0; // First tab
        NSUInteger removeHistoryTab = 0; // Was Second tab, now First tab
        NSUInteger removeAllHistoryTab = 0; // Was Third tab, now First tab
        NSMutableArray *controllersToKeep = [NSMutableArray arrayWithArray:self.tabBarController.viewControllers];
        [controllersToKeep removeObjectAtIndex:removeTimeClockTab];
        [controllersToKeep removeObjectAtIndex:removeAllHistoryTab];
        [controllersToKeep removeObjectAtIndex:removeHistoryTab];
        [self.tabBarController setViewControllers:controllersToKeep animated:YES];
    }
  
}

- (void)viewWillAppear:(BOOL)animated
{
  
}

- (void)viewWillDisappear:(BOOL)animated
{
    
}

- (void)updateTime
{
    [_updateTimer invalidate];
    _updateTimer = nil;
    
    _currentTime = [NSDate date];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateStyle:NSDateFormatterFullStyle];
    _lblLiveDate.text = [timeFormatter stringFromDate:_currentTime];
    
    timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setTimeStyle:NSDateFormatterMediumStyle];
    _lblLiveTime.text = [timeFormatter stringFromDate:_currentTime];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
}

// Style the button with lightGray rounded edges
- (void)buttonStyle
{
    _btnClockIn.layer.cornerRadius = 8.0f;
    _btnClockIn.layer.borderWidth = 1;
    _btnClockIn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    _btnClockOut.layer.cornerRadius = 8.0f;
    _btnClockOut.layer.borderWidth = 1;
    _btnClockOut.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

// Disable buttons based on user status
- (void)clockedInState
{
    EmployeeLogins *employeeLogin = self.employeeLogin;
    
    if ([employeeLogin.status isEqual: @""])
    {
        _btnClockIn.enabled = YES;
        _btnClockOut.alpha = 0.4;
        _btnClockOut.enabled = NO;
        _btnClockIn.alpha = 1;
        _btnClockIn.enabled = YES;
    }
    if ([employeeLogin.status isEqual: @"LOGGED IN"])
    { // If user is clocked in, disable btnClockIn
        _btnClockIn.alpha = 0.4;
        _btnClockIn.enabled = NO;
        _btnClockOut.alpha = 1;
        _btnClockOut.enabled = YES;
    }
    if ([employeeLogin.status isEqual: @"LOGGED OUT"] || [employeeLogin.role isEqualToString:@"Admin"])
    { // If user is not clocked in, disable btnClockOut
        _btnClockIn.enabled = NO;
        _btnClockOut.alpha = 0.4;
        _btnClockOut.enabled = NO;
        _btnClockIn.alpha = 0.4; // 1 is enabled look
    }
}

 -(IBAction)signInButton:(id)sender
{
    EmployeeLogins *employeeLogin = self.employeeLogin;
    
    // Check if there is a picture before allowing sing in
    if (self.employeeLogin.thumbnail ==nil) {
        UIAlertView *noPicture = [[UIAlertView alloc] initWithTitle:@"No Picture"
                                                            message:@"Please take a picture with login" delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
       [noPicture show];
    } else { //if picture, get info from fields and write to disk
        employeeLogin.firstName = self.firstNameField.text;
        employeeLogin.lastName = self.lastNameField.text;
        employeeLogin.role = self.roleField.text;
        employeeLogin.idNumber = self.idNumberField.text;
        employeeLogin.signIn = [NSDate date];
        employeeLogin.status = @"LOGGED IN";
    
        self.statusField.text = employeeLogin.status;
    
        static NSDateFormatter *dateFormatter;
        
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterMediumStyle;
            dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        }

        self.signInDateLabel.text = [dateFormatter stringFromDate:self.employeeLogin.signIn];
        [self clockedInState];
            
        // Write to disk
        [[EmployeeLoginStore sharedStore] saveChanges];
    }
}

 -(IBAction)signOutButton:(id)sender
{
    EmployeeLogins *employeeLogin = self.employeeLogin;
    
    //set status for log out and get current time
    employeeLogin.status = @"LOGGED OUT";
    employeeLogin.signOut = [NSDate date];
    
   [[EmployeeLoginStore sharedStore] saveChanges];
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    //display info
    self.sigOutDateLabel.text = [dateFormatter stringFromDate:self.employeeLogin.signOut];
    self.statusField.text = employeeLogin.status;
    
    //update buttons
    [self clockedInState];
}

- (IBAction)takePicture:(id)sender
{
    if([self.employeeLogin.status isEqualToString:@""])
    {
        if ([self.imagePickerPopover isPopoverVisible]) {
            // If the popover is already up, get rid of it
            [self.imagePickerPopover dismissPopoverAnimated:YES];
            self.imagePickerPopover = nil;
            return;
        }
    
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
        // If the device ahs a camera, take a picture, otherwise,
        // just pick from the photo library
    
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        } else {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
    
        imagePicker.delegate = self;
    
        // Place image picker on the screen
        // Check for iPad device before instantiating the popover controller
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            // Create a new popover controller that will display the imagePicker
            self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
            self.imagePickerPopover.delegate = self;
        
            // Display the popover controller; sender
            // is the camera bar button item
            [self.imagePickerPopover presentPopoverFromBarButtonItem:sender
                                            permittedArrowDirections:UIPopoverArrowDirectionAny
                                                            animated:YES];
        } else {
            [self presentViewController:imagePicker animated:YES completion:NULL];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *oldKey = self.employeeLogin.itemKey;
    
    // Did the item already have an image?
    if (oldKey) {
        // Delete the old image
        [[TCImageStore sharedStore] deleteImageForKey:oldKey];
    }
    
    // Get picked image from info dictionary
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self.employeeLogin setThumbnailFromImage:image];
    
    // Store the image in the TCImageStore for this key
    [[TCImageStore sharedStore] setImage:image forKey:self.employeeLogin.itemKey];
    
    // Put that image onto the screen in our image view
    self.imageView.image = image;
    
    // Do I have a popover?
    if (self.imagePickerPopover) {
        // Dismiss it
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
    } else {
        // Dismiss the modal image picker
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"User dismissed popover");
    self.imagePickerPopover = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
