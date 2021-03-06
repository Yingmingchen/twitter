//
//  MediaTweetCell.m
//  Twitter
//
//  Created by Yingming Chen on 2/20/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "MediaTweetCell.h"
#import "UIImageView+AFNetworking.h"
#import "NSDate+DateTools.h"
#import "ComposeViewController.h"
#import "TwitterClient.h"

@interface MediaTweetCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userProfileImageViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timeStampTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tweetPhotoViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *retweetStatusIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetUserLabel;

@property (weak, nonatomic) IBOutlet UIImageView *userProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *userScreenName;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UILabel *tweetText;
@property (weak, nonatomic) IBOutlet UIImageView *tweetPhotoView;
@property (weak, nonatomic) IBOutlet UIButton *retweetButton;
@property (weak, nonatomic) IBOutlet UILabel *retweetCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UILabel *favoriteCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;

@property (weak, nonatomic) Tweet *tweetToShow;

@end

@implementation MediaTweetCell

- (void)awakeFromNib {
    // This is to fix some bug that sometimes autolayout causing text in label doesn't wrap properly
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
    
    self.userProfileImageView.layer.cornerRadius = 3;
    self.userProfileImageView.clipsToBounds = YES;
    
    self.tweetPhotoView.layer.cornerRadius = 3;
    self.tweetPhotoView.clipsToBounds = YES;
    
    UITapGestureRecognizer *profileTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfilePicTapped)];
    [profileTapGestureRecognizer setNumberOfTouchesRequired:1];
    [profileTapGestureRecognizer setNumberOfTapsRequired:1];
    [self.userProfileImageView addGestureRecognizer:profileTapGestureRecognizer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - event handlers

- (void)onProfilePicTapped
{
    NSLog(@"TAP");
    [self.delegate MediaTweetCell:self didProfilePicTapped:self.tweetToShow.user];
}

// handle reply/retweet/favorite
// @TODO: rename it
- (IBAction)onReply:(id)sender {
    if (sender == self.retweetButton) {
        if ([self.tweet.user.userId isEqualToString:[User currentUser].userId]) {
            NSLog(@"Can't retweet your own tweet");
            return;
        }
        if (!self.tweet.retweeted) {
            self.tweet.retweeted = YES;
            [self.delegate MediaTweetCell:self didRetweetButtonClicked:YES];
            UIColor *highlightGreen = [UIColor  colorWithRed:119.0f/255.0f green:178.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
            self.retweetCountLabel.textColor = highlightGreen;
        }
    } else if (sender == self.replyButton){
        [self.delegate MediaTweetCell:self didRelyButtonClicked:self.tweet];
    } else if (sender == self.favoriteButton){
        self.tweet.favorited = !self.tweet.favorited;
        if (self.tweet.favorited) {
            [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_on-16"]];
            self.tweet.favoriteCount ++;
            self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.favoriteCount];
            UIColor *highlightYellow = [UIColor  colorWithRed:255.0f/255.0f green:172.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
            self.favoriteCountLabel.textColor = highlightYellow;
            [[TwitterClient sharedInstance] favorite:self.tweet.tweetId completion:nil];
        } else {
            [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_default-16"]];
            self.tweet.favoriteCount --;
            self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.favoriteCount];
            self.favoriteCountLabel.textColor = [UIColor lightGrayColor];
            [[TwitterClient sharedInstance] unfavorite:self.tweet.tweetId completion:nil];
        }
        [self.delegate MediaTweetCell:self didFavoriteTweet:self.tweet.favorited];
    }
}

#pragma mark - setters

- (void)setTweet:(Tweet *)tweet {
    _tweet = tweet;
    Tweet *tweetToShow = tweet;

    if (self.tweet.childTweet != nil) {
        tweetToShow = self.tweet.childTweet;
        self.retweetStatusIcon.hidden = NO;
        self.retweetUserLabel.hidden = NO;
        self.retweetUserLabel.text = [NSString stringWithFormat:@"%@ retweeted", self.tweet.user.name];
        self.userProfileImageViewTopConstraint.constant = 32.0;
        self.timeStampTopConstraint.constant = 32.0;
    } else {
        self.retweetStatusIcon.hidden = YES;
        self.retweetUserLabel.hidden = YES;
        self.userProfileImageViewTopConstraint.constant = 8.0;
        self.timeStampTopConstraint.constant = 8.0;
    }
    
    self.tweetToShow = tweetToShow;
    
    [self.userProfileImageView setImageWithURL:[NSURL URLWithString:tweetToShow.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.userName.text = tweetToShow.user.name;
    self.userScreenName.text = [NSString stringWithFormat:@"@%@", tweetToShow.user.screenname];
    self.tweetText.text = tweetToShow.text;
    [self.tweetText sizeToFit];
    self.retweetCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.retweetCount];
    self.timeStamp.text = tweetToShow.createAt.shortTimeAgoSinceNow;
    
    if (tweetToShow.tweetPhotoUrl != nil) {
        [self.tweetPhotoView setImageWithURL:[NSURL URLWithString:tweetToShow.tweetPhotoUrl] placeholderImage:[UIImage imageNamed:@"placeholder_image18"]];
        
        // We need to lower the priority of this constraint to 999 from 1000, otherwise, we get constraint confliction
        // involving UIView-Encapsulated-Layout-Height.
        // See http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i.
        self.tweetPhotoViewHeightConstraint.constant = 150.0;
    } else {
        [self.tweetPhotoView setImage:nil];
        self.tweetPhotoViewHeightConstraint.constant = 0.0;
    }

    if (tweetToShow.retweeted) {
        [self.retweetButton.imageView setImage:[UIImage imageNamed:@"retweet_on-16"]];
        UIColor *highlightGreen = [UIColor  colorWithRed:119.0f/255.0f green:178.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
        self.retweetCountLabel.textColor = highlightGreen;
    } else {
        [self.retweetButton.imageView setImage:[UIImage imageNamed:@"retweet_default-16"]];
        self.retweetCountLabel.textColor = [UIColor lightGrayColor];
    }
    
    if (tweetToShow.favorited) {
        [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_on-16"]];
        UIColor *highlightYellow = [UIColor  colorWithRed:255.0f/255.0f green:172.0f/255.0f blue:51.0f/255.0f alpha:1.0f];
        self.favoriteCountLabel.textColor = highlightYellow;
    } else {
        [self.favoriteButton.imageView setImage:[UIImage imageNamed:@"favorite_default-16"]];
        self.favoriteCountLabel.textColor = [UIColor lightGrayColor];
    }
    
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.favoriteCount];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // This is to fix some bug that sometimes autolayout causing text in label doesn't wrap properly
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
}

@end
