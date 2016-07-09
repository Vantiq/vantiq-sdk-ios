//
//  Location.h
//  vantiq-sdk-ios
//
//  Created by Jacob Schmitz on 7/7/16.
//  Copyright © 2016 Michael Swan. All rights reserved.
//

#ifndef Location_h
#define Location_h

@import CoreLocation;

@interface Location : NSObject <NSCopying>

@property NSString * proximityUUID;
@property NSString * major;
@property NSString * minor;
@property NSString * name;

-(id) initWithProximityUUID:(NSString*)proximityUUID_ major:(NSString *) major_ minor:(NSString*) minor_ name:(NSString*) name_;

-(id) initWithBeacon:(CLBeaconRegion*) beaconRegion;

@end

#endif /* Location_h */
