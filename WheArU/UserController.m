//
//  UserController.m
//  WheArU
//
//  Created by Calvin Ng on 9/6/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UserController.h"

#import "AppDelegate.h"

#import "UIColor+Hex.h"

@implementation UserController
{
    NSManagedObjectContext *managedObjectContext;
    NSMutableArray *delegateList;
    
    User *currentUser;
}

- (id)init
{
    if (self = [super init]) {
        managedObjectContext = [(AppDelegate *) [[UIApplication sharedApplication] delegate] managedObjectContext];
        delegateList = [[NSMutableArray alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityUser inManagedObjectContext:managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setReturnsObjectsAsFaults:NO];
        
        NSArray *requestResult = [managedObjectContext executeFetchRequest:request error:nil];
        
        if (requestResult != nil) {
            if ([requestResult count] >= 1) {
                currentUser = (User *) [requestResult lastObject];
                [self setUsername:[currentUser username]];
                [self setUserIcon:[UIImage imageWithData:[currentUser userIcon]]];
                [self setUserColor:[UIColor colorFromHexString:[currentUser userColor]]];
                
                [self setFetchCount:[currentUser fetchCount]];
            }
        }
    }
    return self;
}

#pragma mark - Functions
#pragma mark Support

#pragma mark External

- (void)addDelegate:(id<UserControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
}

- (BOOL)isUserRegistered
{
    return currentUser != nil;
}

- (void)createUser
{
    if (![self isUserRegistered]) {
        currentUser = [NSEntityDescription insertNewObjectForEntityForName:kWAUCoreDataEntityUser inManagedObjectContext:managedObjectContext];
        
        NSString *currentTimestamp = [NSString stringWithFormat:@"%d", (int) [[NSDate date] timeIntervalSince1970]];
        [currentUser setUserId:[NSString stringWithFormat:@"%@-%@", [[NSProcessInfo processInfo] globallyUniqueString], currentTimestamp]];
        [currentUser setFetchCount:0];
        [currentUser setVersion:1];
        
        [managedObjectContext save:nil];
    }
}

#pragma mark External Class

+ (NSArray *)availableUserColor
{
    NSArray *colorHexList = [[NSArray alloc] initWithObjects:@"FFAAAA", @"FFD8AA", @"FFECAA", @"FFFFAA", @"C4E79A", @"70A897", @"7887AB", @"8D79AE", @"B77AAB", nil];
    
    NSMutableArray *colorList = [[NSMutableArray alloc] initWithCapacity:[colorHexList count]];
    for (NSString *colorHex in colorHexList) {
        [colorList addObject:[UIColor colorFromHexString:colorHex]];
    }
    return [NSArray arrayWithArray:colorList];
}

#pragma mark - Properties

- (UIColor *)wordColor
{
    CGFloat red, green, blue;
    [[self userColor] getRed:&red green:&green blue:&blue alpha:nil];
    
    int lightCount = 0;
    if (red >= 0.8f) lightCount++;
    if (green >= 0.8f) lightCount++;
    if (blue >= 0.8f) lightCount++;
    
    return lightCount >= 2 ? [UIColor lightGrayColor] : [UIColor whiteColor];
}

- (void)setUsername:(NSString *)username
{
    if (_username == username) return;
    _username = username;
    
    [currentUser setUsername:username];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        [delegate userDidUpdateUsername:self];
    }
}

- (void)setUserIcon:(UIImage *)userIcon
{
    if (_userIcon == userIcon) return;
    _userIcon = userIcon;
    
    [currentUser setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        [delegate userDidUpdateUserIcon:self];
    }
}

- (void)setUserColor:(UIColor *)userColor
{
    if (_userColor == userColor) return;
    _userColor = userColor;
    
    [currentUser setUserColor:[UIColor hexStringFromColor:userColor]];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        [delegate userDidUpdateUserColor:self];
    }
}

@end
