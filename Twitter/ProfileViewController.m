//
//  ProfileViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/25/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileCell.h"
#import "UIImageView+AFNetworking.h"
#import "TwitterClient.h"
#import "MediaTweetCell.h"
#import "ComposeViewController.h"
#import "TweetDetailViewController.h"

@interface ProfileViewController () <UITableViewDataSource, UITableViewDelegate, MediaTweetCellDelegate, ProfileCellDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigProfileTableTopAlignment;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigProfileLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *profileBannerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *profileBannerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *bigProfileImageView;

@property (nonatomic, weak) ContainerViewController *parentContainerViewController;

@property (nonatomic, strong) NSMutableArray *tweets;
@property (nonatomic, assign) BOOL isLoadingOnTheFly;
@property (nonatomic, assign) BOOL isInfiniteLoading;
@property (nonatomic, assign) CGFloat currentBannerHeightConstraint;

@end

// TODO: handle all the delegates functions

@implementation ProfileViewController

- (ProfileViewController *)initWithParentContainerViewController:(ContainerViewController *)parentContainerViewController {
    self = [super init];
    if (self) {
        self.parentContainerViewController = parentContainerViewController;
        self.isLoadingOnTheFly = NO;
        self.isInfiniteLoading = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Set navigation bar style to be transparent
    // http://stackoverflow.com/questions/19082963/how-to-make-completely-transparent-navigation-bar-in-ios-7
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    // Hide the navigation bar at the beginning
    // self.navigationController.navigationBarHidden = YES;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Previous-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenu)];
    
    // Setup table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 150;
    [self.tableView registerNib:[UINib nibWithNibName:@"ProfileCell" bundle:nil] forCellReuseIdentifier:@"ProfileCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MediaTweetCell" bundle:nil] forCellReuseIdentifier:@"MediaTweetCell"];
    // This is to make sure that table view starts from the top instead of after the navigation bar
    // See http://stackoverflow.com/questions/18900428/ios-7-uitableview-shows-under-status-bar
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.bigProfileImageView setImageWithURL:[NSURL URLWithString:self.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.bigProfileImageView.layer.cornerRadius = 3;
    self.bigProfileImageView.clipsToBounds = YES;
    self.bigProfileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.bigProfileImageView.layer.borderWidth = 2.5;
    
    if (self.user.profileBannerImage != nil) {
        NSLog(@"set profile banner image");
        [self.profileBannerView setImageWithURL:[NSURL URLWithString:self.user.profileBannerImage] placeholderImage:[UIImage imageNamed:@"background"]];
    } else {
        // consider calling getBannerUrl()
    }
    
    UIPanGestureRecognizer *tablePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    UIPanGestureRecognizer *bannerPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    // This is needed to capture vertical pan (which is already listened by default table view
    // See http://stackoverflow.com/questions/10183584/uipangesturerecognizer-on-uitableviewcell-overrides-uitableviews-scroll-view-ge
    tablePanGestureRecognizer.delegate = self;
    bannerPanGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:tablePanGestureRecognizer];
    [self.profileBannerView addGestureRecognizer:bannerPanGestureRecognizer];
    
    
    // TODO: since profile banner is loaded asyncly. May need a delegate from User class to this
    if (self.user.profileBannerImage != nil) {
        NSLog(@"set profile banner image");
        [self.profileBannerView setImageWithURL:[NSURL URLWithString:self.user.profileBannerImage] placeholderImage:[UIImage imageNamed:@"background"]];
    } else {
        // consider calling getBannerUrl()
    }
    
    [self loadTimelineWithParams:nil dataSourceIndex:TableDataSourceIndexTweets];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - loading functions

- (void)loadTimelineWithParams:(NSMutableDictionary *)params dataSourceIndex:(TableDataSourceIndex)dataSourceIndex{
    self.isLoadingOnTheFly = YES;
    
    // TODO: move this under Tweet class (ORM) instead of calling it here
    NSMutableDictionary *finalParams = params;
    
    if (finalParams == nil) {
        finalParams = [[NSMutableDictionary alloc] init];
        [finalParams setObject:@([self.user.userId integerValue]) forKey:@"user_id"];
        [finalParams setObject:@(20) forKey:@"count"];
    }
    
    void (^handleLoadCompletion)(NSArray *, NSError *) = ^(NSArray *tweets, NSError *error){
        if (!error) {
            if (self.isInfiniteLoading) {
                [self.tweets addObjectsFromArray:tweets];
            } else {
                self.tweets = [NSMutableArray arrayWithArray:tweets];
            }
            
            [self.tableView reloadData];
        } else {
            NSLog(@"failed to load home timeline data with error %@", error);
        }
        
        //        if (self.isPullDownRefreshing) {
        //            [self.tableRefreshControl endRefreshing];
        //        }
        //        if (self.isInfiniteLoading) {
        //            [self.infiniteLoadingView stopAnimating];
        //        }
        
        self.isLoadingOnTheFly = NO;
        //        self.isPullDownRefreshing = NO;
        self.isInfiniteLoading = NO;
    };
    
    if (dataSourceIndex == TableDataSourceIndexTweets) {
        [[TwitterClient sharedInstance] userTimelineWithParams:finalParams completion:handleLoadCompletion];
    } else if (dataSourceIndex == TableDataSourceIndexFavorites) {
        [[TwitterClient sharedInstance] userFavoritesWithParams:finalParams completion:handleLoadCompletion];
    }
}

#pragma mark - delegates

- (void)dataSourceDidChange:(TableDataSourceIndex)index {
    [self loadTimelineWithParams:nil dataSourceIndex:index];
}

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didFavoriteTweet:(BOOL)value {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:mediaTweetCell];
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:indexPath, nil];
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
}

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didRelyButtonClicked:(Tweet *)originlTweet {
    [self onReply:originlTweet];
}

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didProfilePicTapped:(User *)user {
    [self onProfilePicTapped:user];
}


- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didRetweetButtonClicked:(BOOL)value {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:mediaTweetCell];
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:indexPath, nil];
    Tweet *tweet = self.tweets[indexPath.row];
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
    [[TwitterClient sharedInstance] retweet:tweet.tweetId completion:nil];
}


#pragma mark - gesture controls

// Need to allow parent container to handle pan gesture while the table view scroll still working
// See http://stackoverflow.com/questions/17614609/table-view-doesnt-scroll-when-i-use-gesture-recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (void)onPan:(UIPanGestureRecognizer *)sender {
    CGPoint currentPoint = [sender locationInView:self.view];
    CGPoint velocity = [sender velocityInView:self.view];
    NSLog(@"on my pan");
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.currentBannerHeightConstraint = self.profileBannerHeightConstraint.constant;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:self.view];
        CGFloat newHeight = (self.currentBannerHeightConstraint + translation.y);
        if (newHeight >= 100) {
            self.profileBannerHeightConstraint.constant = newHeight;
            [self.view bringSubviewToFront:self.bigProfileImageView];
        }

        if (newHeight >= 100 && newHeight < 150) {
            //self.bigProfileImageView.hidden = NO;
            CGFloat scale = newHeight/150;
            self.bigProfileImageView.transform = CGAffineTransformMakeScale(scale, scale);
            //self.bigProfileTopConstraint.constant = newHeight + 32 - scale*48;
            self.bigProfileTableTopAlignment.constant = scale*48 - 32;
            //self.bigProfileLeadingConstraint.constant = 8 + 24 - 24*scale;
        } else if (newHeight > 150){
            //self.bigProfileImageView.hidden = NO;
            self.bigProfileImageView.transform = CGAffineTransformIdentity;
            self.bigProfileTableTopAlignment.constant = 16;
        } else {
            self.bigProfileTableTopAlignment.constant = 0;
            [self.view bringSubviewToFront:self.profileBannerView];
        }
        
        self.tableViewTopConstraint.constant = newHeight;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.profileBannerHeightConstraint.constant >= 150) {
            self.profileBannerHeightConstraint.constant = 150;
            self.tableViewTopConstraint.constant = 150;
            self.bigProfileTableTopAlignment.constant = 16;
            [self.view setNeedsLayout];
            [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
                //[self.profileBannerView layoutIfNeeded];
                [self.view layoutIfNeeded];
                [self.view bringSubviewToFront:self.bigProfileImageView];
            } completion:^(BOOL finished) {
            }];
        } else { // moving left
        }
    }
}

#pragma mark - Table methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    CGRect newFrame = self.tableView.tableHeaderView.frame;
//    newFrame.size.height = self.tableHeaderHeight;
//    self.headerView.frame = newFrame;
//    
//    return self.headerView;
//    
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
        cell.user = self.user;
        cell.delegate = self;
        return cell;
    }
    
    Tweet *tweet = self.tweets[indexPath.row - 1];
    MediaTweetCell *mcell = [tableView dequeueReusableCellWithIdentifier:@"MediaTweetCell"];
    mcell.tweet = tweet;
    mcell.delegate = self;
    
    // Infinite loading
//    if (indexPath.row == self.tweets.count - 1 && !self.isLoadingOnTheFly) {
//        NSMutableDictionary *params = [NSMutableDictionary dictionary];
//        // See https://dev.twitter.com/rest/public/timelines
//        NSInteger max_id = [tweet.tweetId integerValue] - 1;
//        [params setObject:@(max_id) forKey:@"max_id"];
//        self.isInfiniteLoading = YES;
//        [self loadHomelineWithParams:params];
//    }
    return mcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

// TODO: need to fully solve this issue: http://stackoverflow.com/questions/25937827/table-view-cells-jump-when-selected-on-ios-8
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 150;
    }
    
    Tweet *tweet = self.tweets[indexPath.row - 1];
    if (tweet.tweetPhotoUrl != nil) {
        return 265.0;
    } else {
        return 100.0;
    }
}

#pragma mark - helper functions

- (void)onMenu {
    if (self.parentContainerViewController) {
        [self.parentContainerViewController toggleMenu];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)presentProfileView:(User *)user {
    ProfileViewController *pvc = [[ProfileViewController alloc] init];
    pvc.user = user;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)onProfilePicTapped:(User *)user {
    // Don't try to present your own profile again
    if ([user.userId isEqualToString:self.user.userId]) {
        return;
    }
    
    if (user.profileBannerImage == nil) {
        [[TwitterClient sharedInstance] getProfileBanner:user.userId completion:^(NSDictionary *bannerData, NSError *error) {
            [user setBannerUrl:bannerData];
            [self presentProfileView:user];
        }];
    } else {
        [self presentProfileView:user];
    }
}

- (void)onReply:(Tweet *)originalTweet {
    ComposeViewController *cvc = [[ComposeViewController alloc] init];
    cvc.originalTweet = originalTweet;
    //cvc.delegate = self;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:cvc];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)onCompose {
    ComposeViewController *cvc = [[ComposeViewController alloc] init];
    cvc.delegate = self;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:cvc];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)setUser:(User *)user {
    _user = user;
}

@end
