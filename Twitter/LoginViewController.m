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
#import <QuartzCore/QuartzCore.h>

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]


@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIView *bottomLoginView;

@end

@implementation LoginViewController

- (IBAction)onLogin:(id)sender {
    TwitterClient *client = [TwitterClient sharedInstance];
    [client loginWithCompletion:^(User *user, NSError *error) {
        if (user) {
            TweetsViewController *tvc = [[TweetsViewController alloc] init];
            UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:tvc];
            [self presentViewController:nvc animated:YES completion:nil];
        } else {
            
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    // UIColorFromRGB(0x55ACEE);
    //[self.bottomLoginView setBackgroundColor:twitterBlue];
    //[[self.loginButton layer] setBorderColor:twitterBlue.CGColor];
    [self.loginButton setBackgroundColor:twitterBlue];
    //[[self.loginButton layer] setBorderWidth:1.0f];
    [[self.loginButton layer] setCornerRadius:5.0f];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
