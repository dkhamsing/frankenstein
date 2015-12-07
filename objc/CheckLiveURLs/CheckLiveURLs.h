//
//  CheckLiveURLs.h
//
//  Created by Daniel Khamsing on 10/14/15.
//  Copyright © 2015 Daniel Khamsing. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Small library to check that URLs on a page are live. */
@interface CheckLiveURLs : NSObject

/**
 Get http response status code for a url.
 @param urlString String url.
 @param completion Block to execute on completion with status code, success and error arguments.
 */
+ (void)getHttpResponseStatusCodeForStringUrl:(NSString *)urlString completion:(void (^)(NSInteger statusCode, BOOL success, NSError *error))completion;

/**
 Get a list of unique links found on pages.
 @param pages List of web pages to get links from.
 @param completion Block to be executed on completion, it takes a list of string urls as an argument.
 */
+ (void)getUrlsFromPages:(NSArray *)pages completion:(void(^)(NSArray *stringUrls))completion;

@end
