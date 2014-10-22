//
//  WAUServerConnector.m
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "WAUServerConnector.h"

#import "AppDelegate.h"
#import "EncryptionController.h"

#import "APAsyncDictionary.h"
#import "NSString+Hash.h"
#import "Reachability.h"
#import "Reachability+SharedInstance.h"
#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUUtilities.h"


float const kWAUServerConnectorRequestTimeout = 10.f;

@implementation WAUServerConnector
{
    Reachability *reachibility;
    
    APAsyncDictionary *pendingRequestList;
    WAUServerConnectorPendingRequestState pendingRequestState;
}

- (id)init
{
    if (self = [super init]) {
        reachibility = [Reachability sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        pendingRequestList = [[APAsyncDictionary alloc] init];
        pendingRequestState = WAUServerConnectorPendingRequestStateIdle;
    }
    return self;
}

#pragma mark - Singleton Class

+ (WAUServerConnector *)sharedInstance
{
    static WAUServerConnector *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[WAUServerConnector alloc] init];
        }
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (void)reachabilityChanged:(NSNotification*)notification
{
    if (![reachibility isReachable] || pendingRequestState == WAUServerConnectorPendingRequestStateClearing) return;
    pendingRequestState = WAUServerConnectorPendingRequestStateClearing;
    
    [pendingRequestList allKeysCallback:^(NSArray *tagList)
     {
         for (NSString *tag in tagList) {
             WAUServerConnectorRequest *request = [pendingRequestList objectForKeySynchronously:tag];
             [pendingRequestList removeObjectForKey:tag];
             [self sendRequest:request synchrounous:YES];
         }
         pendingRequestState = WAUServerConnectorPendingRequestStateIdle;
         
         if ([pendingRequestList objectsCountSynchronously] != 0) [self reachabilityChanged:notification];
     }];
}

- (void)sendRequest:(WAUServerConnectorRequest *)connectorRequest synchrounous:(BOOL)isSynchrounous
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[connectorRequest URL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kWAUServerConnectorRequestTimeout];
    [request setHTTPMethod:[connectorRequest method]];
    
    NSData *httpBodyData = nil;
    if ([connectorRequest parameters] != nil && [[connectorRequest parameters] count] > 0) {
        httpBodyData = [NSJSONSerialization dataWithJSONObject:[connectorRequest parameters] options:kNilOptions error:nil];
        if ([connectorRequest isEncryptionNeeded]) {
            NSString *encryptedJsonInfo = [[EncryptionController sharedInstance] encryptStringWithSystemKey:[[NSString alloc] initWithData:httpBodyData encoding:NSUTF8StringEncoding]];
            httpBodyData = [encryptedJsonInfo dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    if (httpBodyData != nil) [request setHTTPBody:httpBodyData];
    if ([connectorRequest isSignatureNeeded]) {
        NSString *nonce = [[[NSUUID UUID] UUIDString] sha1];
        NSString *encryptedHash = [[EncryptionController sharedInstance] encryptStringWithGeneratedKey:nonce];
        [request setValue:[NSString stringWithFormat:@"WAUSign %@|%@", nonce, encryptedHash] forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        int httpStatusCode = (int) [(NSHTTPURLResponse *) response statusCode];
        if (error != nil || httpStatusCode != 200) {
            [WAULog log:[NSString stringWithFormat:@"http request error: %@ status code: %d", [error localizedDescription], httpStatusCode] from:self];
            if ([connectorRequest failureHandler] != nil) {
                [connectorRequest failureHandler](connectorRequest);
            }
        }
        else {
            if ([connectorRequest successHandler] != nil) {
                NSObject *requestResult = data;
                if ([connectorRequest isDecryptionNeeded]) {
                    NSString *plainRequest = [[EncryptionController sharedInstance] decryptStringWithSystemKey:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                    requestResult = [plainRequest dataUsingEncoding:NSUTF8StringEncoding];
                    if ([connectorRequest isResultInJSON]) {
                        requestResult = [NSJSONSerialization JSONObjectWithData:[plainRequest dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
                    }
                }
                [connectorRequest successHandler](connectorRequest, requestResult);
            }
        }
        [WAUUtilities endBackgroundTask:[connectorRequest backgroundTaskIdentifier]];
    }];
    [postDataTask resume];
}

#pragma mark External

- (void)sendRequest:(WAUServerConnectorRequest *)connectorRequest withTag:(NSString *)tag
{
    if ([reachibility isReachable]) [self sendRequest:connectorRequest synchrounous:NO];
    else [pendingRequestList setObject:connectorRequest forKey:tag];
}

@end
