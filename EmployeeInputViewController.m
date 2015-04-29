//
//  EmployeeInputViewController.m
//  TimeClock
//
//  Created by Mimi on 4/22/15.
//  Copyright (c) 2015 FIU. All rights reserved.
//

#import "EmployeeInputViewController.h"
#import "TCEmployees.h"
#import "TCEmployeeStore.h"
#import "TCImageStore.h"


@interface EmployeeInputViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
UITextFieldDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource> {
	UIPickerView    *singlePicker;
	NSArray         *pickerData;
}

@property (nonatomic, strong) UIPopoverController *imagePickerPopover;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *idNumberField;
@property (weak, nonatomic) IBOutlet UITextField *lastFourSSNField;
@property (weak, nonatomic) IBOutlet UITextField *roleField;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *idNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastFourSSNLabel;
@property (weak, nonatomic) IBOutlet UILabel *roleLabel;

@property (nonatomic, retain) NSArray *pickerData;

- (IBAction)takePicture:(id)sender;
- (IBAction)saveButton:(id)sender;


@end

@implementation EmployeeInputViewController

@synthesize pickerData;

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)path
                                                           coder:(NSCoder *)coder
{

    BOOL isNew = NO;
    return [[self alloc] initForNewEmployee:(BOOL)isNew];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.employee.itemKey
                 forKey:@"employee.itemKey"];
    
    // Save changes into item
    self.employee.firstName = self.firstNameField.text;
    self.employee.lastName = self.lastNameField.text;
    self.employee.idNumber = self.idNumberField.text;
    self.employee.lastFourSSN = self.lastFourSSNField.text;
    self.employee.role = self.roleField.text;
    
    // Have store save changes to disk
    [[TCEmployeeStore sharedStore] saveChanges];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *itemKey = [coder decodeObjectForKey:@"employee.itemKey"];
    
    for (TCEmployees *employee in [[TCEmployeeStore sharedStore] allEmployees]) {
        if ([itemKey isEqualToString:employee.itemKey]) {
            self.employee = employee;
            break;
        }
    }
    
    [super decodeRestorableStateWithCoder:coder];
}

//custom init method to display buttons
- (instancetype)initForNewEmployee:(BOOL)isNew;
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        if (isNew) {
        
            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                      target:self
                                                                                      action:@selector(save:)];
            self.navigationItem.rightBarButtonItem = doneItem;
            
            UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancel:)];
            self.navigationItem.leftBarButtonItem = cancelItem;
        }
        
        
    }
    
    return self;
}


//ensure correct init method is being called
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    @throw [NSException exceptionWithName:@"Wrong initializer"
                                   reason:@"Use initForNewItem:"
                                 userInfo:nil];
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    // roleField Picker Choices
    NSArray *array = [[NSArray alloc] initWithObjects:@"Employee", @"Supervisor", nil];
    self.pickerData = array;
    
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;
    self.idNumberField.delegate = self;
    self.lastFourSSNField.delegate = self;
    self.roleField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //display employee info to text fields
    TCEmployees *employee = self.employee;
    
    self.firstNameField.text = employee.firstName;
    self.lastNameField.text = employee.lastName;
    self.idNumberField.text = employee.idNumber;
    self.roleField.text = employee.role;
    self.lastFourSSNField.text = employee.lastFourSSN;
    
    // You need a NSDateFormatter that will turn a date into a simple date string
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    
    // Use filtered NSDate object to set dateLabel contents
    self.dateLabel.text = [dateFormatter stringFromDate:employee.dateCreated];
    
    //check to see if employee has an image key
    NSString *itemKey = self.employee.itemKey;
    if (itemKey) {
        // Get image for image key from the image store
        UIImage *imageToDisplay = [[TCImageStore sharedStore] imageForKey:itemKey];
        
        // Use that image to put on the screen in imageView
        self.imageView.image = imageToDisplay;
    } else {
        // Clear the imageView
        self.imageView.image = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Clear first responder
    [self.view endEditing:YES];
    
    // save changes to item
    TCEmployees *employee = self.employee;
    
    employee.firstName = self.firstNameField.text;
    employee.lastName = self.lastNameField.text;
    employee.lastFourSSN = self.lastFourSSNField.text;
    employee.role = self.roleField.text;
    employee.idNumber = self.idNumberField.text;
    
    [[TCEmployeeStore sharedStore] saveChanges];
}



- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect pickerFrame = CGRectMake(0, 44, 0, 0);
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:pickerFrame];
    
    self.roleField.text = [pickerData objectAtIndex:0];
    self.roleField.inputView = picker;
    picker.delegate = self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.roleField resignFirstResponder];
}

#pragma mark -
#pragma mark Picker Data Source Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [pickerData count];
}

#pragma mark Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView *)pickerView
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component
{
    return [pickerData objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.roleField.text = [pickerData objectAtIndex:row];
}



//dismiss view
- (void)save:(id)sender
{
    if ([self fieldsAreEmpty]) {
        UIAlertView *emptyField = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Please do not leave any fields blank"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [emptyField show];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:self.dismissBlock];
    }
}

- (void)cancel:(id)sender
{
    // If the user cancelled, then remove the employee from  the store
    [[TCEmployeeStore sharedStore] removeItem:self.employee];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

// Checks if the New User fields are empty
- (BOOL)fieldsAreEmpty
{
    // NSArray of UITextField to cycle through to check if empty
    NSArray *newUserFields = [[NSArray alloc] initWithObjects:self.firstNameField, self.lastNameField, self.idNumberField, self.lastFourSSNField, self.roleField, nil];
    // NSArray of UILabel to change the corresponding label textColor to red if empty
    NSArray *newUserLabels = [[NSArray alloc] initWithObjects:self.firstNameLabel, self.lastNameLabel, self.idNumberLabel, self.lastFourSSNLabel, self.roleLabel, nil];
    
    BOOL isFieldEmpty = NO;
    
    for (NSInteger i = 0; i < newUserFields.count; i++) {
        UITextField *textField = (UITextField *)[newUserFields objectAtIndex:i];
        UILabel *label = (UILabel *)[newUserLabels objectAtIndex:i];

        if ([textField.text isEqualToString:@""]) { // if textField is empty
            label.textColor = [UIColor redColor]; // set corresponding label textColor to red
            isFieldEmpty = YES;
        } else { // textField is not empty
            label.textColor = [UIColor blackColor];
        }
    }
    
    return isFieldEmpty;
}

-(IBAction)saveButton:(UIButton *)sender;
{
    if ([self fieldsAreEmpty]) {
        UIAlertView *emptyField = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Please do not leave any fields blank"
                                                            delegate:self
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [emptyField show];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:self.dismissBlock];
    }
}

- (IBAction)takePicture:(id)sender
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



- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *oldKey = self.employee.itemKey;
    
    // Did the item already have an image?
    if (oldKey) {
        // Delete the old image
        [[TCImageStore sharedStore] deleteImageForKey:oldKey];
    }
    
    // Get picked image from info dictionary
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self.employee setThumbnailFromImage:image];
    
    // Store the image in the TCImageStore for this key
    [[TCImageStore sharedStore] setImage:image forKey:self.employee.itemKey];
    
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
    // Keyboard's Next button takes you to next textField
    if (textField == self.firstNameField) {
        [self.lastNameField becomeFirstResponder];
    }
    if (textField == self.lastNameField) {
        [self.idNumberField becomeFirstResponder];
    }
    if (textField == self.idNumberField) {
        [self.lastFourSSNField becomeFirstResponder];
    }
    if (textField == self.lastFourSSNField) {
        [self.roleField becomeFirstResponder];
    }
    
    [textField resignFirstResponder];
    
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
