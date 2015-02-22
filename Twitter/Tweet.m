//
//  Tweet.m
//  Twitter
//
//  Created by Yingming Chen on 2/18/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.text = dictionary[@"text"];
        NSString *createAtString = dictionary[@"created_at"];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        formater.dateFormat = @"EEE MMM d HH:mm:ss Z y";
        self.createAt = [formater dateFromString:createAtString];
        self.user = [[User alloc] initWithDictionary:dictionary[@"user"]];
        self.favoriteCount = [dictionary[@"favorite_count"] integerValue];
        self.favorited = [dictionary[@"favorited"] boolValue];
        self.tweetId = dictionary[@"id_str"];
        self.retweetCount = [dictionary[@"retweet_count"] integerValue];
        self.retweeted = [dictionary[@"retweeted"] boolValue];
        NSDictionary *childTweetDictionary = dictionary[@"retweeted_status"];
        if (childTweetDictionary != nil) {
            self.childTweet = [[Tweet alloc] initWithDictionary:childTweetDictionary];
        } else {
            self.childTweet = nil;
        }

        self.tweetPhotoUrl = nil;
        self.tweetPhotoUrls = [NSMutableArray array];
        NSArray *mediaArray = [dictionary valueForKeyPath:@"extended_entities.media"];
        if (mediaArray != nil && mediaArray.count > 0) {
            NSDictionary *mediaData = mediaArray[0];
            if ([mediaData[@"type"] isEqualToString:@"photo"]) {
                self.tweetPhotoUrl = mediaData[@"media_url"];
            }
            for (NSDictionary *data in mediaArray) {
                if ([data[@"type"] isEqualToString:@"photo"]) {
                    [self.tweetPhotoUrls addObject:data[@"media_url"]];
                }
            }
        }
    }
    return self;
}

+ (NSArray *)tweetsWithArray:(NSArray *)dictionaries {
    NSMutableArray *tweets = [NSMutableArray array];
    
    for (NSDictionary *dictionary in dictionaries) {
        [tweets addObject:[[Tweet alloc] initWithDictionary:dictionary]];
    }
    
    return tweets;
}

@end
