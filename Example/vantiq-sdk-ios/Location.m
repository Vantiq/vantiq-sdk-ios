//
//  Location.m
//  vantiq-sdk-ios
//
//  Created by Jacob Schmitz on 7/7/16.
//  Copyright © 2016 Michael Swan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Location.h"

@import CoreLocation;

@implementation Location

@synthesize proximityUUID,major,minor;

-(id) initWithProximityUUID:(NSString*)proximityUUID_ major:(NSString *) major_ minor:(NSString*) minor_ name:(NSString*) name_ {
    self = [super init];
    if (self) {
        self.name = name_;
        self.major = major_;
        self.minor = minor_;
        self.proximityUUID = proximityUUID_;
    }
    return self;
}

-(id) initWithBeacon:(CLBeaconRegion*) beaconRegion{
    self = [super init];
    if (self) {
        self.name = (NSString*) beaconRegion.identifier;
        self.major = (NSString*) beaconRegion.major;
        self.minor = (NSString*) beaconRegion.minor;
        self.proximityUUID = (NSString*) beaconRegion.proximityUUID;
    }
    return self;
}

-(BOOL) isEqual:(Location*)object {
    if(![self.proximityUUID isEqualToString:object.proximityUUID]) {
        return NO;
    }
    if(![self.major isEqualToString: object.major]) {
        return NO;
    }
    if(![self.minor isEqualToString: object.minor]) {
        return NO;
    }
    /*if(![self.name isEqualToString: object.name]) {
        return NO;
    }*/
    return YES;
}

- (NSUInteger)hash {
    return [self.major hash] ^ [self.minor hash] ^ [self.proximityUUID hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setProximityUUID:(NSString*)self.proximityUUID];
        [copy setMajor:(NSString*)self.major];
        [copy setMinor:(NSString*)self.minor];
        [copy setName:(NSString*)self.name];
    }
    
    return copy;
}


@end