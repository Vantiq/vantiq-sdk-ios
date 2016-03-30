//
//  DecodeError.m
//  VantiqDemo
//
//  Created by Michael Swan on 3/25/16.
//  Copyright (c) 2016 Vantiq, Inc. All rights reserved.
//

#import "DecodeError.h"

@implementation DecodeError
+ (BOOL)formError:(NSHTTPURLResponse *)response error:(NSError *)error diagnosis:(NSString *)diagnosis resultStr:(NSString **)resultStr {
    if (error) {
        *resultStr = [NSString stringWithFormat:diagnosis, [error localizedDescription]];
        return YES;
    } else if ((response.statusCode < 200) || (response.statusCode > 299)) {
        *resultStr = [NSString stringWithFormat:diagnosis, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
        return YES;
    }
    return NO;
}
@end
