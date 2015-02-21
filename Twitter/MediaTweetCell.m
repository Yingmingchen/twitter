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
@property (weak, nonatomic) IBOutlet UIImageView *replyIcon;
@property (weak, nonatomic) IBOutlet UIImageView *retweetIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteIcon;
@property (weak, nonatomic) IBOutlet UILabel *favoriteCountLabel;

@end

@implementation MediaTweetCell

- (void)awakeFromNib {
    // Initialization code
    // This is to fix some bug that sometimes autolayout causing text in label doesn't wrap properly
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
    
    self.userProfileImageView.layer.cornerRadius = 3;
    self.userProfileImageView.clipsToBounds = YES;
    
    self.tweetPhotoView.layer.cornerRadius = 3;
    self.tweetPhotoView.clipsToBounds = YES;
    
    //self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

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
    
    [self.userProfileImageView setImageWithURL:[NSURL URLWithString:tweetToShow.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.userName.text = tweetToShow.user.name;
    self.userScreenName.text = [NSString stringWithFormat:@"@%@", tweetToShow.user.screenname];
    self.tweetText.text = tweetToShow.text;
    [self.tweetText sizeToFit];
    self.retweetCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.retweetCount];
    self.timeStamp.text = tweetToShow.createAt.shortTimeAgoSinceNow;
    
    if (tweetToShow.tweetPhotoUrl != nil) {
        [self.tweetPhotoView setImageWithURL:[NSURL URLWithString:tweetToShow.tweetPhotoUrl] placeholderImage:[UIImage imageNamed:@"Twitter_logo_blue"]];
        
        // We need to lower the this constraint's priority to 999 instead of 1000, otherwise, we get constraint confliction
        // involving UIView-Encapsulated-Layout-Height.
        // See http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i.
        self.tweetPhotoViewHeightConstraint.constant = 150.0;
    } else {
        [self.tweetPhotoView setImage:nil];
        self.tweetPhotoViewHeightConstraint.constant = 0.0;
    }

    if (tweetToShow.retweeted) {
        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_on-16"]];
    } else {
        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_default-16"]];
    }
    
    if (tweetToShow.favorited) {
        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_on-16"]];
    } else {
        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_default-16"]];
    }
    
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", tweetToShow.favoriteCount];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // This is to fix some bug that sometimes autolayout causing text in label doesn't wrap properly
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
}

@end
