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

#import "HistorySearchViewController.h"
#import "EmployeeLoginStore.h"

@interface HistorySearchViewController ()

@property (strong , nonatomic) IBOutlet UITextField *startDateTextField;
@property (strong , nonatomic) IBOutlet UITextField *endDateTextField;

@property (strong, nonatomic) IBOutlet UIButton *btnSubmit;

@property (strong , nonatomic)  NSDate *endDate;
@property (strong , nonatomic)  NSDate *startDate;
@property (strong, nonatomic) UIDatePicker *datePicker;

@end

@implementation HistorySearchViewController
@synthesize startDateTextField;
@synthesize endDateTextField;
@synthesize btnSubmit;
@synthesize datePicker;
@synthesize startDate;
@synthesize endDate;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize a date picker and its mode
    datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    
    [self.startDateTextField setInputView:datePicker];
    [self.endDateTextField setInputView:datePicker];
    
    // Style the button with lightGray rounded edges
    btnSubmit.layer.cornerRadius = 8.0f;
    btnSubmit.layer.borderWidth = 1;
    btnSubmit.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

-(IBAction)setStartDate:(id)sender
{
    // Format date
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    // Get date from picker
    startDate = [datePicker date];
    
    // Set text field
    self.startDateTextField.text = [dateFormatter stringFromDate:startDate];
    
}

-(IBAction)setEndDate:(id)sender
{
    // Format
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    // Get date
    endDate = [datePicker date];
    
    // Set date field
    self.endDateTextField.text = [dateFormatter stringFromDate:endDate];
}

-(IBAction)submitButton:(id)sender
{
    // Check if fields are blank
    if([self.startDateTextField.text isEqualToString:@""] || [self.endDateTextField.text isEqualToString:@""]) {
        UIAlertView *badInputs = [[UIAlertView alloc] initWithTitle:@"Unacceptable Values"
                                                            message:@"Please select a start and end date" delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [badInputs show];
    } else { // End startdate enddate to employeeLoginStore to do a search based on those variables, and return true if a result is found
        if ([[EmployeeLoginStore sharedStore] setAllLoginsBySearch:startDate and:endDate]== true) {
            [self performSegueWithIdentifier:@"go_to_search_results" sender:self];
        } else {
            UIAlertView *noResults = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                                message:@"No results found" delegate:self
                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [noResults show];
        }
    }
}

@end
