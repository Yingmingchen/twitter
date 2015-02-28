//
//  ProfileViewController.h
//  Twitter
//
//  Created by Yingming Chen on 2/25/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "ContainerViewController.h"

@interface ProfileViewController : UIViewController

@property (nonatomic, strong) User *user;

- (ProfileViewController *)initWithParentContainerViewController:(ContainerViewController *)parentContainerViewController;

@end
