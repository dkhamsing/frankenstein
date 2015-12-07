//
//  CheckLiveURLs.m
//
//  Created by Daniel Khamsing on 10/14/15.
//  Copyright © 2015 Daniel Khamsing. All rights reserved.
//

#import "CheckLiveURLs.h"

@implementation CheckLiveURLs

+ (void)getHttpResponseStatusCodeForStringUrl:(NSString *)urlString completion:(void (^)(NSInteger statusCode, BOOL success, NSError *error))completion;
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLRequest *request = ({
        NSURL *url = [NSURL URLWithString:urlString];
        [NSURLRequest requestWithURL:url];
    });
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        completion(httpResponse.statusCode,
                   httpResponse.statusCode==200,
                   error);
    }] resume];
}

+ (void)getUrlsFromPages:(NSArray *)pages completion:(void (^)(NSArray *))completion;
{
    NSMutableArray *links = [[NSMutableArray alloc] init];
    __block NSInteger counter = 0;
    [pages enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLRequest *request = ({
            NSURL *url = [NSURL URLWithString:obj];
            [NSURLRequest requestWithURL:url];
        });
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            // check for dupes
            NSArray *foundLinks = [self getLinksFromData:data];
            for (NSString *item in foundLinks) {
                if (![links containsObject:item]) {
                    [links addObject:item];
                }
            }
            
            counter++;
            if (counter==pages.count) {
                completion(links);
            }
        }] resume];
    }];
}

#pragma mark Private

+ (NSArray *)getLinksFromData:(NSData *)data;
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *array = [string componentsSeparatedByString:@" "];
    
    NSMutableArray *links = [[NSMutableArray alloc] init];
    
    [array enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:@"http://"] ||
            [obj containsString:@"https://"]
            ) {
            if ([obj containsString:@"("] &&
                [obj containsString:@")"]
                ) {
                // markdown
                NSRange range = [obj rangeOfString:@"http"];
                NSString *substring = [obj substringFromIndex:range.location];
                
                substring = [self stringByRemovingEverythingAfterString:@")" from:substring];
                substring = [self stringByRemovingEverythingAfterString:@"]" from:substring];
                
                // should be longer than http://
                if (substring.length>7) {
                    [links addObject:substring];
                }
            }
            else {
                NSString *filtered = [self stringByRemovingEverythingAfterString:@"\n" from:obj];
                
                NSRange range = [filtered rangeOfString:@"http"];
                if (range.location==0) {
                    
                    filtered = [self stringByRemovingEverythingAfterString:@"\"" from:filtered];
                    
                    [links addObject:filtered];
                }
                else {
                    NSString *adjusted = [filtered substringFromIndex:range.location];
                    range = [adjusted rangeOfString:@"\""];
                    if (range.location==NSNotFound) {
                        
                        [links addObject:adjusted];
                    }
                    else {
                        
                        NSString *adjustedEnd = [adjusted substringToIndex:range.location];
                        [links addObject:adjustedEnd];
                    }
                }
            }
        }
    }];
    
    return links.copy;
}

+ (NSString *)stringByRemovingEverythingAfterString:(NSString *)this from:(NSString *)string {
    if (![string containsString:this])
        return string;
    
    // else
    NSRange range = [string rangeOfString:this];
    NSInteger len= (string.length - range.location);
    NSString *remove = [string substringWithRange:NSMakeRange(range.location, len)];
    
    return [string stringByReplacingOccurrencesOfString:remove withString:@""];
}

@end
