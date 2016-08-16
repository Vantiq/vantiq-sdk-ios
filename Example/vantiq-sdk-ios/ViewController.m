//
//  ViewController.m
//  VantiqDemo
//
//  Created by Swan on 3/24/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "ViewController.h"
#import "DecodeError.h"
#import "DisplayAlert.h"
#import "Vantiq.h"

// our one globally-available Vantiq endpoint
Vantiq *v;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    v = [[Vantiq alloc] initWithServer:@"https://dev.vantiq.com"];
    [v verify:^(NSHTTPURLResponse *response, NSError *error) {
        NSString *resultStr;
        if (![DecodeError formError:response error:error diagnosis:@"" resultStr:&resultStr]) {
            // the user already has a valid token so no need to log in
            [self performSegueWithIdentifier:@"Home" sender:self];
        }
    }];
}

- (IBAction)loginTapped:(id)sender {
    [v authenticate:_username.text password:_password.text completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
        NSString *resultStr;
        if ([DecodeError formError:response error:error
            diagnosis:NSLocalizedString(@"com.vantiq.demo.LoginErrorExplain", @"") resultStr:&resultStr]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                // any UI display needs to be on the main thread
                [DisplayAlert display:self title:NSLocalizedString(@"com.vantiq.demo.LoginError", @"") message:resultStr];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^ {
                // clear our password field
                _password.text = @"";
                // transition to the home view
                [self performSegueWithIdentifier:@"Home" sender:self];
            });
        }
    }];
}

- (IBAction)textChanged:(id)sender {
    _loginButton.enabled = ![_username.text isEqualToString:@""] && ![_password.text isEqualToString:@""];
}

/*
 *  prepareForSegue
 *      - called whenever we start a segue to a new modal view
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

@end
