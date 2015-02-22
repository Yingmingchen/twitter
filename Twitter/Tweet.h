//
//  Tweet.h
//  Twitter
//
//  Created by Yingming Chen on 2/18/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface Tweet : NSObject

@property (nonatomic, assign) NSInteger favoriteCount;
@property (nonatomic, assign) BOOL favorited;
@property (nonatomic, strong) NSString *tweetId;
@property (nonatomic, assign) NSInteger retweetCount;
@property (nonatomic, assign) BOOL retweeted;
@property (nonatomic, strong) NSString *text; // Need to parse the text for retweet
// E.g., text = "RT @jamiesmiller: Great visit to @BoxHQ today.  Rethinking collaboration in the enterprise - keep it coming!! #howtomorrowworks #gofaster";
@property (nonatomic, strong) Tweet *childTweet; // for retweet/like/reply. For example, for retweet, it is under "retweeted_status"
@property (nonatomic, strong) NSDate *createAt;
@property (nonatomic, strong) User *user;
// TODO: add one for hashtags
// TODO: add one for media/urls
@property (nonatomic, strong) NSString *tweetPhotoUrl;
// TODO: add one hashtag

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (NSArray *)tweetsWithArray:(NSArray *)dictionaries;

@end
