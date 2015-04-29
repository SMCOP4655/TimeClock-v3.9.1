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

#import "AllHistoryTableViewController.h"
#import "EmployeeInputViewController.h"
#import "TCEmployeeStore.h"
#import "TCEmployees.h"
#import "TCEmployeeCell.h"
#import "TCImageStore.h"
#import "TCImageViewController.h"
#import "EmployeeLoginStore.h"
#import "EmployeeLogins.h"
#import "LoginHistoryEditViewController.h"

@interface AllHistoryTableViewController () <UIPopoverControllerDelegate, UIDataSourceModelAssociation>

@property (nonatomic, strong) UIPopoverController *imagePopover;

@end

@implementation AllHistoryTableViewController


+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)path
                                                            coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

-(instancetype)init
{
    self = [super init];
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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView reloadData];
    
    //Load the NIB file
    UINib *nib = [UINib nibWithNibName:@"TCEmployeeCell" bundle:nil];
    
    //Register this NIB, which contains the cell
    [self.tableView registerNib:nib
         forCellReuseIdentifier:@"TCEmployeeCell"];
    
    self.tableView.restorationIdentifier = @"AllHistoryTableViewController";
    
    //[[EmployeeLoginStore sharedStore] allEmployeesLogins];
    //[self.tableView reloadData];
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
        EmployeeLogins *employeeLogin = [[EmployeeLoginStore sharedStore] allEmployeesLogins][path.row];
        identifier = employeeLogin.itemKey;
    }
    return identifier;
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier
                                                 inView:(UIView *)view
{
    NSIndexPath *indexPath = nil;
    
    if (identifier && view) {
        NSArray *employeeLogins = [[EmployeeLoginStore sharedStore] allEmployeesLogins];
        
        for (EmployeeLogins *employeeLogin in employeeLogins) {
            if ([identifier isEqualToString:employeeLogin.itemKey]) {
                NSInteger row = [employeeLogins indexOfObjectIdenticalTo:employeeLogin];
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
    return [[[EmployeeLoginStore sharedStore] allEmployeesLogins] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get a new or recycled cell
    TCEmployeeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TCEmployeeCell" forIndexPath:indexPath];
    
    // Employees cannot interact with history cells
    TCEmployees *loggedInUser = [[TCEmployeeStore sharedStore] getLoggedInEmployee];
    
    if([loggedInUser.role isEqualToString:@"Employee"]) {
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
    
    // Set the text on the cell with the description of the item
    // that is at the nth index of items, where n = row this cell
    // will appear in on the tableview
    NSArray *employeeLogins = [[EmployeeLoginStore sharedStore] allEmployeesLogins];
    EmployeeLogins *employeeLogin = employeeLogins[indexPath.row];
    
    // You need a NSDateFormatter that will turn a date into a simple date string
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    
    //assign attibutes to custom cell
    cell.firstNameLabel.text = employeeLogin.firstName;
    cell.lastNameLabel.text = employeeLogin.lastName;
    cell.signInDateLabel.text = [dateFormatter stringFromDate:employeeLogin.signIn];
    cell.idNumberLabel.text = employeeLogin.idNumber;
    cell.thumbnailView.image = employeeLogin.thumbnail;
    
    __weak TCEmployeeCell *weakCell = cell;
    
    cell.actionBlock = ^{
        NSLog(@"Going to show image for %@", employeeLogin);
        
        TCEmployeeCell *strongCell = weakCell;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            NSString *itemKey = employeeLogin.itemKey;
            // If there is no image, we don't need to display anything
            UIImage *img = [[TCImageStore sharedStore] imageForKey:itemKey];
            if (!img) {
                return;
            }
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
    TCEmployees *loggedInUser = [[TCEmployeeStore sharedStore] getLoggedInEmployee];
    
    if([loggedInUser.role isEqualToString:@"Supervisor"] || [loggedInUser.role isEqualToString:@"Admin"]) {
        NSArray *employeeLogins = [[EmployeeLoginStore sharedStore] allEmployeesLogins];
        
        EmployeeLogins *selectedEmployeeLogin = employeeLogins[indexPath.row];
        
        NSLog(@"selected employee %@", selectedEmployeeLogin);
        
        //set employee for the edit page 
        [[EmployeeLoginStore sharedStore]setEmployeeLoginForHistoryEdit:selectedEmployeeLogin];
        
        [self performSegueWithIdentifier:@"edit_login_history" sender:self];
    }
}

// Only Supervisor role can swipe entries
-(BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCEmployees *loggedInUser = [[TCEmployeeStore sharedStore] getLoggedInEmployee];
    
    if([loggedInUser.role isEqualToString:@"Supervisor"] || [loggedInUser.role isEqualToString:@"Admin"]) {
        return YES;
    }
    return NO;
}

// Only Supervisor role can delete entries
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCEmployees *loggedInUser = [[TCEmployeeStore sharedStore] getLoggedInEmployee];
    
    if([loggedInUser.role isEqualToString:@"Supervisor"] || [loggedInUser.role isEqualToString:@"Admin"])
        {
        // If the table view is asking to commit a delete command...
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSArray *employeeLogins = [[EmployeeLoginStore sharedStore] allEmployeesLogins];
            EmployeeLogins *employeeLogin = employeeLogins[indexPath.row];
            
            [[EmployeeLoginStore sharedStore] removeItem:employeeLogin];
            
            //Also remove that row from the table view with an animation
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

-(void)refreshTable
{
    [[EmployeeLoginStore sharedStore] allEmployeesLogins];
    [self.tableView reloadData];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.imagePopover = nil;
}

@end
