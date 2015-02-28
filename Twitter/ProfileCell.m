//
//  ProfileCell.m
//  Twitter
//
//  Created by Yingming Chen on 2/26/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "ProfileCell.h"
#import "UIImageView+AFNetworking.h"

@interface ProfileCell ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userScreenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followerCountLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tableDataSourceControl;

- (IBAction)onDataSourceControl:(UISegmentedControl *)sender;
@end

@implementation ProfileCell

- (void)awakeFromNib {
    // Initialization code
    self.tableDataSourceControl.selectedSegmentIndex = TableDataSourceIndexTweets;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(User *)user {
    _user = user;
    NSLog(@"render user");
    [self.profileImageView setImageWithURL:[NSURL URLWithString:self.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.userNameLabel.text = self.user.name;
    self.userScreenNameLabel.text = self.user.screenname;
    self.followerCountLabel.text = [NSString stringWithFormat:@"%ld", self.user.followersCount];
    self.followingCountLabel.text = [NSString stringWithFormat:@"%ld", self.user.friendsCount];
}

- (IBAction)onDataSourceControl:(UISegmentedControl *)sender {
    NSLog(@"source control %ld", sender.selectedSegmentIndex);
    [self.delegate dataSourceDidChange:sender.selectedSegmentIndex];
}

@end
