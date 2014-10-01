//
//  AddContactWithFacebookViewController.h
//  WheArU
//
//  Created by Calvin Ng on 9/29/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

#import "AppDelegate.h"


extern NSString *const kWAUUserDictionaryKeyFacebookUserId;

@interface AddContactWithFacebookViewController : UIViewController <ExternalURLSchemeDelegate, ApplicationStateChangeDelegate, UITableViewDataSource, UITableViewDelegate>

@end
