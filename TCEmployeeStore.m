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

#import "TCEmployeeStore.h"
#import "TCEmployees.h"
#import "TCImageStore.h"
#import "EmployeeLogins.h"

@import CoreData;

@interface TCEmployeeStore ()

@property (nonatomic) NSMutableArray *privateItems;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;

@property (nonatomic, strong) TCEmployees *loggedInUser;
@property (nonatomic, readonly) TCEmployees *employeeCalledForAllUserSearch;

@end

@implementation TCEmployeeStore
@synthesize loggedInUser;
@synthesize employeeCalledForAllUserSearch;

+ (instancetype)sharedStore
{
    static TCEmployeeStore *sharedStore;
    

    if (!sharedStore) {
        sharedStore = [[self alloc] initPrivate];
    }
    
    return sharedStore;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[TCEmployeeStore sharedStore]"
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
        
        [self loadAllItems];
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

//fecth all employees in database for entity TCEmployees
- (void)loadAllItems
{
    if (!self.privateItems) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *e = [NSEntityDescription entityForName:@"TCEmployees"
                                             inManagedObjectContext:self.context];
        
        request.entity = e;
        
        NSError *error;
        
        //add results of fecth to array
        NSArray *result = [self.context executeFetchRequest:request error:&error];
        if (!result) {
            [NSException raise:@"Fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        
        self.privateItems = [[NSMutableArray alloc] initWithArray:result];
    }
}

- (NSArray *)allEmployees
{
    return [self.privateItems copy];
}

//create employee
- (TCEmployees *)createItem
{
   //insert object into database
    TCEmployees *employee = [NSEntityDescription insertNewObjectForEntityForName:@"TCEmployees"
                                                  inManagedObjectContext:self.context];
    
    //add to array holding all employeess
    [self.privateItems addObject:employee];
    
    return employee;
}

//admin, first user
- (void) createAdmin
{
    //insert object
    TCEmployees *employee = [NSEntityDescription insertNewObjectForEntityForName:@"TCEmployees"
                                                          inManagedObjectContext:self.context];
    //edit attributes
    employee.firstName = @"Admin";
    employee.lastName = @ "Admin";
    employee.lastFourSSN = @"Admin";
    employee.idNumber = @"Admin";
    employee.role = @"Admin";
    
    //add to array holding all employeess
    [self.privateItems addObject:employee];
}

- (void)removeItem:(TCEmployees *)employee
{
    //if the employee has an image key, use it to delete its image
    NSString *key = employee.itemKey;
    if (key) {
        [[TCImageStore sharedStore] deleteImageForKey:key];
    }
    
    [self.context deleteObject:employee];
    
    //remove from array  holding all employeess
    [self.privateItems removeObjectIdenticalTo:employee];
}

//verify user logging in based on id number and last four ssn
-(BOOL)verifyAndSetLoggedInEmployeeWithID:(NSString *)idNumber
                                      and:(NSString *) lastFourSSN;
{
    TCEmployees *loggedInEmployee;
   
    BOOL exists = true;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *e = [NSEntityDescription entityForName:@"TCEmployees"
                                         inManagedObjectContext:self.context];
   
    request.entity = e;
    
    //predicate based on id number and ssn
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(idNumber LIKE[c] %@) AND (lastFourSSN LIKE[c] %@)",idNumber,lastFourSSN];
    
    //set predicate to requrst
    [request setPredicate:p];
    
    NSError *error;
    
    //add to array
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    

    //if no result, then nothing found and no employee exist based on id number and last four ssn
   
        if ([result count] <= 0) {
            exists = false;
        }
    
    //else , someone found
    if ([result count] > 0) {
        //NSLog(@"this is not  empty");
        
        NSArray *signedInEmployee = [self.allEmployees filteredArrayUsingPredicate:p];
        
        //should only be one, so get first
        loggedInEmployee  = signedInEmployee[0];
        
        //set as logged in user
        loggedInUser = loggedInEmployee;
       
        signedInEmployee = nil;
    }
   
    return exists;
}

//return logged in user, set in verify method

-(TCEmployees *)getLoggedInEmployee
{
    return loggedInUser;
}

//method used to filter the allhistory search with an employee based search
- (void) setEmployeeForAllUserSearch:(TCEmployees *) employee
{
    employeeCalledForAllUserSearch= employee;
}

- (TCEmployees *) getEmployeeForAllUserSearch
{
    return employeeCalledForAllUserSearch;
}
@end
