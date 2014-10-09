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
#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"
#import "WAUUtilities.h"


@implementation UserController
{
    NSMutableArray *delegateList;
    
    User *currentUser;
}

- (id)init
{
    if (self = [super init]) {
        delegateList = [[NSMutableArray alloc] init];
        
#ifdef DEBUG
        [self setPlatform:WAUUserPlatformTypeIOSDev];
#else
        [self setPlatform:WAUUserPlatformTypeIOS];
#endif
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityUser inManagedObjectContext:[self managedObjectContext]];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setReturnsObjectsAsFaults:NO];
        
        NSArray *requestResult = [[self managedObjectContext] executeFetchRequest:request error:nil];
        
        if (requestResult != nil && [requestResult count] >= 1) {
            currentUser = (User *) [requestResult lastObject];
            if ([currentUser userId] != nil) [self setUserId:[currentUser userId]];
            else [self performSelectorInBackground:@selector(registerUser) withObject:nil];
            
            [super setUsername:[currentUser username]];
            [super setUserColor:[UIColor colorFromHexString:[currentUser userColor]]];
            
            if ([currentUser userIcon] != nil) [super setUserIcon:[UIImage imageWithData:[currentUser userIcon]]];
            
            [super setNotificationKey:[currentUser notificationKey]];
            _fetchCount = [currentUser fetchCount];
            
            if ([currentUser isModified]) {
                [self setModified:YES withSyncDelay:0];
            }
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

- (void)registerUser
{
    if ([self userId] != nil) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(registerUser) object:nil];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[NSNumber numberWithInt:[self platform]] forKey:kWAUDictionaryKeyPlatform];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointRegister method:@"POST" parameters:userDictionary];
    [request setSignatureNeeded:NO];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:@"failed to register user" from:self];
         [self performSelector:@selector(registerUser) withObject:nil afterDelay:10];
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         NSString *userId = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyUserId];
         NSString *generatedKey = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyGeneratedKey];
         [WAULog log:[NSString stringWithFormat:@"user id: %@", userId] from:self];
         
         [currentUser setUserId:userId];
         [[self managedObjectContext] save:nil];
         
         [self setUserId:userId];
         
         [[EncryptionController sharedInstance] setGeneratedKey:generatedKey];
         if ([self isModified]) [self syncUser];
     }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"RegisterUser"];
}

- (void)syncUser
{
    if ([self userId] == nil || ![self isModified]) return;
    [self setModified:NO];
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[self userId] forKey:kWAUDictionaryKeyUserId];
    
    NSMutableDictionary *modifiedDictionary = [[NSMutableDictionary alloc] init];
    [modifiedDictionary setObject:[NSNumber numberWithInt:[self platform]] forKey:kWAUDictionaryKeyPlatform];
    [modifiedDictionary setObject:[currentUser username] forKey:kWAUDictionaryKeyUsername];
    [modifiedDictionary setObject:[currentUser userColor] forKey:kWAUDictionaryKeyUserColor];
    if ([currentUser userIcon] != nil) [modifiedDictionary setObject:[[currentUser userIcon] base64EncodedStringWithOptions:kNilOptions] forKey:kWAUDictionaryKeyUserIcon];
    if ([currentUser notificationKey] != nil) [modifiedDictionary setObject:[currentUser notificationKey] forKey:kWAUDictionaryKeyNotificationKey];
    [userDictionary setObject:modifiedDictionary forKey:kWAUDictionaryKeyModifiedList];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointUserSync method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:@"failed to sync user" from:self];
         
         [self setModified:YES withSyncDelay:60];
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         [WAULog log:@"user synced" from:self];
     }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"SyncUser"];
}

#pragma mark External

- (void)addDelegate:(id<UserControllerDelegate>)delegate
{
    @synchronized(delegateList) {
        [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
    }
    
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
        
        [currentUser setFetchCount:0];
        [[self managedObjectContext] save:nil];
        
        _fetchCount = 0;
        [self performSelectorInBackground:@selector(registerUser) withObject:nil];
    }
}

- (NSString *)QRCodeDescription
{
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[currentUser userId] forKey:kWAUDictionaryKeyUserId];
    [userDictionary setObject:[currentUser username] forKey:kWAUDictionaryKeyUsername];
    [userDictionary setObject:[currentUser userColor] forKey:kWAUDictionaryKeyUserColor];
    
    NSString *plainJsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:userDictionary options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    return [[EncryptionController sharedInstance] encryptStringWithSystemKey:plainJsonString];
}

#pragma mark - Properties

- (void)setUserId:(NSString *)userId
{
    if ([[self userId] isEqualToString:userId]) return;
    [super setUserId:userId];
    
    [WAUUtilities object:self performSelector:@selector(controllerDidSetUserId:) onDelegateList:delegateList];
}

- (void)setModified:(BOOL)isModified
{
    [self setModified:isModified withSyncDelay:20];
}

- (void)setModified:(BOOL)isModified withSyncDelay:(NSTimeInterval)delay
{
    if (_isModified == isModified) return;
    _isModified = isModified;
    
    [currentUser setIsModified:isModified];
    [[self managedObjectContext] save:nil];
    
    if (isModified && [self userId] != nil) [self performSelector:@selector(syncUser) withObject:nil afterDelay:delay];
}

- (void)setNotificationKey:(NSString *)notificationKey
{
    if ([[self notificationKey] isEqualToString:notificationKey]) return;
    [super setNotificationKey:notificationKey];
    
    [currentUser setNotificationKey:notificationKey];
    [[self managedObjectContext] save:nil];
    
    [self setModified:YES withSyncDelay:0];
}

- (void)setUsername:(NSString *)username
{
    if ([[self username] isEqualToString:username]) return;
    [super setUsername:username];
    
    [currentUser setUsername:username];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(userDidUpdateUsername:) onDelegateList:delegateList];
    
    [self setModified:YES];
}

- (void)setUserIcon:(UIImage *)userIcon
{
    if ([UIImagePNGRepresentation([self userIcon]) isEqualToData:UIImagePNGRepresentation(userIcon)]) return;
    [super setUserIcon:userIcon];
    
    [currentUser setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(userDidUpdateUserIcon:) onDelegateList:delegateList];
    
    [self setModified:YES];
}

- (void)setUserColor:(UIColor *)userColor
{
    if ([[self userColor] isEqual:userColor]) return;
    [super setUserColor:userColor];
    
    [currentUser setUserColor:[UIColor hexStringFromColor:userColor]];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(userDidUpdateUserColor:) onDelegateList:delegateList];
    
    [self setModified:YES];
}

- (void)incrementFetchCount:(int)count
{
    [self setFetchCount:[self fetchCount] + count];
}

- (void)setFetchCount:(int)fetchCount
{
    if (_fetchCount == fetchCount) return;
    _fetchCount = fetchCount;
    
    [currentUser setFetchCount:fetchCount];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(controllerDidReceiveNewFetch:) onDelegateList:delegateList];
}

@end
