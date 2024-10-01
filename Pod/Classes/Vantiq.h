//
//  Vantiq.h
//  Vantiq
//
//  Created by Michael Swan on 3/25/16.
//  Copyright © 2016 Vantiq, Inc. All rights reserved.
//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import <Foundation/Foundation.h>

#define VantiqAPIVersion               1
#define errorCodeIncompleteJSON     1
#define errorNoAccessToken          2
#define VantiqErrorDomain              @"com.vantiq.Vantiq"

/**
The Vantiq class declares the interface for authentication and subsequent interaction with a Vantiq server.
 */
@interface Vantiq : NSObject
/**
Access token to be used for direct Vantiq server operations.
 */
@property (readwrite, nonatomic) NSString *accessToken;
/**
User name of the last authenticated user
 */
@property (readwrite, nonatomic) NSString *username;
/**
Namespace of the last authenticated user
 */
@property (readwrite, nonatomic) NSString *namespace;
/**
Server ID of the last authenticated user
 */
@property (readonly, nonatomic) NSString *serverId;
/**
Unique ID for this installation of the device running the Vantiq SDK
 */
@property (readonly, nonatomic) NSString *appUUID;

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
 
@see initWithServer:apiVersion:
 
@param server       Server URL, e.g. https://dev.vantiq.com
 */
- (id)initWithServer:(NSString *)server;

/**
The verify method attempts to validate the given Vantiq server token. If the token has expired
or a token has never been issued, the error parameter in the callback will be non-null and the
app should then call authenticate (see below) in order to reauthenticate the user. The data
parameter returned in the completionHandler is an array of user records for the namespace
associated with the access token.
 
@warning Please also note this method invokes a callback block associated with a network-
related block. Because this block is called from asynchronous network operations,
its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
to ensure UI operations are completed on the main thread.
 
@see authenticate:password:completionHandler:
 
@param accessToken  The access token to verify
@param username     The username associated with the token
@param handler      The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
*/
- (void)verify:(NSString *)accessToken username:(NSString *)username completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The authenticate method connects to the Vantiq server with the given authentication
credentials used to authorize the user. The username and password credentials are not stored.

@warning Please also note this method invokes a callback block associated with a network-
related block. Because this block is called from asynchronous network operations,
its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
to ensure UI operations are completed on the main thread.
 
@param  username    The username to provide access to the Vantiq server
@param  password    The password associated with the username
@param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)authenticate:(NSString *)username password:(NSString *)password
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
The retrieveServerId method retrieves a unique VANTIQ server ID once the user has been
authenticated, setting the serverId property in the process. This ID can be used to determine
the uniqueness of a server if one server has multiple IP addresses/URL endpoints

@warning Please also note this method invokes a callback block associated with a network-
related block. Because this block is called from asynchronous network operations,
its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
to ensure UI operations are completed on the main thread.
 
@param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)retrieveServerId:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 @param type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
 @param props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
 @param where   Specifies constraints to filter the data. Null means all records will be returned.
 @param sort    Specifies the desired sort for the result set. This is a JSON-formatted string.
 @param limit   Specifies a limit on the number of records returned. -1 means no limits. If zero or greater, the actual number of records present is returned in the 'X-Total-Count' HTTP header.
 @param handler    The handler block to execute.
 
 @return data: array of NSDictionary objects of matching records
 @return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
 @return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    sort:(NSString *)sort limit:(int)limit completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
 The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 @param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
 @param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
 @param  where   Specifies constraints to filter the data. Null means all records will be returned.
 @param  sort    Specifies the desired sort for the result set. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 
 @return data: array of NSDictionary objects of matching records
 @return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
 @return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    sort:(NSString *)sort completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
The select may query both user-defined types as well as system types, such as procedures and types.
 
@warning Please also note this method invokes a callback block associated with a network-
related block. Because this block is called from asynchronous network operations,
its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
to ensure UI operations are completed on the main thread.
 
It is important to check the response and error callback return values to verify there were no
errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
@see select:props:where:sort:completionHandler:
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
@param  where   Specifies constraints to filter the data. Null means all records will be returned. This is a JSON-formatted string.
@param handler    The handler block to execute.

@return data: array of NSDictionary objects of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)select:(NSString *)type props:(NSArray *)props where:(NSString *)where
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
@see select:props:where:sort:completionHandler:
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  props   Specifies the desired properties to be returned in each record. An empty array or null value means all properties will be returned. The array contains NSStrings.
@param handler    The handler block to execute.
 
@return data: array of NSDictionary objects of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)select:(NSString *)type props:(NSArray *)props
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The select method issues a query to select all matching records for a given type.
 The select may query both user-defined types as well as system types, such as procedures and types.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the select operation. The callback data returned is an array of NSDictionary objects.
 
@see select:props:where:sort:completionHandler:
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param handler    The handler block to execute.
 
@return data: array of NSDictionary objects of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
*/
- (void)select:(NSString *)type
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
 The selectOne method issues a query to select a single record for a given type and unique identifier.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the selectOne operation. The callback data returned is an array of NSDictionary objects.
 
 @see select:props:where:sort:completionHandler:

@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param ID  The unique identifier that matches the type's '_id' property.
@param handler    The handler block to execute.
 
@return data: array of NSDictionary objects of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)selectOne:(NSString *)type id:(NSString *)ID
completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
/**
The count method is similar to the select method except it returns only the number of records rather than returning the records themselves.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the count operation. The callback count returned is a count of the items requested.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  where   Specifies constraints to filter the data. Null means all records will be returned. This is a JSON-formatted string.
@param handler    The handler block to execute.
 
@return count: number of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
*/
- (void)count:(NSString *)type where:(NSString *)where
    completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler;
/**
The count method is similar to the select method except it returns only the number of records rather than returning the records themselves.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the count operation. The callback count returned is a count of the items requested.
 
@see count:where:completionHandler:
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param handler    The handler block to execute.
 
@return count: number of matching records
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)count:(NSString *)type
    completionHandler:(void (^)(int count, NSHTTPURLResponse *response, NSError *error))handler;

/**
The insert method creates a new record of a given type.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the inserted data.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  object  The JSON-formated string data to insert.
@param handler    The handler block to execute.
 
@return data: copy of the inserted data
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)insert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The update method updates an existing record of a given type. This method supports partial updates meaning that only the properties provided are updated. Any properties not specified are not changed in the underlying record.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the updated data.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  ID      The "_id" internal identifier for the record.
@param  object  The JSON-formated string data to update.
@param handler    The handler block to execute.
 
@return data: copy of the updated data
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)update:(NSString *)type id:(NSString *)ID object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
The upsert method either creates or updates a record in the database depending if the record already exists. The method tests for existence by looking at the natural keys defined on the type.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the insert operation. The callback data returned is a copy of the upserted data.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources)
@param  object  The JSON-formated string data to upsert.
@param handler    The handler block to execute.
 
@return data: copy of the upserted data
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)upsert:(NSString *)type object:(NSString *)object
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
 This delete method removes records from the system for a given type. Use this form of delete
 for system types which require the name of the type in order to perform the delete.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the deleteOne operation.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  resourceId   The resource identifier. This is a string and is mostly but not always associated with the type's 'name' property.
@param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)delete:(NSString *)type resourceId:(NSString *)resourceId completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;
/**
 This delete method removes records from the system for a given type. Deletes always require a constraint indicating which records to remove.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the deleteOne operation.
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param  where   Specifies constraints to filter the data. This is a JSON-formatted string.
@param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)delete:(NSString *)type where:(NSString *)where
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;
/**
 The deleteOne method issues a query to delete a single record for a given type and unique identifier.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the delete operation.
 
 @see delete:where:completionHandler:
 
@param  type    The data type to query. If querying for a Vantiq system type (e.g. types, sources), add a 'system.' prefix to the type (e.g. system.types, system.sources).
@param ID  The unique identifier that matches the type's '_id' property.
@param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)deleteOne:(NSString *)type id:(NSString *)ID
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The publish method publishes a message onto a given topic. Messages published onto topics can trigger rules to facilitate identifying situations.
 
 Topics are slash-delimited strings, such as '/test/topic'. Vantiq system-defined topics begin with /type, /property, /system, and /source.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the publish operation.
 
 @param  topic    The topic on which to publish.
 @param  message The message to publish. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)publish:(NSString *)topic message:(NSString *)message
    completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The publishEvent method publishes a message onto a given resource (topics, sources or services) and event. Messages published onto resources can trigger rules to facilitate identifying situations.
 
 event is a slash-delimited strings for topics, such as '/test/topic', a source name for sources, and a <serviceName>/<inboundEventName> for services.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the publish operation.
 
 @param  resource    The resource on which to publish.
 @param  resourceId    The resource instance on which to publish.
 @param  message The message to publish. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)publishEvent:(NSString *)resource event:(NSString *)resourceId message:(NSString *)message
   completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The execute method executes a procedure on the Vantiq server. Procedures can take parameters (i.e. arguments) and produce a result.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the procedure, if any.
 
 @param  procedure    The procedure to execute. The parameters may be provided as an array where the arguments are given in order. Alternatively, the parameters may be provided as an object where the arguments are named.
 @param  params Parameters passed to the procedure. This is a JSON-formatted string.
 @param handler    The handler block to execute.
 
@return data: result of method execution, if any, usually an NSDictionary or NSArray (use isKindOfClass to determine)
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)execute:(NSString *)procedure params:(NSString *)params
completionHandler:(void (^)(id data, NSHTTPURLResponse *response, NSError *error))handler;
/**
 The execute method executes a procedure on the Vantiq server. Procedures can take parameters (i.e. arguments) and produce a result.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the procedure, if any.
 
 @see execute:params:completionHandler:
 
 @param  procedure    The procedure to execute. The parameters may be provided as an array where the arguments are given in order. Alternatively, the parameters may be provided as an object where the arguments are named.
 @param handler    The handler block to execute.
 
@return data: result of method execution, if any, usually an NSDictionary or NSArray (use isKindOfClass to determine)
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)execute:(NSString *)procedure
    completionHandler:(void (^)(id data, NSHTTPURLResponse *response, NSError *error))handler;

/**
 The registerForPushNotifications method registers an app to receive Apple Push Notifications. Please note that
 you must enable the iOS app for Push Notifications and for the remote-notifications Background Mode, in addition
 to assigning a bundle identifier in both the app and in the app definition and provisioning profiles at the
 [Apple Developer](https://developer.apple.com) site.
 
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the procedure, if any.

 @param APNSDeviceToken The APNS Device Token returned by the registerForRemoteNotifications method.
 @param handler The handler block to execute.
 
 @return data: result of method execution, if any
 @return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
 @return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)registerForPushNotifications:(NSString *)APNSDeviceToken
    completionHandler:(void (^)(NSDictionary *data, NSHTTPURLResponse *response, NSError *error))handler;

/**
 The uploadDocument method uploads the given file, specified by the full path and file name, with
 any directory prefix and the given content type (MIME type). The upload process creates an
 ArsDocument record which contains the contents of the file. This method invokes the following
 method but passes the default @"/resources/documents" value for the resourcePath parameter.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the upload, if any.
 
 @param filePath The full path to the document, for example in the NSDocumentDirectory appended with the file name
 @param fileName The file name which also contains its file extension
 @param filePrefix Any directory prefix to be added to the file path when it's uploaded
 @param contentType The MIME type of the file contents
 @param handler The handler block to execute
 
 @return data: result of method execution, if any
 @return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
 @return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
*/
- (void)uploadDocument:(NSString *)filePath fileName:(NSString *)fileName filePrefix:(NSString *)filePrefix
    contentType:(NSString *)contentType completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
 The uploadDocument method uploads the given file, specified by the full path and file name, with
 any directory prefix and the given content type (MIME type). The upload process creates an
 ArsDocument record which contains the contents of the file.
 
 @warning Please also note this method invokes a callback block associated with a network-
 related block. Because this block is called from asynchronous network operations,
 its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
 to ensure UI operations are completed on the main thread.
 
 It is important to check the response and error callback return values to verify there were no
 errors returned by the execute operation. The callback data returns the results of the upload, if any.
 
 @param filePath The full path to the document, for example in the NSDocumentDirectory appended with the file name
 @param fileName The file name which also contains its file extension
 @param filePrefix Any directory prefix to be added to the file path when it's uploaded
 @param contentType The MIME type of the file contents
 @param resourcePath String specification of the destination resource, e.g. @"/resources/documents", @"/resources/images" or @"/resources/videos"
 @param handler The handler block to execute
 
 @return data: result of method execution, if any
 @return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
 @return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
 */
- (void)uploadDocument:(NSString *)filePath fileName:(NSString *)fileName filePrefix:(NSString *)filePrefix
    contentType:(NSString *)contentType resourcePath:(NSString *)resourcePath completionHandler:(void (^)(NSHTTPURLResponse *response, NSError *error))handler;

/**
The batch method  uses the batch REST API endpoint to process multiple REST URIs

@warning Please also note this method invokes a callback block associated with a network-
related block. Because this block is called from asynchronous network operations,
its code must be wrapped by a call to _dispatch_async(dispatch_get_main_queue(), ^ {...});_
to ensure UI operations are completed on the main thread.

It is important to check the response and error callback return values to verify there were no
errors returned by the execute operation. The callback data returns an array of results of each
of the URIs, if any.

@param encodedQueries NSData-encoded JSON request array
@param handler The handler block to execute

@return data: result of method execution, if any
@return response: [iOS HTTP operation response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSHTTPURLResponse_Class/)
@return error: [iOS error condition response](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSError_Class/)
*/
- (void)batch:(NSData *)encodedQueries
    completionHandler:(void (^)(NSArray *data, NSHTTPURLResponse *response, NSError *error))handler;
@end
#pragma clang diagnostic pop
