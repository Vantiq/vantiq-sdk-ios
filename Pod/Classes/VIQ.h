//
//  VIQ.h
//  VIQ
//
//  Created by Michael Swan on 3/25/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VIQAPIVersion               1
#define errorCodeIncompleteJSON     1
#define VIQErrorDomain              @"com.vantiq.viq"

/**
The VIQ class declares the interface for authentication and subsequent interaction with a Vantiq server.
 */
@interface VIQ : NSObject
/**
Access token to be used for direct Vantiq server operations.
 */
@property (readonly, nonatomic) NSString *accessToken;

/**
Constructor for use with all other Vantiq server operations.
 
@param server       Server URL, e.g. https://dev.vantiq.com
@param version   Version of the Vantiq API to use
 */
- (id)initWithServer:(NSString *)server apiVersion:(unsigned long)version;
/**
Constructor for use with all other Vantiq server operations. This constructor
will use the most recent version of the Vantiq API. If an earlier version of the
API is required, use the initWithServer:server apiVersion:version contructor.
 
@param server       Server URL, e.g. https://dev.vantiq.com
 */
- (id)initWithServer:(NSString *)server;

/**
The authenticate method connects to the Vantiq server with the given authentication
credentials used to authorize the user. The username and password credentials are not stored.

Please also note this method invokes callback blocks associated with network-
related blocks. Because these blocks are called from asynchronous network operations,
their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
to ensure UI operations are completed on the main thread.
 
@param  username    The username to provide access to the Vantiq server
@param  password    The password associated with the username
@param handler    The handler block to execute.
 */
- (void)authenticate:(NSString *)username password:(NSString *)password
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
The select method issues a query to select all matching records for a given type.
The select may query both user-defined types as well as system types, such as procedures and types.

Please also note this method invokes callback blocks associated with network-
related blocks. Because these blocks are called from asynchronous network operations,
their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
to ensure UI operations are completed on the main thread.
 
@param  type    The data type to query
 @param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
@param  where   Specifies constraints to filter the data. Null means all records will be returned.
@param  sort    Specifies the desired sort for the result set. This is a JSON-formatted string.
@param handler    The handler block to execute.
 */
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    sort:(NSString *)sort completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
The select may query both user-defined types as well as system types, such as procedures and types.
 
Please also note this method invokes callback blocks associated with network-
related blocks. Because these blocks are called from asynchronous network operations,
their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
to ensure UI operations are completed on the main thread.
 
It is important to check the response and error callback return values to verify there were no
errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
 @param  type    The data type to query
 @param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.

 @param  where   Specifies constraints to filter the data. Null means all records will be returned. This is a JSON-formatted string.
@param handler    The handler block to execute.
 */
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
@param  type    The data type to query.
@param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
@param handler    The handler block to execute.
 */
- (void)select:(NSString *)type props:(NSArray *)props
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
@param  type    The data type to query.
@param handler    The handler block to execute.
*/
- (void)select:(NSString *)type
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The count method is similar to the select method except it returns only the number of records rather than returning the records themselves.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the count operation. The callback count returned is a count of the items requested.
 
@param  type    The data type to query.
@param  where   Specifies constraints to filter the data. Null means all records will be returned. This is a JSON-formatted string.
@param handler    The handler block to execute.
*/
- (void)count:(NSString *)type where:(NSString *)where
    completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler;
/**
The count method is similar to the select method except it returns only the number of records rather than returning the records themselves.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the count operation. The callback count returned is a count of the items requested.
 
 @param  type    The data type to query.
@param handler    The handler block to execute.
 */
- (void)count:(NSString *)type
    completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler;

/**
The insert method creates a new record of a given type.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the inserted data.
 
 @param  type    The data type to insert.
 @param  object  The JSON-formated string data to insert.
 @param handler    The handler block to execute.
 */
- (void)insert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The update method updates an existing record of a given type. This method supports partial updates meaning that only the properties provided are updated. Any properties not specified are not changed in the underlying record.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the updated data.
 
 @param  type    The data type to update.
 @param  ID      The "_id" internal identifier for the record.
 @param  object  The JSON-formated string data to update.
 @param handler    The handler block to execute.
 */
- (void)update:(NSString *)type id:(NSString *)ID object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The upsert method either creates or updates a record in the database depending if the record already exists. The method tests for existence by looking at the natural keys defined on the type.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the upserted data.
 
 @param  type    The data type to upsert.
 @param  object  The JSON-formated string data to upsert.
 @param handler    The handler block to execute.
 */
- (void)upsert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The delete method removes records from the system for a given type. Deletes always require a constraint indicating which records to remove.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the delete operation.
 
 @param  type    The data type to query.
 @param  where   Specifies constraints to filter the data. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 */
- (void)delete:(NSString *)type where:(NSString *)where
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
The publish method publishes a message onto a given topic. Messages published onto topics can trigger rules to facilitate identifying situations.
 
 Topics are slash-delimited strings, such as '/test/topic'. Vantiq system-defined topics begin with /type, /property, /system, and /source.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the publish operation.
 
 @param  topic    The topic on which to publish.
 @param  message The message to publish. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 */
- (void)publish:(NSString *)topic message:(NSString *)message
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The execute method executes a procedure on the Vantiq server. Procedures can take parameters (i.e. arguments) and produce a result.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the procedure, if any.
 
 @param  procedure    The procedure to execute. The parameters may be provided as an array where the arguments are given in order. Alternatively, the parameters may be provided as an object where the arguments are named.
 @param  params Parameters passed to the procedure. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 */
- (void)execute:(NSString *)procedure params:(NSString *)params
completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
 The execute method executes a procedure on the Vantiq server. Procedures can take parameters (i.e. arguments) and produce a result.
 
 Please also note this method invokes callback blocks associated with network-
 related blocks. Because these blocks are called from asynchronous network operations,
 their code must be wrapped by a call to dispatch_async(dispatch_get_main_queue(), ^ {...});
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the procedure, if any.
 
 @param  procedure    The procedure to execute. The parameters may be provided as an array where the arguments are given in order. Alternatively, the parameters may be provided as an object where the arguments are named.
 @param handler    The handler block to execute.
 */
- (void)execute:(NSString *)procedure
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;
@end