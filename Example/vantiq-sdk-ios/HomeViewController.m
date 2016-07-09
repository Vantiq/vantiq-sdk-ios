//
//  HomeViewController.m
//  VantiqDemo
//
//  Created by Michael Swan on 3/25/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "HomeViewController.h"
#import "DecodeError.h"
#import "DisplayAlert.h"
#import "AppDelegate.h"
#import "Location.h"
#import <vantiq_sdk_ios/Vantiq.h>
#import <Foundation/Foundation.h>

@import CoreLocation;

extern Vantiq *v;

static NSString * const kRWTStoredItemsKey = @"storedItems";

@interface HomeViewController() <CLLocationManagerDelegate> {
    NSMutableString *results;
    Boolean finishedQueuing;
    NSString *lastVantiqID;
}
@property (weak, nonatomic) IBOutlet UIButton *runTests;
@property (weak, nonatomic) IBOutlet UITextView *textResults;
@property (strong, atomic) NSNumber *queueCount;
@property (strong, nonatomic) CLLocationManager * locationManager;
@property (nonatomic, retain) IBOutlet UITableView * tableView;
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSMutableDictionary *knownLocations;
@property (nonatomic, strong) NSMutableDictionary *knownRegions;
@property (strong, nonatomic) NSMutableSet *displayedLocations;
@property (strong, nonatomic) CLBeaconRegion * currentRegion;
@end

// macro to add text to our UITextView field, scroll to the last entry and,
// as a side effect, decrement our outstanding operations count
#define AddToResults() dispatch_async(dispatch_get_main_queue(), ^ {\
    [self appendAndScroll:[NSString stringWithFormat:@"%@", resultStr]];\
    _queueCount = [NSNumber numberWithInt:[_queueCount intValue] - 1];\
    if ([_queueCount intValue] == 0) {\
        [self appendAndScroll:@"Finished tests."];\
        _runTests.enabled = true;\
    }\
});

@implementation HomeViewController

@synthesize tableData,tableView,knownLocations,knownRegions,displayedLocations,username,currentRegion;

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    results = [NSMutableString new];
    _queueCount = [NSNumber new];
    tableData = [[NSMutableArray alloc] init];
    knownLocations = [NSMutableDictionary dictionary];
    knownRegions = [NSMutableDictionary dictionary];
    displayedLocations = [NSMutableSet set];
    currentRegion = nil;
    self.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Add commented out locationManager requests to support background tracking
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        //[self.locationManager requestAlwaysAuthorization];
        [self.locationManager requestWhenInUseAuthorization];
    }
    /*if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }*/
    //[self.locationManager startUpdatingLocation];
    
    // Push notification stuff used to be here
}

/**
 * The next two methods are delegates required by the UITableView for displaying
 * nearby beacons
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

/**
 * This method defines the contents of each cell in the UITableView
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    CLBeaconRegion * beacon = [tableData objectAtIndex:indexPath.row];
    if ([self.currentRegion isEqual:beacon]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (Current Location)", beacon.identifier];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@\n", beacon.identifier];
    }
    return cell;
}

/**
 * This delegate ca be used when in the background, but does not currently do anything meaningful
 */
/*
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (state == CLRegionStateInside) { // Beacon appeared within region
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        NSLog(@"Ranging beacon: %@", region);
    } else if (state == CLRegionStateOutside) { // Beacon Disappeared from region
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        NSLog(@"Stopped Ranging beacon: %@", region);
    }
}
*/
// This delegate is called when a beacon comes into range
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        //if ([beaconRegion.identifier isEqualToString:@"com.nsscreencast.beaconfun.region"]) {
        NSString * major = [beaconRegion.major stringValue];
        NSString * minor = [beaconRegion.minor stringValue];
        if (!major) {
            major = @"0";
        }
        if (!minor) {
            minor = @"0";
        }
        Location * l = [[Location alloc] initWithProximityUUID:[beaconRegion.proximityUUID UUIDString] major:major minor:minor name:nil];
        if ([displayedLocations containsObject:l]) {
            CLBeaconRegion * realRegion = [[self.knownRegions objectForKey:[beaconRegion.proximityUUID UUIDString]] objectForKey:l];
            //[self.tableView beginUpdates];
            //NSUInteger objectIndex = [tableData indexOfObject:realRegion];
            [self.tableData removeObject:realRegion];
            [self.tableView reloadData];
            [self.displayedLocations removeObject: l];
            NSLog(@"Stopped Ranging beacon: %@", region);
        }
        //[self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        /*if ([displayedLocations containsObject:beaconIdentity]) {
            [knownLocations removeObject:beaconIdentity];
            [self.tableView beginUpdates];
            [tableData removeObject:region];
            [knownLocations addObject:beaconIdentity];
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:([tableData count] - 1) inSection: 0]];
            [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
            //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            [self.tableView endUpdates];
        }*/
        //}
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSDate *now = [NSDate date];
    NSString *iso8601String = [dateFormatter stringFromDate:now];

    NSLog([NSString stringWithFormat:@"%d", (int)indexPath.row]);
    CLBeaconRegion *br = [self.tableData objectAtIndex:indexPath.row];
    NSDictionary *msg = [NSDictionary dictionaryWithObjectsAndKeys:
                        [br.proximityUUID UUIDString], @"beaconId",
                        self.username, @"username",
                        iso8601String, @"timestamp",
                        nil];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString * jsonString = nil;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    if (jsonString) {
        
        [v publish:@"/user/location" message:jsonString completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                NSString *resultStr;
                if (![DecodeError formError:response error:error
                                  diagnosis:NSLocalizedString(@"com.vantiq.demo.PublishErrorExplain", @"") resultStr:&resultStr]) {
                    resultStr = [NSString stringWithFormat:@"publish(%@) successful.", @"/user/location"];
                    if ([currentRegion isEqual:br]) {
                        self.currentRegion = nil;
                    } else {
                        self.currentRegion = br;
                    }
                    [self.tableView reloadData];
                }
                NSLog(@"Got publish result: %@", resultStr);
            });
        }];
     
    }
}

- (NSString *)stringForProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityUnknown:    return @"Unknown";
        case CLProximityFar:        return @"Far";
        case CLProximityNear:       return @"Near";
        case CLProximityImmediate:  return @"Immediate";
        default:
            return nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if ([beacons count] > 0) {
        for (CLBeacon *beacon in beacons) {
            // Color top of table based on proximity
            [self setColorForProximity:beacon.proximity];
            Location * l = [[Location alloc] init];
            l.proximityUUID = [beacon.proximityUUID UUIDString];
            l.major = [beacon.major stringValue];
            l.minor = [beacon.minor stringValue];
            // If we see a beacon that is part of the knownLocations Dictionary, we should display the name of the location in the table view
            if ([knownLocations objectForKey:l] && ![displayedLocations containsObject:l]) {
                NSString * bName = [knownLocations objectForKey:l];
                [self.tableView beginUpdates];
                CLBeaconRegion *br = [[CLBeaconRegion alloc] initWithProximityUUID:beacon.proximityUUID
                                                       major:[beacon.major intValue]
                                                       minor:[beacon.minor intValue]
                                                       identifier:bName];
                [tableData addObject:br];
                //[knownLocations addObject:beaconIdentity];
                NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:([tableData count] - 1) inSection: 0]];
                [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
                [self.displayedLocations addObject:l];
                [[self.knownRegions objectForKey:[beacon.proximityUUID UUIDString]] setObject:br forKey:l];
            }
        }
    } else if ([displayedLocations count] > 0) { // Ranged no beacons, so remove all beacons from the list. This only works when app is open in foreground
        NSLog(@"Trying to remove all objects from tableview ");
        [self.tableData removeAllObjects];
        [self.displayedLocations removeAllObjects];
        [self.tableView reloadData];
    }
}

- (void)setColorForProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityUnknown:
            self.view.backgroundColor = [UIColor whiteColor];
            break;
            
        case CLProximityFar:
            self.view.backgroundColor = [UIColor yellowColor];
            break;
            
        case CLProximityNear:
            self.view.backgroundColor = [UIColor orangeColor];
            break;
            
        case CLProximityImmediate:
            self.view.backgroundColor = [UIColor redColor];
            break;
            
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

/*
 *  appendAndScroll
 *      - given some text, add that text to our mutable results string, then
 *          update the UITextView and scroll to the latest entry
 */
- (void)appendAndScroll:(NSString *)text {
    [results appendString:[NSString stringWithFormat:@"%@\n", text]];
    _textResults.text = results;

    // scroll to the bottom of the results
    NSRange range = NSMakeRange(_textResults.text.length - 1, 1);
    [_textResults scrollRangeToVisible:range];
}

/************************************
 *  the next eight methods are helpers for each of the methods in the Vantiq API
 *  they call the API, recognize errors, either in transport or HTTP, or, if
 *  there are no errors, form a results string that indicates success
 */
- (void)runSelectTest:(NSString *)type props:(NSArray *)props where:(NSString *)where sort:(NSString *)sort {
    [v select:type props:props where:where sort:sort completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.SelectErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"select(%@) returns %lu records.", type, (unsigned long)[data count]];
            }
            AddToResults();
        });
    }];
}

- (void)runSelectOneTest:(NSString *)type id:(NSString *)ID {
    [v selectOne:type id:ID completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                              diagnosis:NSLocalizedString(@"com.vantiq.demo.SelectOneErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"selectOne(%@) successful.", type];
            }
            AddToResults();
        });
    }];
}

- (void)runCountTest:(NSString *)type where:(NSString *)where {
    [v count:type where:where completionHandler:^(int count, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.CountErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"count(%@) returns count %d.", type, count];
            }
            AddToResults();
        });
    }];
}

- (void)runInsertTest:(NSString *)type object:(NSString *)object {
    [v insert:type object:object completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
        if (data) {
            // remember the record ID of this insert
            lastVantiqID = [data objectForKey:@"_id"];
        }
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError :response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.InsertErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"insert(%@) successful.", type];
            } else {
                [self appendAndScroll:resultStr];
                resultStr = @"Please make sure the type 'TestType' is defined. See the documentation.";
            }
            AddToResults();
        });
    }];
};

- (void)runUpdateTest:(NSString *)type id:(NSString *)ID object:(NSString *)object {
    [v update:type id:ID object:object completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError :response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.UpdateErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"update(%@) successful.", type];
            }
            AddToResults();
        });
    }];
};

- (void)runUpsertTest:(NSString *)type object:(NSString *)object {
    [v upsert:type object:object completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError :response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.UpsertErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"upsert(%@) successful.", type];
            }
            AddToResults();
        });
    }];
};

- (void)runDeleteTest:(NSString *)type where:(NSString *)where {
    [v delete:type where:where completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.DeleteErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"delete(%@) successful.", type];
            }
            AddToResults();
        });
    }];
}

- (void)runDeleteOneTest:(NSString *)type id:(NSString *)ID {
    [v deleteOne:type id:ID completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                              diagnosis:NSLocalizedString(@"com.vantiq.demo.DeleteOneErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"deleteOne(%@) successful.", type];
            }
            AddToResults();
        });
    }];
}

- (void)runPublishTest:(NSString *)topic message:(NSString *)message {
    [v publish:topic message:message completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.PublishErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"publish(%@) successful.", topic];
            }
            AddToResults();
        });
    }];
}

- (void)runExecuteTest:(NSString *)procedure params:(NSString *)params {
    [v execute:procedure params:params completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                diagnosis:NSLocalizedString(@"com.vantiq.demo.ExecuteErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"procedure(%@) successful.", procedure];
            } else {
                [self appendAndScroll:resultStr];
                resultStr = @"Please make sure the procedure 'AddTwo' is defined. See the documentation.";
            }
            AddToResults();
        });
    }];
}

/*
 *  runTests
 *      - run the actual tests on a separate thread so we can remain responsive
 *          to the user and update our progress text as each test completes
 */
- (void)runActualTests {
    [self runSelectTest:@"types" props:@[] where:NULL sort:NULL];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"ArsType" props:@[@"name", @"naturalKey"] where:NULL sort:NULL];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"ArsType" props:@[@"name", @"naturalKey"] where:@"{\"name\":\"ArsRuleSnapshot\"}" sort:NULL];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"ArsType" props:@[@"name", @"_id"] where:NULL sort:@"{\"name\":-1}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"types" where:NULL];
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"types" where:@"{\"name\":\"ArsRuleSnapshot\"}"];
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"types" where:@"{\"ars_version\":{\"$gt\":5}}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runInsertTest:@"TestType" object:@"{\"intValue\":42}"];
    [NSThread sleepForTimeInterval:.3];
    [self runInsertTest:@"TestType" object:@"{\"intValue\":43,\"stringValue\":\"A String.\"}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runUpsertTest:@"TestType" object:@"{\"intValue\":44,\"uniqueString\":\"A Unique String.\"}"];
    [NSThread sleepForTimeInterval:.3];
    [self runUpsertTest:@"TestType" object:@"{\"intValue\":45,\"uniqueString\":\"A Unique String.\"}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runUpdateTest:@"TestType" id:lastVantiqID object:@"{\"stringValue\":\"Updated String.\"}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runSelectOneTest:@"TestType" id:lastVantiqID];
    
    [NSThread sleepForTimeInterval:.3];
    [self runPublishTest:@"/vantiq" message:@"{\"intValue\":42}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runExecuteTest:@"sumTwo" params:@"[35, 21]"];
    [NSThread sleepForTimeInterval:.3];
    [self runExecuteTest:@"sumTwo" params:@"{\"val2\":35, \"val1\":21}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runDeleteOneTest:@"TestType" id:lastVantiqID];
    
    [NSThread sleepForTimeInterval:.3];
    [self runDeleteTest:@"TestType" where:@"{\"intValue\":42}"];
    [NSThread sleepForTimeInterval:.3];
    [self runDeleteTest:@"TestType" where:@"{\"intValue\":43}"];
}

/*
 *  runTestsTapped
 *      - the user has tapped the Run Tests button
 *      - make a series of API calls which exercise all API methods in various combinations
 *      - there is one potential timing issue in that the last insert operation has to
 *          complete before the only update operation since we need to know the unique ID
 *          of the last inserted record in order to do the update
 */
- (IBAction)runTestsTapped:(id)sender {
    // This is what the example app actually does when run tests is tapped
    /*_runTests.enabled = false;
    finishedQueuing = false;
    _queueCount = [NSNumber numberWithInt:19];
    results = [NSMutableString stringWithString:@""];
    
    [self appendAndScroll:[NSString stringWithFormat:@"Starting %d tests...", [_queueCount intValue]]];
    [NSThread detachNewThreadSelector:@selector(runActualTests) toTarget:self withObject:nil];*/
    self.locationManager = nil;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        //[self.locationManager requestAlwaysAuthorization];
        [self.locationManager requestWhenInUseAuthorization];
    }
    NSString * queryString = [NSString stringWithFormat:@"{\"username\": \"%@\"}", self.username];
    [v select:@"UserLocation" props:nil where:queryString sort:nil completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString * currentlLocationId;
            NSString *resultStr;
            if (![DecodeError formError:response error:error
                              diagnosis:NSLocalizedString(@"com.vantiq.demo.SelectErrorExplain", @"") resultStr:&resultStr]) {
                resultStr = [NSString stringWithFormat:@"select(%@) returns %lu records.", @"UserLocation", (unsigned long)[data count]];
            }
            
            for ( NSDictionary * userLocation in data) {
                currentlLocationId = [NSString stringWithFormat:@"%@",[userLocation objectForKey:@"locationId"]];
            }
            
            NSString * type = @"Location";
            [v select:type props:nil where:nil sort:nil completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    NSString *resultStr;
                    if (![DecodeError formError:response error:error
                                      diagnosis:NSLocalizedString(@"com.vantiq.demo.SelectErrorExplain", @"") resultStr:&resultStr]) {
                        resultStr = [NSString stringWithFormat:@"select(%@) returns %lu records.", type, (unsigned long)[data count]];
                    }
                    
                    for ( NSDictionary * item in data) {
                        NSString * beaconIDString = [item objectForKey:@"beaconId"];
                        NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString: beaconIDString];
                        // If we want to specifically monitor only certain major and minor vals within a UUID, we need this
                        //CLBeaconMajorValue major = [[item objectForKey:@"major"] intValue];
                        //CLBeaconMinorValue minor = [[item objectForKey:@"minor"] intValue];
                        NSString * name = [item objectForKey:@"name"];
                        Location * l = [[Location alloc] init];
                        l.proximityUUID = beaconIDString;
                        l.major = (NSString*)[item objectForKey:@"major"];
                        l.minor = (NSString*)[item objectForKey:@"minor"];
                        l.name = [item objectForKey:@"name"];
                        if (![self.knownRegions objectForKey:beaconIDString]) {
                            [self.knownRegions setObject: [NSMutableDictionary dictionary] forKey: beaconIDString];
                        }
                        if (![self.knownLocations objectForKey:l]) {
                            [self.knownLocations setObject:[item objectForKey:@"name"] forKey:l];
                        }
                        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                        // We don't specify major and minor vals here because ios limits you to monitoring 20 beacon regions
                                                        //       major:major
                                                        //       minor:minor
                                                                                          identifier:name];
                        beaconRegion.notifyOnEntry = YES;
                        beaconRegion.notifyOnExit = YES;
                        beaconRegion.notifyEntryStateOnDisplay = YES;
                        [self.locationManager stopMonitoringForRegion:beaconRegion];
                        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
                        [self.locationManager startMonitoringForRegion:beaconRegion];
                        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
                        
                        if ([currentlLocationId isEqualToString:[NSString stringWithFormat:@"%@",[item objectForKey:@"locationId"]]]) {
                            self.currentRegion = beaconRegion;
                        }
                        
                        //[self.locationManager requestStateForRegion:beaconRegion];
                        NSLog(@"Ranging local beacon: %@", beaconRegion.proximityUUID);
                    }
                });
            }];

        });
    }];
    
    
   }
@end
