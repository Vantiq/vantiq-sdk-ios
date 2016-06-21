//
//  AppDelegate.m
//  VantiqDemo
//
//  Created by Swan on 3/24/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (readwrite, nonatomic) NSString *APNSDeviceToken;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // allow the user to select which type of notifications to receive, if any
    UIUserNotificationType types =
        (UIUserNotificationType)(UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert);
    UIUserNotificationSettings *mySettings =
        [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    // register for an APNS token
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // we've received an APNS token
    NSMutableString *deviceID = [NSMutableString string];
    // iterate through the bytes and convert to hex
    unsigned char *ptr = (unsigned char *)[deviceToken bytes];
    for (NSInteger i=0; i < 32; ++i) {
        [deviceID appendString:[NSString stringWithFormat:@"%02x", ptr[i]]];
    }
    
    // remember token for use in registering it with the Vantiq server
    _APNSDeviceToken = deviceID;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
    NSLog(@"Failed to receive token.");
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"%@", userInfo);
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

@end
