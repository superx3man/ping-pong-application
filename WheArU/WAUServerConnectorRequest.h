//
//  WAUServerConnectorRequest.h
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WAUServerConnectorRequest : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSDictionary *parameters;

@property (nonatomic, assign, setter = setEncryptionNeeded:) BOOL isEncryptionNeeded;
@property (nonatomic, assign, setter = setDecryptionNeeded:) BOOL isDecryptionNeeded;
@property (nonatomic, assign, setter = setSignatureNeeded:) BOOL isSignatureNeeded;
@property (nonatomic, assign, setter = setResultInJSON:) BOOL isResultInJSON;

@property (nonatomic, strong) void (^successHandler)(WAUServerConnectorRequest *, NSObject *);
@property (nonatomic, strong) void (^failureHandler)(WAUServerConnectorRequest *);

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

- (id)initWithEndPoint:(NSString *)endPoint method:(NSString *)method parameters:(NSDictionary *)parameters;
- (id)initWithURL:(NSURL *)URL method:(NSString *)method parameters:(NSDictionary *)parameters;

@end
