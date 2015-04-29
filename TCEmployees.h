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


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TCEmployees : NSManagedObject

//employee attributes
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * idNumber;
@property (nonatomic, retain) NSString * itemKey;
@property (nonatomic, retain) NSString * lastFourSSN;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * role;
@property (nonatomic, retain) UIImage * thumbnail;

//employee image
- (void)setThumbnailFromImage:(UIImage *)image;

@end