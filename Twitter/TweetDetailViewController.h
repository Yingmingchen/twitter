//
//  TweetDetailViewController.h
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tweet.h"

@class TweetDetailViewController;

@protocol TweetDetailViewControllerDelegate <NSObject>

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didFavoriteTweet:(BOOL)value;
- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didRelyButtonClicked:(BOOL)value;
- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didRetweetButtonClicked:(BOOL)value;

@end


@interface TweetDetailViewController : UIViewController

@property (nonatomic, strong) Tweet *tweet;

@property (nonatomic, weak) id<TweetDetailViewControllerDelegate> delegate;

- (void)setTweet:(Tweet *)tweet;

@end
