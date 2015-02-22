//
//  TweetDetailViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "TweetDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "NSDate+DateTools.h"
#import "TwitterClient.h"

@interface TweetDetailViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaCollectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *profileTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetIconTopConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *retweetIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetUserName;
@property (weak, nonatomic) IBOutlet UIImageView *tweetUserProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *tweetUserName;
@property (weak, nonatomic) IBOutlet UILabel *tweetUserScreenName;
@property (weak, nonatomic) IBOutlet UILabel *tweetText;
@property (weak, nonatomic) IBOutlet UICollectionView *mediaCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *retweetCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *retweetTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UIButton *retweetButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;

@property (nonatomic, assign) NSInteger navigationBarHeight;
@property (nonatomic, assign) NSInteger relativeProfileTopConstraint;

@end

@implementation TweetDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Tweet";
    // Setup rotation related stuff to make sure our own elements below navigation bar
    // See http://stackoverflow.com/questions/23478724/autolayout-specify-spacing-between-view-and-navigation-bar
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self applyTopBarOffsetForOrientation:currentOrientation];
    // Need to to do this here instead of inside setTweet because those IBOutlets were nil at that time.
    [self renderTweet];
    NSLog(@"view did load");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onReply)];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self applyTopBarOffsetForOrientation:toInterfaceOrientation];
    NSLog(@"rotate");
}

- (void)applyTopBarOffsetForOrientation:(UIInterfaceOrientation) orientation {
    BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    NSLog(@"orientation %ld", orientation);
    self.navigationBarHeight = UIDeviceOrientationIsLandscape(orientation) && isPhone ? 52 : 64;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - event handlers

- (IBAction)onButtonClick:(id)sender {
    if (sender == self.retweetButton) {
        NSLog(@"Click retweet for %@", self.tweet);
        if (!self.tweet.retweeted) {
            [self.delegate TweetDetailViewController:self didRetweetButtonClicked:YES];
        }
    } else if (sender == self.replyButton){
        NSLog(@"Click reply");
        [self.delegate TweetDetailViewController:self didRelyButtonClicked:YES];
    } else if (sender == self.favoriteButton){
        NSLog(@"Click favorite");
        self.tweet.favorited = !self.tweet.favorited;
        if (self.tweet.favorited) {
            NSLog(@"favorite id %@", self.tweet.tweetId);
            [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_on-16"]];
            self.tweet.favoriteCount ++;
            self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.favoriteCount];
            [[TwitterClient sharedInstance] favorite:self.tweet.tweetId completion:nil];
        } else {
            [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_default-16"]];
            self.tweet.favoriteCount --;
            self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.favoriteCount];
            [[TwitterClient sharedInstance] unfavorite:self.tweet.tweetId completion:nil];
        }
        [self.delegate TweetDetailViewController:self didFavoriteTweet:self.tweet.favorited];
    }
}

- (void)onReply {
    [self.delegate TweetDetailViewController:self didRelyButtonClicked:YES];
}

#pragma mark - custom setters

- (void)setTweet:(Tweet *)tweet {
    NSLog(@"set tweet %@", tweet);
    _tweet = tweet;
}

#pragma mark - helper function

- (void)renderTweet {
    Tweet *tweetToShow = self.tweet;
    
    if (self.tweet.childTweet != nil) {
        tweetToShow = self.tweet.childTweet;
        self.retweetIcon.hidden = NO;
        self.retweetUserName.hidden = NO;
        self.retweetUserName.text = [NSString stringWithFormat:@"%@ retweeted", self.tweet.user.name];
        self.relativeProfileTopConstraint = 32;
        self.retweetIconTopConstraint.constant = self.navigationBarHeight + 8;
        self.profileTopConstraint.constant = self.navigationBarHeight + self.relativeProfileTopConstraint;
    } else {
        self.retweetIcon.hidden = YES;
        self.retweetUserName.hidden = YES;
        self.relativeProfileTopConstraint = 8;
        self.profileTopConstraint.constant = self.navigationBarHeight + self.relativeProfileTopConstraint;
    }
    
    [self.tweetUserProfileImage setImageWithURL:[NSURL URLWithString:tweetToShow.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.tweetUserName.text = tweetToShow.user.name;
    self.tweetUserScreenName.text = [NSString stringWithFormat:@"@%@", tweetToShow.user.screenname];
    self.tweetText.text = tweetToShow.text;
    [self.tweetText sizeToFit];
    self.retweetCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.retweetCount];
    if (tweetToShow.retweetCount <= 1) {
        self.retweetTextLabel.text = @"RETWEET";
    } else {
        self.retweetTextLabel.text = @"RETWEETS";
    }
    
    self.timestampLabel.text = [tweetToShow.createAt formattedDateWithFormat:@"MM/d/yy, HH:mm"];
    //    self.timeStamp.text = tweetToShow.createAt.shortTimeAgoSinceNow;
    
    if (tweetToShow.tweetPhotoUrl != nil) {
        //        [self.tweetPhotoView setImageWithURL:[NSURL URLWithString:tweetToShow.tweetPhotoUrl] placeholderImage:[UIImage imageNamed:@"Twitter_logo_blue"]];
        
        // We need to lower the this constraint's priority to 999 instead of 1000, otherwise, we get constraint confliction
        // involving UIView-Encapsulated-Layout-Height.
        // See http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i.
        self.mediaCollectionViewHeightConstraint.constant = 150.0;
    } else {
        //[self.tweetPhotoView setImage:nil];
        self.mediaCollectionViewHeightConstraint.constant = 0.0;
    }
    
    //    if (tweetToShow.retweeted) {
    //        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_on-16"]];
    //    } else {
    //        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_default-16"]];
    //    }
    //
    //    if (tweetToShow.favorited) {
    //        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_on-16"]];
    //    } else {
    //        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_default-16"]];
    //    }
    //
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.favoriteCount];
    if (tweetToShow.favoriteCount <= 1) {
        self.favoriteTextLabel.text = @"FAVORITE";
    } else {
        self.favoriteTextLabel.text = @"FAVORITES";
    }
}

@end
