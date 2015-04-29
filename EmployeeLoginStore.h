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


@class EmployeeLogins;
@class TCEmployees;

@interface EmployeeLoginStore : NSObject

+ (instancetype)sharedStore;

// Create new login
- (EmployeeLogins *)createLoginWithID:(NSString *) idNumber
                                  and:(NSString *) lastFourSSN;

// Remove item
- (void)removeItem:(EmployeeLogins *)item;

// Save, write to disk
- (BOOL)saveChanges;




// Returns all the logins
- (NSArray *)allEmployeesLogins;

// Return an array of logins based on a search
- (NSArray *)allLoginsBySearch;

// Returns al logins for the employee currently logged in
- (NSArray *)allLoginsByEmployee;

// Returns an array of logins based on a start date and end date, this is for the history view
- (BOOL)setAllLoginsBySearch: (NSDate *) startDate
                           and:(NSDate *)endDate;

//set criteria for a search on the all history view
- (BOOL)setAllLoginsBySearchForAllUsers: (NSDate *) startDate
                         and:(NSDate *)endDate
                                    and:(NSString *)fN
                                    and:(NSString * )lN;


// Set which login the user clicks on to bring to the edit page
-(void) setEmployeeLoginForHistoryEdit: (EmployeeLogins *)editLogin;



// Use this method to get the login the user intends to edit
-(EmployeeLogins *) getEmployeeLoginForHistoryEdit;

@end
