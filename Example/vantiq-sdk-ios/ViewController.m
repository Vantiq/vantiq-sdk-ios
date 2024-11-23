//
//  ViewController.m
//  VantiqDemo
//
//  Created by Swan on 3/24/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "ViewController.h"
#import "OauthWebController.h"
#import "DecodeError.h"
#import "DisplayAlert.h"
#import "Vantiq.h"

// our one globally-available Vantiq endpoint
Vantiq *v;

#define VANTIQ_SERVER_URL   @"https://2334355bb174.ngrok.app"
#define VANTIQ_NAMESPACE    @"swan"

@interface ViewController () {
    NSString *accessToken;
    NSString *OAuthURL;
}
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    v = [[Vantiq alloc] initWithServer:VANTIQ_SERVER_URL];
    accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.vantiq.vantiq.accessToken"];
    _username.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.vantiq.vantiq.username"];
    [v verify:accessToken username:_username.text completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *resultStr;
        if (![DecodeError formError:response error:error diagnosis:@"" resultStr:&resultStr]) {
            // the user already has a valid token so no need to log in
            dispatch_async(dispatch_get_main_queue(), ^ {
                v.namespace = VANTIQ_NAMESPACE;
                [self performSegueWithIdentifier:@"Home" sender:self];
            });
        } else {
            // find out what kind of authentication we need to use
            [v authenticate:@"" password:@"" completionHandler:^(NSHTTPURLResponse *response, NSError *error) {
                if (response) {
                    NSDictionary *headerFields = response.allHeaderFields;
                    if (headerFields) {
                        // look in a well-known header for the OAuth URL, if any
                        OAuthURL = [headerFields objectForKey:@"Www-Authenticate"];
                        if (OAuthURL && ![OAuthURL isEqualToString:@"Vantiq"]) {
                            dispatch_async(dispatch_get_main_queue(), ^ {
                                v.namespace = VANTIQ_NAMESPACE;
                                [self performSegueWithIdentifier:@"OauthWeb" sender:self];
                            });
                        }
                    }
                }
            }];
        }
    }];
}

/*
 *  loginTapped
 *      - this implements the old-style (non-OAuth) username/password authentication
 */
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
                // remember our access token and username
                accessToken = v.accessToken;
                [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"com.vantiq.vantiq.accessToken"];
                [[NSUserDefaults standardUserDefaults] setObject:_username.text forKey:@"com.vantiq.vantiq.username"];
                
                // clear our password field
                _password.text = @"";
                v.namespace = VANTIQ_NAMESPACE;
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
    if ([segue.identifier isEqualToString:@"OauthWeb"]) {
        OauthWebController *destViewController = [segue destinationViewController];
        destViewController.OAuthURL = OAuthURL;
    }
}

@end
