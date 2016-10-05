//
//  Vantiq.m
//  Vantiq
//
//  Created by Swan on 3/25/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "Vantiq.h"

@interface Vantiq()
@property (strong, nonatomic) NSString *apiServer;
@property (readwrite, nonatomic) NSString *userName;
@property (readwrite, nonatomic) NSString *appUUID;
@property unsigned long apiVersion;
@end

@implementation Vantiq

- (id)initWithServer:(NSString *)server apiVersion:(unsigned long)version {
    if (self = [super init]) {
        while ([server hasSuffix:@"/"]) {
            // remove any trailing '/' characters
            server = [server substringToIndex:[server length] - 1];
        }
        _apiServer = server;
        _apiVersion = version;
    }
    return self;
}

- (id)initWithServer:(NSString *)server {
    _appUUID = [[NSUserDefaults standardUserDefaults] stringForKey:@"com.vantiq.vantiq.appUUID"];
    return [self initWithServer:server apiVersion:VantiqAPIVersion];
}

- (void)setAccessToken:(NSString *)accessToken {
    _accessToken = accessToken;
    [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey:@"com.vantiq.vantiq.accessToken"];
}

- (void)verify:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    _accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"com.vantiq.vantiq.accessToken"];
    _userName = [[NSUserDefaults standardUserDefaults] stringForKey:@"com.vantiq.vantiq.userName"];
    if (_accessToken) {
        [self select:@"types" props:NULL where:@"{\"name\":\"ArsType\"}" completionHandler:^(NSArray *data, NSHTTPURLResponse *response, NSError *error) {
            handler(response, error);
        }];
    } else {
        NSError *noTokenErr = [NSError errorWithDomain:VantiqErrorDomain code:errorNoAccessToken userInfo:nil];
        handler(NULL, noTokenErr);
    }
}

- (void)authenticate:(NSString *)username password:(NSString *)password
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    NSString *urlString = [NSString stringWithFormat:@"%@/authenticate", _apiServer];
    
    // form the HTTP GET request
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setTimeoutInterval:15.0];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [request setValue:[self formBasicAuth:username clientSecret:password] forHTTPHeaderField:@"Authorization"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(httpResponse, error);
        } else {
            NSError *jsonError = nil;
            if (httpResponse.statusCode == 200) {
                // we got a valid response, parse the JSON return
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                id jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                        if ([jsonObject objectForKey:@"accessToken"]) {
                            _accessToken = [jsonObject objectForKey:@"accessToken"];
                            _userName = username;

                            // squirrel away the access token so we can verify it in subsequent app starts
                            [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey:@"com.vantiq.vantiq.accessToken"];
                            [[NSUserDefaults standardUserDefaults] setObject:_userName forKey:@"com.vantiq.vantiq.userName"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        } else {
                            // error if we can't find the dictionary keys
                            jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                        }
                    } else {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(httpResponse, jsonError);
        }
    }];
    [task resume];
}

- (NSString *)formBasicAuth:(NSString *)clientId clientSecret:(NSString *)clientSecret {
    NSString *s = [NSString stringWithFormat:@"%@:%@", clientId, clientSecret];
    NSString *encoded = [[s dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] base64EncodedStringWithOptions:0];
    return [NSString stringWithFormat:@"Basic %@", encoded];
}

/*
 *  buildURLRequest
 *      - given a URL and an HTTP operation, form a URLRequest with appropriate
 *          authentication headers and timeout values
 */
- (NSMutableURLRequest *)buildURLRequest:(NSString *)urlString method:(NSString *)method {
    // form the HTTP GET request
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setTimeoutInterval:15.0];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:method];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (void)update:(NSString *)type id:(NSString *)ID object:(NSString *)object
completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@/%@", _apiServer, _apiVersion, type, ID];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"PUT"];
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            id jsonObject = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(jsonObject, httpResponse, jsonError);
        }
    }];
    [task resume];
}

- (void)upsert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@?upsert=true", _apiServer, _apiVersion, type];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"POST"];
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(jsonObject, httpResponse, jsonError);
        }
    }];
    [task resume];
}

- (void)insert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@", _apiServer, _apiVersion, type];

    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"POST"];
    
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(jsonObject, httpResponse, jsonError);
        }
    }];
    [task resume];
}

- (void)delete:(NSString *)type where:(NSString *)where completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@", _apiServer, _apiVersion, type];
    NSMutableString *murlArgs = [NSMutableString stringWithString:@"?count=true&where="];
    
    // add where clause
    if (where) {
        [murlArgs appendString:where];
    } else {
        [murlArgs appendString:@"{}"];
    }
    NSString *urlArgs = [murlArgs stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [urlString appendString:urlArgs];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"DELETE"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        handler(httpResponse, error);
    }];
    [task resume];
}
- (void)deleteOne:(NSString *)type id:(NSString *)ID
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    NSString *whereClause = [NSString stringWithFormat:@"{\"_id\":\"%@\"}", ID];
    [self delete:type where:whereClause completionHandler:handler];
}

- (void)publish:(NSString *)topic message:(NSString *)message
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/topics/%@", _apiServer, _apiVersion, topic];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"POST"];
    [request setHTTPBody:[message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        handler(httpResponse, error);
    }];
    [task resume];
}

- (void)execute:(NSString *)procedure params:(NSString *)params
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/procedures/%@", _apiServer, _apiVersion, procedure];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"POST"];
    if (params) {
        [request setHTTPBody:[params dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    }
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(jsonObject, httpResponse, jsonError);
        }
    }];
    [task resume];
}

- (void)execute:(NSString *)procedure
completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    [self execute:procedure params:NULL completionHandler:handler];
}

- (void)count:(NSString *)type where:(NSString *)where completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@", _apiServer, _apiVersion, type];
    NSMutableString *murlArgs = [NSMutableString stringWithString:@"?count=true&where="];

    // add where clause
    if (where) {
        [murlArgs appendString:where];
    } else {
        [murlArgs appendString:@"{}"];
    }
    NSString *urlArgs = [murlArgs stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [urlString appendString:urlArgs];
    
    // form the HTTP GET request
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            if (httpResponse.statusCode == 200) {
                int count = [[httpResponse.allHeaderFields objectForKey:@"X-Total-Count"] intValue];
                handler(count, httpResponse, error);
            } else {
                handler(0, httpResponse, error);
            }
        }
    }];
    [task resume];
}
- (void)count:(NSString *)type completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler {
    [self count:type where:NULL completionHandler:handler];
}

- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    sort:(NSString *)sort completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@", _apiServer, _apiVersion, type];
    NSMutableString *murlArgs = [NSMutableString stringWithString:@"?where="];
    NSString *urlArgs;
    
    // add where clause
    if (where) {
        [murlArgs appendString:where];
    } else {
        [murlArgs appendString:@"{}"];
    }
    urlArgs = [murlArgs stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [urlString appendString:urlArgs];
    
    // parse the props, if any
    if (props && [props count]) {
        // iterate the props
        [murlArgs appendString:@"&props=["];
        for (int i = 0; i < [props count]; i++) {
            if (i > 0) {
                [murlArgs appendString:@",\""];
            } else {
                [murlArgs appendString:@"\""];
            }
            [murlArgs appendString:props[i]];
            [murlArgs appendString:@"\""];
            [murlArgs appendString:@"]"];
            // add the props to the URL string
            urlArgs = [murlArgs stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [urlString appendString:urlArgs];
        }
    }
    
    // add the sort clause
    if (sort) {
        murlArgs = [NSMutableString stringWithString:[NSString stringWithFormat:@"&sort=%@", sort]];
        urlArgs = [murlArgs stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendString:urlArgs];
    }
    
    // form the HTTP GET request
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(NULL, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                // we got a valid response, parse the JSON return
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSArray class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(jsonObject, httpResponse, jsonError);
        }
    }];
    [task resume];
}
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler {
    [self select:type props:props where:where sort:NULL completionHandler:handler];
}
- (void)select:(NSString *)type props:(NSArray *)props
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler {
    [self select:type props:props where:NULL sort:NULL completionHandler:handler];
}
- (void)select:(NSString *)type
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler {
    [self select:type props:NULL where:NULL sort:NULL completionHandler:handler];
}
- (void)selectOne:(NSString *)type id:(NSString *)ID
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSString *whereClause = [NSString stringWithFormat:@"{\"_id\":\"%@\"}", ID];
    [self select:type props:NULL where:whereClause sort:NULL completionHandler:handler];
}

- (void)registerForPushNotifications:(NSString *)APNSDeviceToken
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    
    NSString *whereClause = [NSString stringWithFormat:@"{\"username\":\"%@\", \"deviceId\":\"%@\"}", _userName, _appUUID];
    [self select:@"ArsPushTarget" props:@[] where:whereClause completionHandler:^(NSArray *tokenArray,
        NSHTTPURLResponse *response, NSError *error) {
        if (error) {
            handler(nil, response, error);
        } else {
            BOOL needRegistration = true;
            BOOL foundToken = false;
            NSDictionary *tokenDict = nil;
            if ((response.statusCode < 200) || (response.statusCode > 299)) {
                handler(nil, response, error);
            } else {
                for (int i = 0; i < [tokenArray count]; i++) {
                    tokenDict = tokenArray[i];
                    if ([tokenDict isKindOfClass:[NSDictionary class]]) {
                        if ([tokenDict objectForKey:@"token"]) {
                            NSString *accessToken = [tokenDict objectForKey:@"token"];
                            if ([APNSDeviceToken isEqualToString:accessToken]) {
                                // the APNS token already is registered so we're done
                                handler(nil, response, error);
                                foundToken = true;
                                needRegistration = false;
                            }
                        }
                    } else {
                        tokenDict = nil;
                    }
                }
                if (tokenDict && !foundToken) {
                    // we need to update an existing record with the new token value
                    NSString *newToken = [NSString stringWithFormat:@"{\"token\":\"%@\"}", APNSDeviceToken];
                    [self update:@"ArsPushTarget" id:[tokenDict objectForKey:@"_id"] object:newToken completionHandler:^(NSDictionary *data, NSHTTPURLResponse *response, NSError *error) {
                        handler(nil, response, error);
                    }];
                    needRegistration = false;
                }
                if (needRegistration) {
                    // register a completely new token
                    _appUUID = [[NSUserDefaults standardUserDefaults] stringForKey:@"com.vantiq.vantiq.appUUID"];
                    if (!_appUUID) {
                        // create an UUID associated with this app and save it for future use
                        CFUUIDRef aUUID = CFUUIDCreate(NULL);
                        CFStringRef string = CFUUIDCreateString(NULL, aUUID);
                        CFRelease(aUUID);
                        _appUUID = (NSString*)CFBridgingRelease(string);
                        [[NSUserDefaults standardUserDefaults] setObject:_appUUID forKey:@"com.vantiq.vantiq.appUUID"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                    NSString *props = [NSString stringWithFormat:@"{\"appId\":\"%@\", \"appName\":\"%@\", \"deviceId\":\"%@\", \"deviceName\":\"%@\", \"platform\":0,  \"token\":\"%@\", \"username\":\"%@\"}",
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"],
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                        _appUUID, [[UIDevice currentDevice] name], APNSDeviceToken, _userName];
                    [self upsert:@"ArsPushTarget" object:props completionHandler:handler];
                }
            }
        }
    }];
}

- (void)uploadDocument:(NSString *)filePath fileName:(NSString *)fileName filePrefix:(NSString *)filePrefix
    contentType:(NSString *)contentType completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler {
    //
    //  This string is arbitrary; we just choose something to represent the boundary between the various multi-part
    //  MIME "parts".
    //
    NSString* boundaryString = @"*****";
    
    //
    //  These are all different components of the multi-part MIME protocol; we express them as NSDatas because we will be
    //  composing the entire message in one NSMutableData below.
    //
    NSData* lineEnd = [@"\r\n" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSData* twoHyphens = [@"--" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSData* boundary = [boundaryString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSData* contentDisposition = [[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\";filename=\"%@%@\"",
                                   fileName, filePrefix, fileName] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSData* contentBody = [[NSString stringWithFormat:@"Content-Type: %@", contentType] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/documents", _apiServer, _apiVersion];
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"POST"];
    
    // overwrite our default content type
    NSString* contentHeader = [NSString stringWithFormat:@"multipart/form-data;boundary=%@", boundaryString];
    [request setValue:contentHeader forHTTPHeaderField:@"Content-Type"];
    
    // build an NSData object containing the entire multi-part mime buffer we want to send to the server
    NSMutableData *outData = [NSMutableData new];
    
    [outData appendData:twoHyphens];
    [outData appendData:boundary];
    [outData appendData:lineEnd];
    [outData appendData:contentDisposition];
    [outData appendData:lineEnd];
    [outData appendData:contentBody];
    [outData appendData:lineEnd];
    [outData appendData:lineEnd];
    [outData appendData:[NSData dataWithContentsOfFile:filePath]];
    [outData appendData:lineEnd];
    [outData appendData:twoHyphens];
    [outData appendData:boundary];
    [outData appendData:twoHyphens];
    [outData appendData:lineEnd];
    [request setHTTPBody:outData];
    
    NSString *contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)[outData length]];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(httpResponse, error);
        } else {
            NSError *jsonError = nil;
            if (httpResponse.statusCode == 200) {
                // we got a valid response, parse the JSON return
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                id jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                                                                options:0 error:&jsonError];
                if (!jsonError) {
                    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                    } else {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VantiqErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                    }
                }
            }
            handler(httpResponse, jsonError);
        }
    }];
    [task resume];
}

@end
