//
//  MediaTweetCell.m
//  Twitter
//
//  Created by Yingming Chen on 2/20/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "MediaTweetCell.h"
#import "UIImageView+AFNetworking.h"

@interface MediaTweetCell ()

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
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setTweet:(Tweet *)tweet {
    _tweet = tweet;
    [self.userProfileImageView setImageWithURL:[NSURL URLWithString:self.tweet.user.profileImageUrl]placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.userName.text = self.tweet.user.name;
    self.userScreenName.text = [NSString stringWithFormat:@"@%@", self.tweet.user.screenname];
    self.tweetText.text = self.tweet.text;
    [self.tweetText sizeToFit];
    self.retweetCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.retweetCount];
    if (self.tweet.tweetPhotoUrl != nil) {
        [self.tweetPhotoView setImageWithURL:[NSURL URLWithString:self.tweet.tweetPhotoUrl] placeholderImage:[UIImage imageNamed:@"login-background"]];
    } else {
        //[self.tweetPhotoView removeFromSuperview];
        [self.tweetPhotoView setImage:nil];
    }
    //[self.tweetPhotoView sizeToFit];
    if (self.tweet.retweeted) {
        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_on-16"]];
    } else {
        [self.retweetIcon setImage:[UIImage imageNamed:@"retweet_default-16"]];
    }
    
    if (self.tweet.favorited) {
        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_on-16"]];
    } else {
        [self.favoriteIcon setImage:[UIImage imageNamed:@"favorite_default-16"]];
    }
    
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", self.tweet.favoriteCount];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // This is to fix some bug that sometimes autolayout causing text in label doesn't wrap properly
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
}

@end
