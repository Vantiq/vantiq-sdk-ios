//
//  OauthWebController.m
//  vantiq-sdk-ios_Example
//
//  Created by Swan on 3/15/18.
//  Copyright © 2018 Michael Swan. All rights reserved.
//

#import "OauthWebController.h"
#import "Vantiq.h"

extern Vantiq *v;

@interface OauthWebController () {
    NSString *host;
}
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation OauthWebController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // load the given authentication URL
    _webView.delegate = self;
    NSURL *url = [NSURL URLWithString:_OAuthURL];
    host = url.host;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [_webView loadRequest:urlRequest];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/**************************************************
 *    UIWebView Delegates
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;

    // look for a particular URL that indicates the authentication has completed and is returning with a JWT and access token
    if ([url.host isEqualToString:host] && url.path && [url.path isEqualToString:@"/iOS/callback"] && url.fragment) {
        // the JWT and access token will be in the URL's fragment
        BOOL foundAccessToken = false;
        NSArray *fragment = [url.fragment componentsSeparatedByString:@"&"];
        for (NSUInteger i = 0; i < [fragment count]; i++) {
            NSArray *fragmentElem = [fragment[i] componentsSeparatedByString:@"="];
            if ([fragmentElem count] == 2) {
                if ([fragmentElem[0] isEqualToString:@"id_token"]) {
                    // this is the JWT, which may be useful to some users
                } else if ([fragmentElem[0] isEqualToString:@"access_token"]) {
                    // save our access token
                    foundAccessToken = true;
                    v.accessToken = fragmentElem[1];
                    [[NSUserDefaults standardUserDefaults] setObject:v.accessToken forKey:@"com.vantiq.vantiq.accessToken"];
                }
            }
        }
        if (foundAccessToken) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self performSegueWithIdentifier:@"HomeFromWeb" sender:self];
            });
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //webView.scalesPageToFit = YES;
    //webView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"didFailLoadWithError = %@", error);
}
@end
