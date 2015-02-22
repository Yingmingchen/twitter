//
//  ComposeViewController.h
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tweet.h"

@class ComposeViewController;

@protocol ComposeViewControllerDelegate <NSObject>

- (void)ComposeViewController:(ComposeViewController *)composeViewController didTweet:(Tweet *)tweet;

@end

@interface ComposeViewController : UIViewController

@property (strong, nonatomic) Tweet *originalTweet;

@property (nonatomic, weak) id<ComposeViewControllerDelegate> delegate;

@end
