//
//  VIQ.m
//  VIQ
//
//  Created by Swan on 3/25/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import "VIQ.h"

@interface VIQ()
@property (strong, nonatomic) NSString *apiServer;
@property (readwrite, nonatomic) NSString *accessToken;
@property unsigned long apiVersion;
@end

@implementation VIQ

- (id)initWithServer:(NSString *)server apiVersion:(unsigned long)version {
    if (self = [super init]) {
        _apiServer = server;
        _apiVersion = version;
    }
    return self;
}

- (id)initWithServer:(NSString *)server {
    return [self initWithServer:server apiVersion:VIQAPIVersion];
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
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(httpResponse, error);
        } else {
            NSError *jsonError = nil;
            if (httpResponse.statusCode == 200) {
                // we got a valid response, parse the JSON return
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                id jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                        if ([jsonObject objectForKey:@"accessToken"]) {
                            _accessToken = [jsonObject objectForKey:@"accessToken"];
                        } else {
                            // error if we can't find the dictionary keys
                            jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
                        }
                    } else {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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
    NSString *encoded = [[s dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
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
    [request setValue:[NSString stringWithFormat:@"Bearer %@", _accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (void)update:(NSString *)type id:(NSString *)ID object:(NSString *)object
completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/api/v%lu/resources/%@/%@", _apiServer, _apiVersion, type, ID];
    
    NSMutableURLRequest *request = [self buildURLRequest:urlString method:@"PUT"];
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            id jsonObject = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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
    
    [request setHTTPBody:[object dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
    [request setHTTPBody:[message dataUsingEncoding:NSASCIIStringEncoding]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
        [request setHTTPBody:[params dataUsingEncoding:NSASCIIStringEncoding]];
    }
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(0, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        id jsonObject = NULL;
        if (error) {
            handler(NULL, httpResponse, error);
        } else {
            NSError *jsonError = NULL;
            if (httpResponse.statusCode == 200) {
                // we got a valid response, parse the JSON return
                NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                jsonObject = [NSJSONSerialization JSONObjectWithData:[returnString dataUsingEncoding:NSUTF8StringEncoding]
                    options:0 error:&jsonError];
                if (!jsonError) {
                    if (![jsonObject isKindOfClass:[NSArray class]]) {
                        // error if return isn't a dictionary
                        jsonError = [NSError errorWithDomain:VIQErrorDomain code:errorCodeIncompleteJSON userInfo:nil];
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

@end
