//
//  UserController.m
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UserController.h"

#import "AppDelegate.h"
#import "User.h"
#import "EncryptionController.h"
#import "NotificationController.h"

#import "UIColor+Hex.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"


NSString *const kWAUImageUploadRemoteURL = @"icon_link";

NSString *const kWAUImageUploadDictionaryKeyUserId = @"id";
NSString *const kWAUImageUploadDictionaryKeyImageData = @"image";

NSString *const kWAUImageUploadDictionaryKeyIconLink = @"url";

@implementation UserController
{
    NSMutableArray *delegateList;
    
    User *currentUser;
}

- (id)init
{
    if (self = [super init]) {
        delegateList = [[NSMutableArray alloc] init];
        
        [self setPlatform:WAUUserPlatformTypeIOS];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityUser inManagedObjectContext:[self managedObjectContext]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setReturnsObjectsAsFaults:NO];
        
        NSArray *requestResult = [[self managedObjectContext] executeFetchRequest:request error:nil];
        
        if (requestResult != nil && [requestResult count] >= 1) {
            currentUser = (User *) [requestResult lastObject];
            [self setUserId:[currentUser userId]];
            
            [super setUsername:[currentUser username]];
            [super setUserColor:[UIColor colorFromHexString:[currentUser userColor]]];
            
            [super setUserIconState:WAUImageIconStateNoIcon];
            if ([currentUser userIcon] != nil) {
                [super setUserIcon:[UIImage imageWithData:[currentUser userIcon]]];
                if ([currentUser userIconLink] == nil) {
                    [super setUserIconState:WAUImageIconStateNotSynced];
                    [self uploadUserIcon];
                }
                else {
                    [super setUserIconLink:[currentUser userIconLink]];
                    [super setUserIconState:WAUImageIconStateSynced];
                }
            }
            
            [super setNotificationKey:[currentUser notificationKey]];
            _fetchCount = [currentUser fetchCount];
        }
    }
    return self;
}

#pragma mark - Singleton Class

+ (UserController *)sharedInstance
{
    static UserController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[UserController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (void)uploadUserIcon
{
    if ([self userIcon] == nil || [self userIconState] != WAUImageIconStateNotSynced) return;
    
    [self setUserIconState:WAUImageIconStateSyncing];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[currentUser userId] forKey:kWAUImageUploadDictionaryKeyUserId];
    [userDictionary setObject:[[currentUser userIcon] base64EncodedStringWithOptions:kNilOptions] forKey:kWAUImageUploadDictionaryKeyImageData];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUImageUploadRemoteURL method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
    {
        [WAULog log:@"icon link failed to upload" from:self];
        [self setUserIconState:WAUImageIconStateNotSynced];
    }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
    {
        NSString *iconLink = [(NSDictionary *) requestResult objectForKey:kWAUImageUploadDictionaryKeyIconLink];
        [WAULog log:[NSString stringWithFormat:@"icon link: %@", iconLink] from:self];
        
        [self setUserIconLink:iconLink];
        [self setUserIconState:WAUImageIconStateSynced];
    }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"UploadUserIcon"];
}

#pragma mark External

- (void)addDelegate:(id<UserControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
    
    if ([self userId] != nil && [delegate respondsToSelector:@selector(controllerDidSetUserId:)]) [delegate controllerDidSetUserId:self];
}

- (BOOL)isUserRegistered
{
    return currentUser != nil;
}

- (void)createUser
{
    if (![self isUserRegistered]) {
        currentUser = [NSEntityDescription insertNewObjectForEntityForName:kWAUCoreDataEntityUser inManagedObjectContext:[self managedObjectContext]];
        
        NSString *currentTimestamp = [NSString stringWithFormat:@"%d", (int) [[NSDate date] timeIntervalSince1970]];
        [currentUser setUserId:[NSString stringWithFormat:@"%@-%@", [[NSProcessInfo processInfo] globallyUniqueString], currentTimestamp]];
        [currentUser setFetchCount:0];
        [currentUser setVersion:1];
        
        [[self managedObjectContext] save:nil];
        
        [self setUserId:[currentUser userId]];
        _fetchCount = 0;
    }
}

- (NSString *)QRCodeDescription
{
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[currentUser userId] forKey:kWAUUserDictionaryKeyUserId];
    
    [userDictionary setObject:[NSNumber numberWithInt:[self platform]] forKey:kWAUUserDictionaryKeyPlatform];
    [userDictionary setObject:[NSNumber numberWithInt:[currentUser version]] forKey:kWAUUserDictionaryKeyVersion];
    
    if ([currentUser notificationKey] != nil) [userDictionary setObject:[[currentUser notificationKey] base64EncodedStringWithOptions:kNilOptions] forKey:kWAUUserDictionaryKeyNotificationKey];
    
    [userDictionary setObject:[currentUser username] forKey:kWAUUserDictionaryKeyUsername];
    [userDictionary setObject:[currentUser userColor] forKey:kWAUUserDictionaryKeyUserColor];
    
    if ([currentUser userIconLink] != nil) [userDictionary setObject:[currentUser userIconLink] forKey:kWAUUserDictionaryKeyUserIcon];
    
    NSString *plainJsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:userDictionary options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    return [[EncryptionController sharedInstance] encryptStringWithSystemKey:plainJsonString];
}

#pragma mark - Properties

- (void)setUserId:(NSString *)userId
{
    if ([[self userId] isEqualToString:userId]) return;
    [super setUserId:userId];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(controllerDidSetUserId:)]) [delegate controllerDidSetUserId:self];
    }
}

- (void)setNotificationKey:(NSData *)notificationKey
{
    if ([[self notificationKey] isEqualToData:notificationKey]) return;
    [super setNotificationKey:notificationKey];
    
    [currentUser setNotificationKey:notificationKey];
    [currentUser setVersion:[currentUser version] + 1];
    [[self managedObjectContext] save:nil];
}

- (void)setUsername:(NSString *)username
{
    if ([[self username] isEqualToString:username]) return;
    [super setUsername:username];
    
    [currentUser setUsername:username];
    [currentUser setVersion:[currentUser version] + 1];
    [[self managedObjectContext] save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUsername:)]) [delegate userDidUpdateUsername:self];
    }
}

- (void)setUserIcon:(UIImage *)userIcon
{
    if ([UIImagePNGRepresentation([self userIcon]) isEqualToData:UIImagePNGRepresentation(userIcon)]) return;
    [super setUserIcon:userIcon];
    
    [currentUser setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [currentUser setVersion:[currentUser version] + 1];
    [[self managedObjectContext] save:nil];
    
    [self uploadUserIcon];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUserIcon:)]) [delegate userDidUpdateUserIcon:self];
    }
}

- (void)setUserIconLink:(NSString *)userIconLink
{
    if ([[self userIconLink] isEqualToString:userIconLink]) return;
    [super setUserIconLink:userIconLink];
    
    [currentUser setUserIconLink:userIconLink];
    [currentUser setVersion:[currentUser version] + 1];
    [[self managedObjectContext] save:nil];
}

- (void)setUserColor:(UIColor *)userColor
{
    if ([[self userColor] isEqual:userColor]) return;
    [super setUserColor:userColor];
    
    [currentUser setUserColor:[UIColor hexStringFromColor:userColor]];
    [currentUser setVersion:[currentUser version] + 1];
    [[self managedObjectContext] save:nil];
    
    for (id<UserControllerDelegate> delegate in delegateList) {
        if ([delegate respondsToSelector:@selector(userDidUpdateUserColor:)]) [delegate userDidUpdateUserColor:self];
    }
}

@end
