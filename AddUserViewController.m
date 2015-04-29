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

#import "AddUserViewController.h"
#import "LoginViewController.h"
#import "EmployeeInputViewController.h"
#import "TCEmployeeStore.h"
#import "TCEmployees.h"
#import "TCEmployeeCell.h"
#import "TCImageStore.h"
#import "TCImageViewController.h"

@interface AddUserViewController () <UIPopoverControllerDelegate, UIDataSourceModelAssociation>

@property (nonatomic, strong) UIPopoverController *imagePopover;

@end

@implementation AddUserViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)path
                                                            coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

- (instancetype)init
{
    // Call the superclass's designated initializer
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
      self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(updateTableViewForDynamicTypeSize)
                  name:UIContentSizeCategoryDidChangeNotification
                 object:nil];
    }
   return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
     //Load the NIB file
     UINib *nib = [UINib nibWithNibName:@"TCEmployeeCell" bundle:nil];
    
     //Register this NIB, which contains the cell
    [self.tableView registerNib:nib
         forCellReuseIdentifier:@"TCEmployeeCell"];
    
    self.tableView.restorationIdentifier = @"AddUserViewControllerTableView";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateTableViewForDynamicTypeSize];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.isEditing forKey:@"TableViewIsEditing"];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    self.editing = [coder decodeBoolForKey:@"TableViewIsEditing"];
    
    [super decodeRestorableStateWithCoder:coder];
}

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)path
                                            inView:(UIView *)view
{
    NSString *identifier = nil;
    
    if (path && view) {
        // Return an identifier of the given NSIndexPath,
        // in case next time the data source changes
        TCEmployees *employee = [[TCEmployeeStore sharedStore] allEmployees][path.row];
        identifier = employee.itemKey;
    }
    
    return identifier;
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier
                                                 inView:(UIView *)view
{
    NSIndexPath *indexPath = nil;
    
    if (identifier && view) {
        NSArray *employees = [[TCEmployeeStore sharedStore] allEmployees];
        for (TCEmployees *employee in employees) {
            if ([identifier isEqualToString:employee.itemKey]) {
                NSInteger row = [employees indexOfObjectIdenticalTo:employee];
                indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                break;
            }
        }
    }
    
    return indexPath;
}

- (void)updateTableViewForDynamicTypeSize
{
    static NSDictionary *cellHeightDictionary;
    
    if (!cellHeightDictionary) {
        cellHeightDictionary = @{ UIContentSizeCategoryExtraSmall : @44,
                                  UIContentSizeCategorySmall : @44,
                                  UIContentSizeCategoryMedium : @44,
                                  UIContentSizeCategoryLarge : @44,
                                  UIContentSizeCategoryExtraLarge : @55,
                                  UIContentSizeCategoryExtraExtraLarge : @65,
                                  UIContentSizeCategoryExtraExtraExtraLarge : @75 };
    }
    
    NSString *userSize = [[UIApplication sharedApplication] preferredContentSizeCategory];
    
    NSNumber *cellHeight = cellHeightDictionary[userSize];
   
    [self.tableView setRowHeight:cellHeight.floatValue];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //get count for all employees
    return [[[TCEmployeeStore sharedStore] allEmployees] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get a new or recycled cell
    TCEmployeeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TCEmployeeCell" forIndexPath:indexPath];
    
    // Set the text on the cell with the description of the item
    // that is at the nth index of items, where n = row this cell
    // will appear in on the tableview
    NSArray *employees = [[TCEmployeeStore sharedStore] allEmployees];
    TCEmployees *employee = employees[indexPath.row];
    
 
    cell.firstNameLabel.text = employee.firstName;
    cell.lastNameLabel.text = employee.lastName;
    cell.idNumberLabel.text = employee.idNumber;
    cell.thumbnailView.image = employee.thumbnail;
    
    __weak TCEmployeeCell *weakCell = cell;
    
    cell.actionBlock = ^{
        NSLog(@"Going to show image for %@", employee);
        
        TCEmployeeCell *strongCell = weakCell;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            NSString *itemKey = employee.itemKey;
            // If there is no image, we don't need to display anything
            UIImage *img = [[TCImageStore sharedStore] imageForKey:itemKey];
            if (!img) {
                return; }
            // Make a rectangle for the frame of the thumbnail relative to
            // our table view
            CGRect rect = [self.view convertRect:strongCell.thumbnailView.bounds
                                        fromView:strongCell.thumbnailView];
           
            // Create a new TCImageViewController and set its image
           
            
            TCImageViewController *ivc = [[TCImageViewController alloc] init];
            ivc.image = img;
            // Present a 600x600 popover from the rect
            self.imagePopover = [[UIPopoverController alloc]
                                 initWithContentViewController:ivc];
            self.imagePopover.delegate = self;
            self.imagePopover.popoverContentSize = CGSizeMake(600, 600);
            [self.imagePopover presentPopoverFromRect:rect
                                               inView:self.view
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
        }
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //create instance of employee input controller for a previously created  employee
    EmployeeInputViewController *EmployeeInput= [[EmployeeInputViewController alloc] initForNewEmployee:NO];
    
    NSArray *employees = [[TCEmployeeStore sharedStore] allEmployees];
    TCEmployees *selectedEmployee = employees[indexPath.row];
    
    // Give employee input  controller a pointer to the item object in row
    EmployeeInput.employee = selectedEmployee;
  
    [self presentViewController:EmployeeInput animated:YES completion:NULL];
}

- (void)tableView:(UITableView *)tableView
  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
   forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If the table view is asking to commit a delete command...remove employee..
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSArray *employees = [[TCEmployeeStore sharedStore] allEmployees];
        TCEmployees *employee = employees[indexPath.row];
        [[TCEmployeeStore sharedStore] removeItem:employee];
        
        // Also remove that row from the table view with an animation
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (IBAction)addNewItem:(id)sender
{
    //create a new employee
    TCEmployees *newEmployee = [[TCEmployeeStore sharedStore] createItem];
    
    //create an instance of the employeeInputViewcController for a new employee
    EmployeeInputViewController *EmployeeInput = [[EmployeeInputViewController alloc] initForNewEmployee:YES];
    
    //send that instance the newly created employee
    EmployeeInput.employee = newEmployee;
    
    //reload table data once the employeeInput view dismisses
    EmployeeInput.dismissBlock = ^{
        [self.tableView reloadData];
    };
    
    //initialize and load navigation
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:EmployeeInput];
    navController.restorationIdentifier = NSStringFromClass([navController class]);
    
    [self presentViewController:navController animated:YES completion:NULL];
}

// Log out of application
- (IBAction)logOut:(id)sender
{
    LoginViewController *loginVC = (LoginViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"loginNC"];
    [self presentViewController:loginVC animated:YES completion:nil];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePopover = nil;
}

@end
