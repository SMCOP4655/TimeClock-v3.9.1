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

#import "LoginViewController.h"
#import "TCEmployeeStore.h"
#import "TCEmployees.h"
#import "EmployeeLogins.h"
#import "EmployeeLoginStore.h"
#import "ClockInViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *employeeIdNumberField;
@property (weak, nonatomic) IBOutlet UITextField *employeeLastFourField;
@property (strong, nonatomic) NSString * idNumber;
@property (strong, nonatomic) NSString * lastFourSSN;

@property (weak, nonatomic) IBOutlet UIButton *btnLogin;

@end

@implementation LoginViewController
@synthesize idNumber;
@synthesize lastFourSSN;
@synthesize employeeIdNumberField;
@synthesize employeeLastFourField;
@synthesize btnLogin;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    employeeIdNumberField.delegate = self;
    employeeLastFourField.delegate = self;
    
    // Style the button with lightGray rounded edges
    btnLogin.layer.cornerRadius = 8.0f;
    btnLogin.layer.borderWidth = 1;
    btnLogin.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    if ([[TCEmployeeStore sharedStore] allEmployees] <= 0)
    {
        [[TCEmployeeStore sharedStore]createAdmin];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.employeeIdNumberField) {
        // Keyboard's Next button takes you to next textField
        [self.employeeLastFourField becomeFirstResponder];
    } else if (textField == self.employeeLastFourField) {
        // Keyboard's Done button dismisses keyboard
        [textField resignFirstResponder];
        // and 'presses' the Log in button
        [btnLogin sendActionsForControlEvents: UIControlEventTouchUpInside];
    }
    return YES;
}

// Dismiss keyboard when the screen is touched elsewhere
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (IBAction)logInOrOut:(id)sender
{

    idNumber = employeeIdNumberField.text;
    lastFourSSN = employeeLastFourField.text;
    
    //verify method returns true if id number and last four ssn matches one of the employees,
    //if true, if pushes the clock in view 
    if ([[TCEmployeeStore sharedStore] verifyAndSetLoggedInEmployeeWithID:idNumber and:lastFourSSN]) {
        [self performSegueWithIdentifier:@"Login_Successful" sender:self];
    } else {
        UIAlertView *loginFail = [[UIAlertView alloc] initWithTitle:@"Incorrect Login"
                                                            message:@"Invalid Employee ID and/or Password"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [loginFail show];
    }
}

@end
