//
//  UserController.m
//  WheArU
//
//  Created by Calvin Ng on 9/6/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UserController.h"

#import "AppDelegate.h"

#import "Reachability.h"
#import "UIColor+Hex.h"
#import "WAULog.h"


NSString *const kWAUImageUploadRemoteURL = @"icon_link";

NSString *const kWAUImageUploadDictionaryKeyUserId = @"id";
NSString *const kWAUImageUploadDictionaryKeyImageData = @"image";

NSString *const kWAUUserDictionaryKeyUsername = @"username";
NSString *const kWAUUserDictionaryKeyUserIcon = @"user_icon";
NSString *const kWAUUserDictionaryKeyUserColor = @"user_color";
NSString *const kWAUUserDictionaryKeyVersion = @"version";
NSString *const kWAUUserDictionaryKeyNotificationKey = @"notification_key";
NSString *const kWAUUserDictionaryKeyPlatform = @"platform";

@implementation UserController
{
    NSManagedObjectContext *managedObjectContext;
    NSMutableArray *delegateList;
    
    User *currentUser;
    Reachability* reachability;
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
                _username = [currentUser username];
                _userColor = [UIColor colorFromHexString:[currentUser userColor]];
                
                [self setUserIconUploadState:WAUUploadImageIconStateNoIcon];
                if ([currentUser userIcon] != nil) {
                    _userIcon = [UIImage imageWithData:[currentUser userIcon]];
                    [self setUserIconUploadState:[currentUser userIconLink] == nil ? WAUUploadImageIconStateNotUploaded : WAUUploadImageIconStateUploaded];
                }
                
                _notificationKey = [currentUser notificationKey];
                _fetchCount = [currentUser fetchCount];
            }
        }
        
        reachability = [Reachability reachabilityWithHostname:kWAUAppRemoteHost];
        [reachability setReachableOnWWAN:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [reachability startNotifier];
    }
    return self;
}

#pragma mark - Functions
#pragma mark Support

- (void)reachabilityChanged:(NSNotification*)notification
{
    [self uploadUserIcon];
}

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

- (void)uploadUserIcon
{
    if ([currentUser userIcon] == nil || [self userIconUploadState] != WAUUploadImageIconStateNotUploaded) return;
    if (![reachability isReachable]) return;
    
    [self setUserIconUploadState:WAUUploadImageIconStateUploading];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[currentUser userId] forKey:kWAUImageUploadDictionaryKeyUserId];
    [userDictionary setObject:[[currentUser userIcon] base64EncodedStringWithOptions:0] forKey:kWAUImageUploadDictionaryKeyImageData];
    
    NSData *jsonImageInfo = [NSJSONSerialization dataWithJSONObject:userDictionary options:0 error:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", kWAUAppRemoteHost, kWAUImageUploadRemoteURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.f];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonImageInfo];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                          {
                                              if (error != nil || [(NSHTTPURLResponse *) response statusCode] != 200) {
                                                  [WAULog log:@"icon link failed to upload" from:self];
                                                  [self setUserIconUploadState:WAUUploadImageIconStateNotUploaded];
                                                  return;
                                              }
                                              
                                              NSString *iconLink = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              [WAULog log:[NSString stringWithFormat:@"icon link: %@", iconLink] from:self];
                                              
                                              [currentUser setUserIconLink:iconLink];
                                              [currentUser setVersion:[currentUser version] + 1];
                                              [managedObjectContext save:nil];
                                              
                                              [self setUserIconUploadState:WAUUploadImageIconStateUploaded];
                                          }];
    [postDataTask resume];
}

- (NSString *)JSONDescription
{
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[NSNumber numberWithInteger:WAUUserPlatformTypeIOS] forKey:kWAUUserDictionaryKeyPlatform];
    [userDictionary setObject:[NSNumber numberWithInt:[currentUser version]] forKey:kWAUUserDictionaryKeyVersion];
    
    if ([currentUser notificationKey] != nil) [userDictionary setObject:[[currentUser notificationKey] base64EncodedStringWithOptions:0] forKey:kWAUUserDictionaryKeyNotificationKey];
    
    [userDictionary setObject:[currentUser username] forKey:kWAUUserDictionaryKeyUsername];
    [userDictionary setObject:[currentUser userColor] forKey:kWAUUserDictionaryKeyUserColor];
    
    if ([currentUser userIconLink] != nil) [userDictionary setObject:[currentUser userIconLink] forKey:kWAUUserDictionaryKeyUserIcon];
    
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:userDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
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
    if ([_username isEqualToString:username]) return;
    _username = username;
    
    [currentUser setUsername:username];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUsername:)]) [delegate userDidUpdateUsername:self];
    }
}

- (void)setUserIcon:(UIImage *)userIcon
{
    if (_userIcon == userIcon) return;
    _userIcon = userIcon;
    
    [currentUser setUserIconLink:nil];
    [self setUserIconUploadState:WAUUploadImageIconStateNotUploaded];
    
    [currentUser setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    [self uploadUserIcon];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUserIcon:)]) [delegate userDidUpdateUserIcon:self];
    }
}

- (void)setUserColor:(UIColor *)userColor
{
    if ([_userColor isEqual:userColor]) return;
    _userColor = userColor;
    
    [currentUser setUserColor:[UIColor hexStringFromColor:userColor]];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUserColor:)]) [delegate userDidUpdateUserColor:self];
    }
}

- (void)setNotificationKey:(NSData *)notificationKey
{
    if ([_notificationKey isEqualToData:notificationKey]) return;
    _notificationKey = notificationKey;
    
    [currentUser setNotificationKey:notificationKey];
    [currentUser setVersion:[currentUser version] + 1];
    [managedObjectContext save:nil];
}

@end
