//
//  ComposeViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "ComposeViewController.h"
#import "UIImageView+AFNetworking.h"
#import "User.h"
#import "TwitterClient.h"

@interface ComposeViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *profileTopVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet UITextView *tweetInputTextView;
@property (weak, nonatomic) IBOutlet UITextView *tweetInputPlaceholderView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;

@end

@implementation ComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.barTintColor = twitterBlue;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cancel-25"] style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Sent-25"] style:UIBarButtonItemStylePlain target:self action:@selector(onPost)];
    
    // Setup rotation related stuff to make sure our own elements below navigation bar
    // See http://stackoverflow.com/questions/23478724/autolayout-specify-spacing-between-view-and-navigation-bar
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self applyTopBarOffsetForOrientation:currentOrientation];
    
    User *currentUser = User.currentUser;
    [self.profilePicView setImageWithURL:[NSURL URLWithString:currentUser.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.nameLabel.text = currentUser.name;
    self.screenNameLabel.text = [NSString stringWithFormat:@"@%@", currentUser.screenname];
    
    self.tweetInputTextView.delegate = self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self applyTopBarOffsetForOrientation:toInterfaceOrientation];
    NSLog(@"rotate");
}

- (void)applyTopBarOffsetForOrientation:(UIInterfaceOrientation) orientation {
    BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    NSLog(@"orientation %ld", orientation);
    self.profileTopVerticalSpaceConstraint.constant = UIDeviceOrientationIsLandscape(orientation) && isPhone ? 52 : 64 + 8;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - text field event handlers

- (void)textViewDidChange:(UITextView *)textView {
    self.tweetInputPlaceholderView.hidden = YES;
    NSLog(@"tweet length %ld", textView.text.length);
}

#pragma mark - helper functions

- (void) onCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) onPost {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.tweetInputTextView.text forKey:@"status"];
    [[TwitterClient sharedInstance] tweet:params completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
