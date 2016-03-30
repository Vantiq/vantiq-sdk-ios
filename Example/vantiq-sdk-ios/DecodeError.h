//
//  DecodeError.h
//  VantiqDemo
//
//  Created by Michael Swan on 3/25/16.
//  Copyright (c) 2016 Vantiq, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecodeError : NSObject
+ (BOOL)formError:(NSHTTPURLResponse *)response error:(NSError *)error diagnosis:(NSString *)diagnosis resultStr:(NSString **)resultStr;
@end
