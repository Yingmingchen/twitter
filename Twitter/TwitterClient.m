//
//  TwitterClient.m
//  Twitter
//
//  Created by Yingming Chen on 2/17/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "TwitterClient.h"
#import "Tweet.h"

NSString * const kTwitterConsumerKey = @"NwlJvq274whdPxt2KNBw89ikO";
NSString * const kTwitterConsumerSecret = @"iZw2uzjwcq7AIbHuaCY5VeIMDcI0YE52BRybFvBAFYR2g2qwAV";
NSString * const kTwitterBaseUrl = @"https://api.twitter.com";

@interface TwitterClient ()

@property (nonatomic, strong) void (^loginCompletion)(User *user, NSError *error);

@end

@implementation TwitterClient

#pragma mark - login related

- (void)loginWithCompletion:(void (^)(User *user, NSError *error))completion {
    self.loginCompletion = completion;
    // To clear your previous login state
    [self.requestSerializer removeAccessToken];
    [self fetchRequestTokenWithPath:@"oauth/request_token" method:@"GET" callbackURL:[NSURL URLWithString:@"cptwitterdemo://oauth"] scope:nil success:^(BDBOAuthToken *requestToken) {
        NSURL *authUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authorize?oauth_token=%@", requestToken.token]];
        [[UIApplication sharedApplication] openURL:authUrl];
    } failure:^(NSError *error) {
        NSLog(@"Faile dot get request token with error %@", error);
        self.loginCompletion(nil, error);
    }];
}

- (void)openURL:(NSURL *)url {
    // third step to get the access token
    [self fetchAccessTokenWithPath:@"oauth/access_token" method:@"POST" requestToken:[BDBOAuthToken tokenWithQueryString:url.query] success:^(BDBOAuthToken *accessToken) {
        [self.requestSerializer saveAccessToken:accessToken];
        
        // Get current user info
        [self GET:@"1.1/account/verify_credentials.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            User *user = [[User alloc] initWithDictionary:responseObject];
            [self getProfileBanner:user.userId completion:^(NSDictionary *bannerData, NSError *error) {
                [user setBannerUrl:bannerData];
                [User setCurrentUser:user];
                self.loginCompletion(user, nil);
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user data %@", error);
            self.loginCompletion(nil, error);
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to get access token %@", error);
        self.loginCompletion(nil, error);
    }];
}

#pragma mark - twitter API endpoint wrappers

// Helper to pull the homeline
- (void)homeTimelineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/statuses/home_timeline.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get tweets with error %@", error);
        completion(nil, error);
    }];
}

- (void)mentionsWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/statuses/mentions_timeline.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get tweets with error %@", error);
        completion(nil, error);
    }];
}

- (void)userTimelineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/statuses/user_timeline.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user timeline tweets with error %@", error);
        completion(nil, error);
    }];
}

- (void)userFavoritesWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion {
    [self GET:@"1.1/favorites/list.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *tweets = [Tweet tweetsWithArray:responseObject];
        completion(tweets, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user favorite tweets with error %@", error);
        completion(nil, error);
    }];
}

// Helper to tweet
- (void)tweet:(NSDictionary *)params completion:(void (^)(Tweet *tweet, NSError *error))completion {
    [self POST:@"1.1/statuses/update.json" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        Tweet *newTweet = [[Tweet alloc] initWithDictionary:responseObject];
        if (completion != nil) {
            completion(newTweet, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"tweet failed %@", error);
        if (completion != nil) {
            completion(nil, error);
        }
    }];
}

- (void)retweet:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion {
    NSString *retweetEndpoint = [NSString stringWithFormat:@"1.1/statuses/retweet/%@.json", tweetIdStr];
    [self POST:retweetEndpoint parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion != nil) {
            completion(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"favorite failed %@", error);
        if (completion != nil) {
            completion(error);
        }
    }];
}


- (void)favorite:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@([tweetIdStr integerValue]) forKey:@"id"];
    [self POST:@"1.1/favorites/create.json" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion != nil) {
            completion(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"favorite failed %@", error);
        if (completion != nil) {
            completion(error);
        }
    }];
}

- (void)unfavorite:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@([tweetIdStr integerValue]) forKey:@"id"];
    [self POST:@"1.1/favorites/destroy.json" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion != nil) {
            completion(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"unfavorite failed %@", error);
        if (completion != nil) {
            completion(error);
        }
    }];
}

- (void)getProfileBanner:(NSString *)userIdStr completion:(void (^)(NSDictionary *bannerData, NSError *error))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@([userIdStr integerValue]) forKey:@"user_id"];
    [self GET:@"1.1/users/profile_banner.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get user banner with error %@", error);
        completion(nil, error);
    }];
}

// Singleton
+ (TwitterClient *)sharedInstance {
    static TwitterClient *instance = nil;
    
    // Use dispatch_once to make sure the block inside is thread safe.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[TwitterClient alloc] initWithBaseURL:[NSURL URLWithString:kTwitterBaseUrl] consumerKey:kTwitterConsumerKey consumerSecret:kTwitterConsumerSecret];
        }
    });
    
    return instance;
}

@end
