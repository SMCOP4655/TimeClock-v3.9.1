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

#import "EmployeeLoginStore.h"
#import "EmployeeLogins.h"
#import "TCEmployees.h"
#import "TCEmployeeStore.h"
#import "TCImageStore.h"

@import CoreData;

@interface EmployeeLoginStore ()

@property (nonatomic) NSMutableArray *privateItems;


@property (nonatomic) NSArray *allLoginsByEmployee;
@property (nonatomic) NSArray *allLoginsBySearch;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, readonly) EmployeeLogins *historyEditLogInObject;


@end

@implementation EmployeeLoginStore

@synthesize  allLoginsByEmployee;
@synthesize allLoginsBySearch;
@synthesize historyEditLogInObject;


+ (instancetype)sharedStore
{
    static EmployeeLoginStore *sharedStore;
    
    if (!sharedStore) {
        sharedStore = [[self alloc] initPrivate];
    }
    
    return sharedStore;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[EmployeeLoginStore sharedStore]"
                                 userInfo:nil];
    return nil;
}


- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // Read in TimClock.xcdatamodeld
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        // Where does the SQLite file go?
        NSString *path = self.itemArchivePath;
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        
        NSError *error;
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:nil
                                       error:&error]) {
            @throw [NSException exceptionWithName:@"OpenFailure"
                                           reason:[error localizedDescription]
                                         userInfo:nil];
        }
        
        // Create the managed object context
        _context = [[NSManagedObjectContext alloc] init];
        _context.persistentStoreCoordinator = psc;
        
        [self loadAllLogins];
        // [self loadAllEmployeeBasedLogins];
    }
    
    return self;
}

- (NSString *)itemArchivePath
{
    // Make sure that the first argument is NSDocumentDirectory
    // and not NSDocumentationDirectory
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // Get the one document directory from that list
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:@"store.data"];
}

- (BOOL)saveChanges
{
    NSError *error;
    BOOL successful = [self.context save:&error];
    if (!successful) {
        NSLog(@"Error saving: %@", [error localizedDescription]);
    }
    
    return successful;
}

- (void)loadAllLogins
{
    //perfrom fecth for all logins in database and save results into designanted array
    if (!self.privateItems) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *e = [NSEntityDescription entityForName:@"EmployeeLogins"
                                             inManagedObjectContext:self.context];
        
        request.entity = e;
        
        NSSortDescriptor *signInSort = [NSSortDescriptor sortDescriptorWithKey:@"signIn" ascending:NO];
        
        request.sortDescriptors = @[signInSort];
        
        NSError *error;
        NSArray *result = [self.context executeFetchRequest:request error:&error];
        if (!result) {
            [NSException raise:@"Fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        self.privateItems = [[NSMutableArray alloc] initWithArray:result];
    }
}



- (NSArray *)allEmployeesLogins

{

    NSString * status = @"LOGGED OUT";
    
    //filter all employee logins with status search, employees may have actve sessions, we only
    //need completed sessions
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(status like[cd] %@)",status];
    
    
    NSArray * all  = [[self.privateItems copy] filteredArrayUsingPredicate:p];
    
    return all;
}


//filter logins by employee
- (NSArray *)allLoginsByEmployee
{
    //get logged in employee
    TCEmployees * loggedInEmployee = [[TCEmployeeStore sharedStore]getLoggedInEmployee];
    
    //set search variables and predicate
    NSString * status = @"LOGGED OUT";
    NSString * identificationNumber = loggedInEmployee.idNumber;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(idNumber like[cd] %@) AND (status like[cd] %@)",identificationNumber,status];
   
    //get all logins
    allLoginsByEmployee = [self.privateItems copy] ;
    
    //then filter it with predicate
    allLoginsByEmployee = [allLoginsByEmployee filteredArrayUsingPredicate:p];
    
    //return results
    return allLoginsByEmployee;
}



- (EmployeeLogins *)createLoginWithID:(NSString *) idNumber
                                  and:(NSString *) lastFourSSN
{
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    //insert new object
    NSEntityDescription *e = [NSEntityDescription entityForName:@"EmployeeLogins"
                                         inManagedObjectContext:self.context];
    request.entity = e;
    
    //get logged in employee
    TCEmployees * loggedInEmployee = [[TCEmployeeStore sharedStore]getLoggedInEmployee];
    
    //employee login object
    EmployeeLogins * employeeLoginObject;
    
    //set status  and predicate  for search
    NSString * status = @"LOGGED IN";
    NSString * identificationNumber = loggedInEmployee.idNumber;
    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(idNumber like[cd] %@) AND (status like[cd] %@)",identificationNumber,status];
    
    [request setPredicate:p];
    
    NSError *error;
    
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    
    //if result is 0 then that means there is no active sessions for this employee, so use login object to create one and add its attributes
    if ([result count]<= 0) {
      
        employeeLoginObject = [NSEntityDescription insertNewObjectForEntityForName:@"EmployeeLogins"
                                                            inManagedObjectContext:self.context];
        employeeLoginObject.firstName = loggedInEmployee.firstName;
        employeeLoginObject.lastName = loggedInEmployee.lastName;
        employeeLoginObject.lastFourSSN = loggedInEmployee.lastFourSSN;
        employeeLoginObject.idNumber = loggedInEmployee.idNumber;
        employeeLoginObject.role = loggedInEmployee.role;
        employeeLoginObject.status = @"";
    
        [self.privateItems addObject:employeeLoginObject];
    }
    //else , and active session is found, can only be one possible
    else {
        employeeLoginObject  = result[0];
        
      
    }
    
    return employeeLoginObject;
}

- (void)removeItem:(EmployeeLogins *)employeeLogin
{
    //if login has a image key, use it to delete its image
    NSString *key = employeeLogin.itemKey;
    if (key) {
        [[TCImageStore sharedStore] deleteImageForKey:key];
    }
    
    [self.context deleteObject:employeeLogin];
    [self.privateItems removeObjectIdenticalTo:employeeLogin];
}

// This method is used to set a login object that can be retrieved to edit on an edit page
-(void) setEmployeeLoginForHistoryEdit: (EmployeeLogins *)editLogin
{
    historyEditLogInObject = editLogin;
}

// This method is used to retrive a login object intended for editing
-(EmployeeLogins *) getEmployeeLoginForHistoryEdit;
{
    return historyEditLogInObject;
}


- (BOOL)setAllLoginsBySearch:(NSDate *)startDate
                         and:(NSDate *)endDate
{
    BOOL exist;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    //fetch
    NSEntityDescription *e = [NSEntityDescription entityForName:@"EmployeeLogins"
                                         inManagedObjectContext:self.context];
    request.entity = e;
    
    TCEmployees * loggedInEmployee = [[TCEmployeeStore sharedStore]getLoggedInEmployee];
   
    //get id number of loggged in user
    NSString * idNumber = loggedInEmployee.idNumber;
    
    //logins should be filtered with signIn being between start and end date , also being for currently logged in employee
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(signIn >= %@) AND (signIn <= %@) AND (idNumber like[cd] %@)",startDate,endDate,idNumber];
    
    //set predicate
    [request setPredicate:p];
    
    NSError *error;
    
    //get results of fetch
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    
    //if found anything based on filter
    if ([result count]<= 0) {
               exist = FALSE;
    } else {
        //place into designated array
        allLoginsBySearch = result;
        
        exist = true;
    }
    
    return exist;
}

//this is for the All History page, uses these variables to filter
- (BOOL)setAllLoginsBySearchForAllUsers:(NSDate *)startDate
                                    and:(NSDate *)endDate
                                    and:(NSString *)fN
                                    and:(NSString *)lN
{

    BOOL exist;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
   //fetch
    NSEntityDescription *e = [NSEntityDescription entityForName:@"EmployeeLogins"
                                         inManagedObjectContext:self.context];
    request.entity = e;
    
   
    //login should be between start and end date
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(signIn >= %@) AND (signOut <= %@) AND (firstName like[cd] %@) AND (lastName like [cd] %@)", startDate, endDate, fN, lN];
    
    //set preidcate
    [request setPredicate:p];
    
    NSError *error;
    
    //save results in array
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    
    //check if any
    if ([result count]<= 0) {
        exist = FALSE;
    } else {
        //if any , place into designanted arrray
        allLoginsBySearch = result;
        
        exist = true;
    }
    
    return exist;
    


}

//returns an array that has results for any search
- (NSArray *)allLoginsBySearch
{
    return allLoginsBySearch;
}



@end
