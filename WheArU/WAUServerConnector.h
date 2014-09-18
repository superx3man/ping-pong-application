//
//  WAUServerConnector.h
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WAUServerConnectorRequest.h"


extern float const kWAUServerConnectorRequestTimeout;

typedef NS_ENUM(int, WAUServerConnectorPendingRequestState)
{
    WAUServerConnectorPendingRequestStateIdle,
    WAUServerConnectorPendingRequestStateClearing
};

@interface WAUServerConnector : NSObject

+ (WAUServerConnector *)sharedInstance;

- (void)sendRequest:(WAUServerConnectorRequest *)connectorRequest withTag:(NSString *)tag;

@end
