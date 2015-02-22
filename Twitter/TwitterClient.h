//
//  TwitterClient.h
//  Twitter
//
//  Created by Yingming Chen on 2/17/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "BDBOAuth1RequestOperationManager.h"
#import "User.h"
#import "Tweet.h"

@interface TwitterClient : BDBOAuth1RequestOperationManager

+ (TwitterClient *)sharedInstance;

- (void)loginWithCompletion:(void (^)(User *user, NSError *error))completion;

- (void)openURL:(NSURL *)url;

- (void)homeTimelineWithParams:(NSDictionary *)params completion:(void (^)(NSArray *tweets, NSError *error))completion;

- (void)tweet:(NSDictionary *)params completion:(void (^)(Tweet *tweet, NSError *error))completion;

- (void)favorite:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion;
- (void)unfavorite:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion;
- (void)retweet:(NSString *)tweetIdStr completion:(void (^)(NSError *error))completion;

@end
