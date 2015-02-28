//
//  LoginViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/17/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "LoginViewController.h"
#import "TwitterClient.h"
#import "TweetsViewController.h"
#import "ContainerViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIView *bottomLoginView;

@end

@implementation LoginViewController

- (IBAction)onLogin:(id)sender {
    TwitterClient *client = [TwitterClient sharedInstance];
    [client loginWithCompletion:^(User *user, NSError *error) {
        if (user) {
            //TweetsViewController *tvc = [[TweetsViewController alloc] init];
            ContainerViewController *cvc = [[ContainerViewController alloc] init];
            //UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:cvc];
            [self presentViewController:cvc animated:YES completion:nil];
            NSLog(@"user profile image %@", user.profileBannerImage);
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Failed to login"
                                                                           message:[NSString stringWithFormat:@("%@"), error.localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [self.loginButton setBackgroundColor:twitterBlue];
    [[self.loginButton layer] setCornerRadius:5.0f];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
