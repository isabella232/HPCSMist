//
//  HPCSSwiftClientSpec.m
//  HPCSIOSSampler
//
//  Created by Mike Hagedorn on 8/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"
#import "HPCSIdentityClient.h"
#import "Environment.h"
#import "OHHTTPStubs.h"
#import "AFNetworking.h"


static NSMutableArray *notifications;

SPEC_BEGIN(IdentityClientSpec)


        describe(@"HPCSIdentityClient", ^{

          context(@"when creating a new client", ^{
            context( @"and the identity url is not defined", ^{
              it(@"thows an NSError",^{
                NSString *userName = @"abc";
                NSString *password = @"password";
                NSString *tenantId = @"12345";
                id client = [[HPCSIdentityClient alloc] initWithUsername:userName andPassword:password andTenantId:tenantId];
                //TODO placeholder nil here
                [[client should] beNil];


              });
            });
            it(@"allows to see if you are authenticated", ^{
              NSString *userName = @"abc";
              NSString *password = @"password";
              NSString *tenantId = @"12345";
              id client = [[HPCSIdentityClient alloc] initWithUsername:userName andPassword:password andTenantId:tenantId];

              [[client should] respondToSelector:@selector(isAuthenticated)];
              [[theValue([client isTokenExpired]) should] beYes];
              [[theValue([client isAuthenticated]) should] beNo];
            });
          });

          context(@"when authenticating", ^{
              context(@"and you want to use username & password credentials directly", ^{
                __block id client = nil;
                beforeEach(^{
                  NSString *userName = @"abc";
                  NSString *password = @"password";
                  NSString *tenantId = @"12345";
                  client = [[HPCSIdentityClient alloc] initWithUsername:userName andPassword:password andTenantId:tenantId];
                });
                it(@"should contain the toplevel auth key", ^{
                  [[[[client authorizationInfo] allKeys] should] contain:kHPCSAuthKey ];
                });
                it(@"should contain the auth.passwordCredentials key", ^{
                  NSString *keyPath = [NSString stringWithFormat:@"%@.%@", kHPCSAuthKey, kHPCSAuthPasswordCredentialsKey];
                  [[[[client authorizationInfo] valueForKeyPath:keyPath ]shouldNot] beNil];;
                });
                it(@"should contain the auth.passwordCredentials.userName key", ^{
                  NSString *keyPath = [NSString stringWithFormat:@"%@.%@.%@", kHPCSAuthKey, kHPCSAuthPasswordCredentialsKey,kHPCSAuthUsernameKey];
                  [[[[client authorizationInfo] valueForKeyPath:keyPath ]shouldNot] beNil];;
                });
                it(@"should contain the auth.passwordCredentials.password key", ^{
                  NSString *keyPath = [NSString stringWithFormat:@"%@.%@.%@", kHPCSAuthKey, kHPCSAuthPasswordCredentialsKey,kHPCSAuthUsernameKey];
                  [[[[client authorizationInfo] valueForKeyPath:keyPath ]shouldNot] beNil];;
                });
                it(@"should contain the auth.tenantId key", ^{
                  NSString *keyPath = [NSString stringWithFormat:@"%@.%@", kHPCSAuthKey, kHPCSAuthTenantIdKey];
                  [[[[client authorizationInfo] valueForKeyPath:keyPath ]shouldNot] beNil];;
                });
                it(@"#authenticate sends the password hash to keystone`", ^{
                  [[client should] receive:@selector(postPath:parameters:success:failure:)];
                  [[client should] receive:@selector(authorizationInfo)];
                  //makes the enqueing a noop for the test
                 // [[client operationQueue] stub:@selector(addOperation:)];
                  [client authenticate:nil];
                });
                it(@"has a correct baseurl", ^{
                 [[[client baseURL] should] equal:[NSURL URLWithString:kHPCSIdentityBaseURLString]];
                });
                context(@"when sending correct valid credentials", ^{
                  beforeEach(^{
                    [OHHTTPStubs setEnabled:YES];
                    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
                    {
                      if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens"]) {
                        NSString* basename = [request.URL.absoluteString lastPathComponent];
                        NSString* fullName = [NSString stringWithFormat:@"%@.json",basename];
                        id stubResponse = [OHHTTPStubsResponse responseWithFile:fullName contentType:@"text/json" responseTime:0.1];
                        return stubResponse;
                      } else {
                        return nil; // Don't stub
                      }
                    }];

                  });
                  afterEach(^{
                    [OHHTTPStubs removeLastRequestHandler];
                  });

                  it(@"should send a service catalog", ^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[result shouldNot] beEmpty];

                  });

                  it(@"should have a compute entry", ^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                        // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                        // been marked as finished (even though the call backs haven't finished yet).
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                                 beforeDate:[NSDate date]];
                    }

                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type ==  %@)", @"compute"];
                    NSArray *filtered = [result filteredArrayUsingPredicate:predicate];
                    [[filtered shouldNot] beEmpty];
                  });

                  it(@"should have an object-store entry", ^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(type ==  %@)", @"object-store"];
                    NSArray *filtered = [result filteredArrayUsingPredicate:predicate];
                    [[filtered shouldNot] beEmpty];

                  });

                  it(@"should have a compute url",^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[[client publicUrlForCompute] shouldNot] beNil];

                  });

                  it(@"should have an objectstorage url",^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[[client publicUrlForObjectStorage] shouldNot] beNil];

                  });


                });
                context(@"when sending incorrect credentials", ^{
                  beforeEach(^{
                    [OHHTTPStubs setEnabled:YES];
                    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
                    {
                      if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens"]) {
                        NSString* basename = @"unauthorized";
                        NSString* fullName = [NSString stringWithFormat:@"%@.json",basename];
                        NSDictionary* headers = [NSDictionary dictionaryWithObject:@"text/json" forKey:@"Content-Type"];
                        id stubResponse = [OHHTTPStubsResponse responseWithFile:fullName statusCode:401 responseTime:0.2 headers:headers];
                        return stubResponse;
                      } else {
                        return nil; // Don't stub
                      }
                    }];
                    notifications = [NSMutableArray array];

                  });
                  afterEach(^{
                    [OHHTTPStubs removeLastRequestHandler];

                  });
                  it(@"sends back an empty array for service catalog", ^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];
                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[result should] beEmpty];
                  });
                  it(@"emits a login failed event", ^{

                    [[NSNotificationCenter defaultCenter] addObserver:notifications
                                                             selector:@selector(addObject:)
                                                                 name:HPCSAuthenticationDidFailNotification
                                                               object:nil];
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];
                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[result should] beEmpty];
                    [[notifications should] haveCountOf:1];

                    [[NSNotificationCenter defaultCenter] removeObserver:notifications];

                  });
                });
              });
              context(@"and you want to use access key id  & secret key credentials directly", ^{
                context(@"and the credentials are correct", ^{
                  __block id client = nil;
                  beforeEach(^{
                    client = [[HPCSIdentityClient alloc] initWithAccessKeyId:@"12345" andSecretKey:@"mykey" andTenantId:@"123"];
                    [OHHTTPStubs setEnabled:YES];
                    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
                    {
                      if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens"]) {
                        NSString* basename = @"tokensApiCreds";
                        NSString* fullName = [NSString stringWithFormat:@"%@.json",basename];
                        id stubResponse = [OHHTTPStubsResponse responseWithFile:fullName contentType:@"text/json" responseTime:0.1];
                        return stubResponse;
                      } else {
                        return nil; // Don't stub
                      }
                    }];

                  });
                  afterEach(^{
                    [OHHTTPStubs removeLastRequestHandler];
                  });
                  it(@"sends back a service catalog",^{
                    NSArray __block *result;
                    [client authenticate:^(NSArray *records) {
                      result = records;
                    }];

                    while (result == nil)
                    {
                      // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                      // been marked as finished (even though the call backs haven't finished yet).
                      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                               beforeDate:[NSDate date]];
                    }

                    [[result shouldNot] beEmpty];

                  });
                });
              });
            });
          context(@"when authenticated", ^{
            __block id client = nil;
            beforeEach(^{
              NSString *userName = @"abc";
              NSString *password = @"password";
              NSString *tenantId = @"12345";
              client = [[HPCSIdentityClient alloc] initWithUsername:userName andPassword:password andTenantId:tenantId];
              [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
              {
                if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens"]) {
                  NSString* basename = [request.URL.absoluteString lastPathComponent];
                  NSString* fullName = [NSString stringWithFormat:@"%@.json",basename];
                  id stubResponse = [OHHTTPStubsResponse responseWithFile:fullName contentType:@"text/json" responseTime:0.1];
                  return stubResponse;
                } else {
                  return nil; // Don't stub
                }
              }];

              NSArray __block *result;
              [client authenticate:^(NSArray *records) {
                result = records;
              }];

              while (result == nil)
              {
                // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                // been marked as finished (even though the call backs haven't finished yet).
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate date]];
              }

              [[[client token] shouldNot] beNil];


            });

            afterEach(^{
              [OHHTTPStubs removeLastRequestHandler];
            });

            context(@"and your token expires", ^{
              it(@"you can detect expiration via query", ^{
                [[theValue([[client token] isExpired]) should] equal:theValue(YES)];
              });
            });
            context(@"and you want to invalidate your token", ^{
              __block NSHTTPURLResponse  *successOp;
              beforeEach(^{
                [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
                {
                  if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens/HPAuth_4f186cb2e4b04d7c46dc85a3"]) {
                    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Test Server", @"Server",
                        @"no-cache", @"Pragma",
                        @"-1", @"Expires",
                        @"Thu, 23 Jan 2012 00:07:40 GMT", @"Date",nil];
                    id stubResponse = [OHHTTPStubsResponse responseWithFile:nil statusCode:204 responseTime:0.2 headers:headers];
                    return stubResponse;
                  } else {
                    return nil; // Don't stub
                  }
                }];
              });

              afterEach(^{
                [OHHTTPStubs removeLastRequestHandler];
              });

             __block int status;

              it(@"allows you do this",^{

                [client tokenInvalidate:^(NSHTTPURLResponse *response){
                  successOp = response;
                  status = response.statusCode;

                }
                invalid:^(NSHTTPURLResponse *response){
                  successOp = response;
                  //status = response.statusCode;
                  status = 999;

                }];

                while (successOp == nil)
                {
                  // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                  // been marked as finished (even though the call backs haven't finished yet).
                  [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                           beforeDate:[NSDate date]];
                };

                [[theValue(status) should] equal:theValue(204)];
                NSLog(@" *** this fails because the content type of the return value is not JSON!!! (its nothing or text/plain) ***");
              });

            });

            context(@"and you havent activated any resources",^{
              beforeEach(^{
                  NSString *userName = @"abc";
                  NSString *password = @"password";
                  NSString *tenantId = @"12345";
                  client = [[HPCSIdentityClient alloc] initWithUsername:userName andPassword:password andTenantId:tenantId];
                  [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
                  {
                    if ([request.URL.absoluteString hasSuffix:@"/v2.0/tokens"]) {
                      NSString* basename = @"authNoScopedToken";
                      NSString* fullName = [NSString stringWithFormat:@"%@.json",basename];
                      id stubResponse = [OHHTTPStubsResponse responseWithFile:fullName contentType:@"text/json" responseTime:0.1];
                      return stubResponse;
                    } else {
                      return nil; // Don't stub
                    }
                  }];
                  [notifications removeAllObjects];
                });

              afterEach(^{
                [OHHTTPStubs removeLastRequestHandler];
              });

              context(@"and you try to access the nova client", ^{
                it(@"notifies you that no compute resources are activated", ^{
                  [[NSNotificationCenter defaultCenter] addObserver:notifications
                                                           selector:@selector(addObject:)
                                                               name:HPCSKeystoneNovaCatalogIsEmptyNotification
                                                             object:nil];
                  NSArray __block *result;
                  [client authenticate:^(NSArray *records) {
                    result = records;
                  }];

                  while (result == nil)
                  {
                    // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                    // been marked as finished (even though the call backs haven't finished yet).
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate date]];
                  }

                  id nova = [client computeClient];
                  [nova shouldBeNil];

                  [[notifications should] haveCountOf:1];
                  [[NSNotificationCenter defaultCenter] removeObserver:notifications];

                });

              });
              context(@"and you try to access the swift client", ^{
                it(@"notifies you that no swift resources are activated", ^{
                  [[NSNotificationCenter defaultCenter] addObserver:notifications
                                                           selector:@selector(addObject:)
                                                               name:HPCSKeystoneSwiftCatalogIsEmptyNotification
                                                             object:nil];
                  NSArray __block *result;
                  [client authenticate:^(NSArray *records) {
                    result = records;
                  }];

                  while (result == nil)
                  {
                    // run runloop so that async dispatch can be handled on main thread AFTER the operation has
                    // been marked as finished (even though the call backs haven't finished yet).
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate date]];
                  }

                  id swift = [client swiftClient];
                  [swift shouldBeNil];

                  [[notifications should] haveCountOf:1];
                  [[NSNotificationCenter defaultCenter] removeObserver:notifications];

                });

              });


            });

          });


        });

SPEC_END


