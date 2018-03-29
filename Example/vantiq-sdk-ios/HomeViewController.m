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
#import "Vantiq.h"
#import <Foundation/Foundation.h>

extern Vantiq *v;

@interface HomeViewController() {
    NSMutableString *results;
    Boolean finishedQueuing;
    NSString *lastVantiqID;
}
@property (weak, nonatomic) IBOutlet UIButton *runTests;
@property (weak, nonatomic) IBOutlet UITextView *textResults;
@property (strong, atomic) NSNumber *queueCount;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    results = [NSMutableString new];
    _queueCount = [NSNumber new];
    
    // register for Push Notifications
    if (((AppDelegate *)[UIApplication sharedApplication].delegate).APNSDeviceToken) {
        [v registerForPushNotifications:((AppDelegate *)[UIApplication sharedApplication].delegate).APNSDeviceToken
            completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    NSString *resultStr;
                    if ([DecodeError formError:response error:error
                        diagnosis:NSLocalizedString(@"com.vantiq.demo.PushNotificationErrorExplain", @"") resultStr:&resultStr]) {
                        [DisplayAlert display:self title:NSLocalizedString(@"com.vantiq.demo.PushNotificationError", @"") message:resultStr];
                    }
                });
        }];
    }
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
- (void)runSelectTest:(NSString *)type props:(NSArray *)props where:(NSString *)where sort:(NSString *)sort limit:(int)limit {
    [v select:type props:props where:where sort:sort limit:limit completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
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
    [self runSelectTest:@"system.types" props:@[] where:NULL sort:NULL limit:-1];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"system.types" props:@[@"name", @"naturalKey"] where:NULL sort:NULL limit:-1];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"system.types" props:@[@"name", @"naturalKey"] where:@"{\"name\":\"ArsRuleSnapshot\"}" sort:NULL limit:-1];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"system.types" props:@[@"name", @"_id"] where:NULL sort:@"{\"name\":-1}" limit:-1];
    [NSThread sleepForTimeInterval:.3];
    [self runSelectTest:@"system.types" props:@[] where:NULL sort:NULL limit:2];
    
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"system.types" where:NULL];
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"system.types" where:@"{\"name\":\"ArsRuleSnapshot\"}"];
    [NSThread sleepForTimeInterval:.3];
    [self runCountTest:@"system.types" where:@"{\"ars_version\":{\"$gt\":5}}"];
    
    [NSThread sleepForTimeInterval:.3];
    [self runInsertTest:@"TestType" object:@"{\"intValue\":42,\"uniqueString\":\"42\"}"];
    [NSThread sleepForTimeInterval:.3];
    [self runInsertTest:@"TestType" object:@"{\"intValue\":43,\"uniqueString\":\"43\",\"stringValue\":\"A String.\"}"];
    
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
    _runTests.enabled = false;
    finishedQueuing = false;
    _queueCount = [NSNumber numberWithInt:20];
    results = [NSMutableString stringWithString:@""];
    
    [self appendAndScroll:[NSString stringWithFormat:@"Starting %d tests...", [_queueCount intValue]]];
    [NSThread detachNewThreadSelector:@selector(runActualTests) toTarget:self withObject:nil];
}
@end
