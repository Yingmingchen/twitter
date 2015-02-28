//
//  TweetsViewController.h
//  Twitter
//
//  Created by Yingming Chen on 2/19/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContainerViewController.h"

typedef NS_ENUM(NSInteger, TweetsViewSourceIndex) {
    TweetsViewSourceIndexHomeTimeline = 0,
    TweetsViewSourceIndexMentions = 1
};

@interface TweetsViewController : UIViewController

- (TweetsViewController *)initWithParentContainerViewController:(ContainerViewController *)parentContainerViewController tweetsViewSourceIndex:(TweetsViewSourceIndex)tweetsViewSourceIndex;

@end
