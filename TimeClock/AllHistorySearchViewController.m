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

#import "AllHistorySearchViewController.h"
#import "TCEmployeeStore.h"
#import "TCEmployees.h"
#import "EmployeeLoginStore.h"

@interface AllHistorySearchViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource> {
	UIPickerView    *singlePicker;
	NSArray         *pickerDataF;
    NSArray         *pickerDataL;
}

@property (strong, nonatomic) IBOutlet UITextField *startDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *endDateTextField;
@property (strong, nonatomic) IBOutlet UIButton *btnSubmit;

@property (strong , nonatomic) IBOutlet UITextField *firstNameField;
@property (strong , nonatomic) IBOutlet UITextField *lastNameField;

@property (strong, nonatomic) NSMutableArray *arrayEmployeeFName;
@property (strong, nonatomic) NSMutableArray *arrayEmployeeLName;

@property (strong , nonatomic)  NSDate *endDate;
@property (strong , nonatomic)  NSDate *startDate;
@property (strong , nonatomic)  NSString *firstName;
@property (strong , nonatomic)  NSString *lastName;

@property (strong, nonatomic) UIDatePicker *datePicker;

@property (nonatomic, retain) NSArray *pickerDataF;
@property (nonatomic, retain) NSArray *pickerDataL;

@end

@implementation AllHistorySearchViewController

@synthesize startDateTextField;
@synthesize endDateTextField;
@synthesize btnSubmit;
@synthesize datePicker;
@synthesize startDate;
@synthesize endDate;
@synthesize firstName;
@synthesize lastName;
@synthesize firstNameField;
@synthesize lastNameField;
@synthesize arrayEmployeeFName;
@synthesize arrayEmployeeLName;
@synthesize pickerDataF;
@synthesize pickerDataL;

-(void)viewWillAppear
{
    TCEmployees *employee = [[TCEmployeeStore sharedStore]getEmployeeForAllUserSearch];
    firstNameField.text = employee.firstName;
    lastNameField.text = employee.lastName;
}

-(void)viewDidLoad
{
    datePicker = [[UIDatePicker alloc]init];
    datePicker.datePickerMode =UIDatePickerModeDateAndTime;
    
    [self.startDateTextField setInputView:datePicker];
    [self.endDateTextField setInputView:datePicker];
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    self.startDateTextField.text = [dateFormatter stringFromDate:startDate];
    self.endDateTextField.text = [dateFormatter stringFromDate:endDate];
    
    // Style the button with lightGray rounded edges
    btnSubmit.layer.cornerRadius = 8.0f;
    btnSubmit.layer.borderWidth = 1;
    btnSubmit.layer.borderColor = [UIColor lightGrayColor].CGColor;
   
    TCEmployees *employee = [[TCEmployeeStore sharedStore]getEmployeeForAllUserSearch];
    firstNameField.text = employee.firstName;
    lastNameField.text = employee.lastName;
    
    arrayEmployeeFName = [self employeeFName];
    arrayEmployeeLName = [self employeeLName];
}

-(IBAction)setStartDate:(id)sender
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    startDate = [datePicker date];
    
    self.startDateTextField.text = [dateFormatter stringFromDate:startDate];
}

-(IBAction)setEndDate:(id)sender
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    endDate = [datePicker date];
    
    self.endDateTextField.text = [dateFormatter stringFromDate:endDate];
}

-(IBAction)submitButton:(id)sender
{
    firstName = firstNameField.text;
    lastName = lastNameField.text;
    
    if([self.startDateTextField.text isEqualToString:@""] || [self.endDateTextField.text isEqualToString:@""]) {
        UIAlertView *badInputs = [[UIAlertView alloc] initWithTitle:@"Unacceptable Values"
                                                            message:@"Please select a start and end date" delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [badInputs show];
    } else {
        if ([[EmployeeLoginStore sharedStore] setAllLoginsBySearchForAllUsers:startDate and:endDate and:firstName and:lastName]== true)
        {
            [self performSegueWithIdentifier:@"go_to_search_results" sender:self];
        }
        else
        {
            UIAlertView *noResults = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                                message:@"No results found" delegate:self
                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [noResults show];
        }
    }
}

// Fill array with employee First Names
- (NSMutableArray *)employeeFName
{
    arrayEmployeeFName = [[NSMutableArray alloc] init];
    NSArray *arrayF = [[TCEmployeeStore sharedStore] allEmployees];
    for (TCEmployees *employee in arrayF) {
        [arrayEmployeeFName addObject:employee.firstName];
    }
    // Confirm that array is correctly populated
    for (NSUInteger i = 0; i < arrayEmployeeFName.count; i++) {
        //NSLog(@"%@", [arrayEmployeeFName objectAtIndex:i]);
    }
    
    // firstNameField Picker Choices
    NSArray *pickerFName = [[NSArray alloc] initWithArray:arrayEmployeeFName];
    self.pickerDataF = pickerFName;
    self.firstNameField.delegate = self;
    
    return arrayEmployeeFName;
}

// Fill array with employee Last Names
- (NSMutableArray *)employeeLName
{
    arrayEmployeeLName = [[NSMutableArray alloc] init];
    NSArray *arrayL = [[TCEmployeeStore sharedStore] allEmployees];
    for (TCEmployees *employee in arrayL) {
        [arrayEmployeeLName addObject:employee.lastName];
    }
    // Confirm that array is correctly populated
    for (NSUInteger i = 0; i < arrayEmployeeLName.count; i++) {
        //NSLog(@"%@", [arrayEmployeeLName objectAtIndex:i]);
    }
    
    // lastNameField Picker Choices
    NSArray *pickerLName = [[NSArray alloc] initWithArray:arrayEmployeeLName];
    self.pickerDataL = pickerLName;
    self.lastNameField.delegate = self;
    
    return arrayEmployeeLName;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect pickerFrame = CGRectMake(0, 44, 0, 0);
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:pickerFrame];
    
    if (textField.tag == pickerFirst) {
        self.firstNameField.text = [pickerDataF objectAtIndex:0];
        self.firstNameField.inputView = picker;
        picker.tag = pickerFirst;
    }
    if (textField.tag == pickerLast) {
        self.lastNameField.text = [pickerDataL objectAtIndex:0];
        self.lastNameField.inputView = picker;
        picker.tag = pickerLast;
    }
    
    picker.delegate = self;
}

// Dismiss keyboard when the screen is touched elsewhere
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
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
    if (pickerView.tag == pickerFirst)
        return [pickerDataF count];
    
    return [pickerDataL count];
}

#pragma mark Picker Delegate Methods
- (NSString *)pickerView:(UIPickerView *)pickerView
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component
{
    if (pickerView.tag == pickerFirst)
        return [pickerDataF objectAtIndex:row];
    
    return [pickerDataL objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.firstNameField.text = [pickerDataF objectAtIndex:row];
    self.lastNameField.text = [pickerDataL objectAtIndex:row];
}

@end
