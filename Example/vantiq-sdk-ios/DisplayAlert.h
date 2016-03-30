//
//  DisplayAlert.h
//  VantiqDemo
//
//  Created by Michael Swan on 3/25/16.
//  Copyright (c) 2016 Vantiq, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DisplayAlert : NSObject
+ (void)display:(UIViewController *)parentController title:(NSString *)title message:(NSString *)message;
@end
