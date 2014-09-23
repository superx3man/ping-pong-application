//
//  WAUServerConnectorRequest.m
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "WAUServerConnectorRequest.h"

#import "AppDelegate.h"

#import "WAUConstant.h"

@implementation WAUServerConnectorRequest

- (id)initWithEndPoint:(NSString *)endPoint method:(NSString *)method parameters:(NSDictionary *)parameters
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@", kWAUServerEndpoint, endPoint]];
    self = [self initWithURL:url method:method parameters:parameters];
    return self;
}

- (id)initWithURL:(NSURL *)URL method:(NSString *)method parameters:(NSDictionary *)parameters
{
    if (self = [super init]) {
        [self setURL:URL];
        [self setMethod:method];
        [self setParameters:parameters];
        
        [self setEncryptionNeeded:YES];
        [self setDecryptionNeeded:YES];
        [self setSignatureNeeded:YES];
        [self setResultInJSON:YES];
    }
    return self;
}

@end
