//
//  User.h
//  Twitter
//
//  Created by Yingming Chen on 2/18/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

// Expose them for other files to use;
extern NSString * const UserDidLoginNotification;
extern NSString * const UserDidLogoutNotification;


@interface User : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *screenname;
@property (nonatomic, strong) NSString *profileImageUrl;
@property (nonatomic, strong) NSString *tagline;
@property (nonatomic, strong) NSDate *createAt;
@property (nonatomic, assign) NSInteger favoritesCount;
@property (nonatomic, assign) NSInteger followersCount;
@property (nonatomic, assign) BOOL following;
@property (nonatomic, assign) NSInteger friendsCount; // following count
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *profileBannerImage;
@property (nonatomic, assign) BOOL verified;

- (id)initWithDictionary:(NSDictionary *)dictionary;

// Fake getter/setter for class property
+ (User *)currentUser;
+ (void)setCurrentUser:(User *)user;

+ (void)logout;

@end
