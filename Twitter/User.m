//
//  User.m
//  Twitter
//
//  Created by Yingming Chen on 2/18/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "User.h"
#import "TwitterClient.h"

NSString * const UserDidLoginNotification = @"UserDidLoginNotification";
NSString * const UserDidLogoutNotification = @"UserDidLogoutNotification";

@interface User()

@property (nonatomic, strong) NSDictionary *dictionary;

@end

@implementation User

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if (self) {
        self.dictionary = dictionary;
        self.name = dictionary[@"name"];
        self.screenname = dictionary[@"screen_name"];
        self.profileImageUrl = dictionary[@"profile_image_url"];
        self.tagline = dictionary[@"description"];
        NSString *createAtString = dictionary[@"created_at"];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        formater.dateFormat = @"EEE MMM d HH:mm:ss Z y";
        self.createAt = [formater dateFromString:createAtString];
        self.favoritesCount = [dictionary[@"favourites_count"] integerValue];
        self.followersCount = [dictionary[@"followers_count"] integerValue];
        if ([dictionary[@"following"] integerValue] == 1) {
            self.following = YES;
        } else {
            self.following = NO;
        }
        self.friendsCount = [dictionary[@"friends_count"] integerValue];
        self.userId = dictionary[@"id_str"];
        self.location = dictionary[@"location"];
        if ([dictionary[@"verified"] integerValue] == 1) {
            self.verified = YES;
        } else {
            self.verified = NO;
        }
        self.profileBannerImage = dictionary[@"profile_banner_url"];
    }
    
    
    return self;
}

static User *_currentUser = nil;
NSString * const kCurrentUserKey = @"kCurrentUserKey";

+ (User *)currentUser {
    if (_currentUser == nil) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentUserKey];
        if (data != nil) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            _currentUser = [[User alloc] initWithDictionary:dictionary];
        }
    }
    return _currentUser;
}

+ (void)setCurrentUser:(User *)user {
    _currentUser = user;
    if (_currentUser != nil) {
        NSData  *data = [NSJSONSerialization dataWithJSONObject:user.dictionary options:0 error:NULL];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kCurrentUserKey];
    } else {
        // clear the saved object
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kCurrentUserKey];
    }

    // Force to save to disk
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)logout {
    [User setCurrentUser:nil];
    [[TwitterClient sharedInstance].requestSerializer removeAccessToken];
    // Notify the logout event
    [[NSNotificationCenter defaultCenter] postNotificationName:UserDidLogoutNotification object:nil];
}
@end
