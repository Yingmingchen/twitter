//
//  MediaTweetCell.h
//  Twitter
//
//  Created by Yingming Chen on 2/20/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tweet.h"

@class MediaTweetCell;

@protocol MediaTweetCellDelegate <NSObject>

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didFavoriteTweet:(BOOL)value;
- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didRelyButtonClicked:(Tweet *)originlTweet;
- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didRetweetButtonClicked:(BOOL)value;

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didProfilePicTapped:(User *)user;

@end

@interface MediaTweetCell : UITableViewCell

@property (nonatomic, strong) Tweet * tweet;

@property (nonatomic, weak) id<MediaTweetCellDelegate> delegate;

@end
