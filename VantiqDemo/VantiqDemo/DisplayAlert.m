//
//  DisplayAlert.m
//  VantiqDemo
//
//  Created by Michael Swan on 3/25/16.
//  Copyright (c) 2016 Vantiq, Inc. All rights reserved.
//

#import "DisplayAlert.h"

@implementation DisplayAlert
+ (void)display:(UIViewController *)parentController title:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"com.vantiq.demo.OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    [alert addAction:defaultAction];
    [parentController presentViewController:alert animated:YES completion:nil];
}
@end
