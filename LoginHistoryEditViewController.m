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

#import "TCImageStore.h"
#import "HistoryViewController.h"
#import "LoginHistoryEditViewController.h"
#import "EmployeeLogins.h"
#import "HistoryViewController.h"
#import "EmployeeLoginStore.h"

@interface LoginHistoryEditViewController () <UITextFieldDelegate>

@property (nonatomic, strong) EmployeeLogins *employeeLogin;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *idNumberField;
@property (weak, nonatomic) IBOutlet UITextField *roleField;

@property (weak, nonatomic) IBOutlet UITextField *signInDateField;
@property (weak, nonatomic) IBOutlet UITextField *signOutDateField;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) UIDatePicker *datePicker;

@property (strong , nonatomic) IBOutlet UIButton *setEndDateButton;
@property (strong , nonatomic) IBOutlet UIButton *setStartDateButton;

@end

@implementation LoginHistoryEditViewController
@synthesize datePicker;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize date picker and mode 
    datePicker = [[UIDatePicker alloc]init];
    datePicker.datePickerMode =UIDatePickerModeDateAndTime;
    
    //get emplyeeLogin for edit, set from a table at row select
    EmployeeLogins *employeeLogin = [[EmployeeLoginStore sharedStore]getEmployeeLoginForHistoryEdit];
    
    //use it to set fields
    [self.signInDateField  setInputView:datePicker];
    [self.signOutDateField setInputView:datePicker];
    
    self.firstNameField.text = employeeLogin.firstName;
    self.lastNameField.text = employeeLogin.lastName;
    self.idNumberField.text = employeeLogin.idNumber;
    self.roleField.text = employeeLogin.role;
    
    // You need a NSDateFormatter that will turn a date into a simple date string
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    self.signInDateField.text = [dateFormatter stringFromDate:employeeLogin.signIn];
    self.signOutDateField.text = [dateFormatter stringFromDate:employeeLogin.signOut];

    NSString *itemKey = employeeLogin.itemKey;
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

- (void)viewWillAppear:(BOOL)animated
{
    
}

-(IBAction)setStartDate:(id)sender
{
    //get emplyeeLogin for edit, set from a table at row select
    EmployeeLogins *employeeLogin = [[EmployeeLoginStore sharedStore]getEmployeeLoginForHistoryEdit];
    
    //format date
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    employeeLogin.signIn = [datePicker date];
    
    //set fields and save changes
    self.signInDateField.text = [dateFormatter stringFromDate:employeeLogin.signIn];
    [[EmployeeLoginStore sharedStore] saveChanges];
    
    [self textFieldShouldReturn:self.signInDateField];
}

-(IBAction)setEndDate:(id)sender
{
    //get emplyeeLogin for edit, set from a table at row select

    EmployeeLogins *employeeLogin = [[EmployeeLoginStore sharedStore]getEmployeeLoginForHistoryEdit];
    
    //format date
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    //set date
    employeeLogin.signOut = [datePicker date];
    
    
    //set date field
    self.signOutDateField.text = [dateFormatter stringFromDate:employeeLogin.signOut];
    
    //save changes
     [[EmployeeLoginStore sharedStore] saveChanges];
   [self textFieldShouldReturn:self.signOutDateField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
