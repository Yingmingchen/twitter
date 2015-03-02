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

@interface ProfileViewController () <UITableViewDataSource, UITableViewDelegate, MediaTweetCellDelegate, ProfileCellDelegate, UIGestureRecognizerDelegate, ComposeViewControllerDelegate, TweetDetailViewControllerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigProfileTableTopAlignment;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bigProfileLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *profileBannerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *profileBannerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *bigProfileImageView;

@property (strong, nonatomic) UILabel *userNameLabel;
@property (strong, nonatomic) UILabel *userScreenNameLabel;

@property (strong, nonatomic) UIVisualEffectView *bannerBlurView;
@property (strong, nonatomic) UIVisualEffectView *bannerVibrancyEffectView;
@property (nonatomic, assign) BOOL isBannerBlurViewOn;

@property (nonatomic, weak) ContainerViewController *parentContainerViewController;

@property (nonatomic, strong) NSMutableArray *tweets;
@property (nonatomic, assign) BOOL isLoadingOnTheFly;
@property (nonatomic, assign) BOOL isInfiniteLoading;
@property (nonatomic, assign) CGFloat currentBannerHeightConstraint;
@property (nonatomic, assign) CGFloat currentTableViewTopConstraint;
@property (nonatomic, assign) BOOL allowDefaultTableScroll;

@property (nonatomic, assign) NSInteger navigationStatusBarHeight;
@property (nonatomic, assign) NSInteger desiredBannerHeight;

@end

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
    
    [self setNavigationBarStyle];
    
    // Setup rotation related stuff to make sure our own elements below navigation bar
    // See http://stackoverflow.com/questions/23478724/autolayout-specify-spacing-between-view-and-navigation-bar
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self applyTopBarOffsetForOrientation:currentOrientation];
    
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
    self.allowDefaultTableScroll = NO;
    
    [self.bigProfileImageView setImageWithURL:[NSURL URLWithString:self.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    [self setdefaultBigProfilePicSetting];
    UITapGestureRecognizer *bigProfileImageTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onbigProfilePicTapped:)];
    bigProfileImageTapGestureRecognizer.delegate = self;
    [self.bigProfileImageView addGestureRecognizer:bigProfileImageTapGestureRecognizer];
    
    if (self.user.profileBannerImage != nil) {
        [self.profileBannerView setImageWithURL:[NSURL URLWithString:self.user.profileBannerImage] placeholderImage:[UIImage imageNamed:@"Background"]];
    } else {
        [self.profileBannerView setImage:[UIImage imageNamed:@"Background"]];
    }
    self.desiredBannerHeight = 100;
    self.bannerBlurView = nil;
    self.bannerVibrancyEffectView = nil;
    self.isBannerBlurViewOn = NO;
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userScreenNameLabel = [[UILabel alloc] init];
    self.userNameLabel.text = self.user.name;
    self.userNameLabel.textColor = [UIColor whiteColor];
    self.userScreenNameLabel.textColor = [UIColor whiteColor];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userScreenNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userScreenNameLabel.text = [NSString stringWithFormat:@"@%@", self.user.screenname];
    
    UIPanGestureRecognizer *tablePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    UIPanGestureRecognizer *bannerPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    // This is needed to capture vertical pan (which is already listened by default table view
    // See http://stackoverflow.com/questions/10183584/uipangesturerecognizer-on-uitableviewcell-overrides-uitableviews-scroll-view-ge
    tablePanGestureRecognizer.delegate = self;
    bannerPanGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:tablePanGestureRecognizer];
    [self.profileBannerView addGestureRecognizer:bannerPanGestureRecognizer];
    
    [self loadTimelineWithParams:nil dataSourceIndex:TableDataSourceIndexTweets];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self applyTopBarOffsetForOrientation:toInterfaceOrientation];
}

- (void)applyTopBarOffsetForOrientation:(UIInterfaceOrientation) orientation {
    BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    self.navigationStatusBarHeight = UIDeviceOrientationIsLandscape(orientation) && isPhone ? 52 : 64;
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
        
        self.isLoadingOnTheFly = NO;
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

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didFavoriteTweet:(BOOL)value {
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:tweetDetailViewController.indexPath, nil];
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
}

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didRelyButtonClicked:(Tweet *)originalTweet {
    [self onReply:originalTweet];
}

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didRetweetButtonClicked:(BOOL)value {
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:tweetDetailViewController.indexPath, nil];
    Tweet *tweet = tweetDetailViewController.tweet;
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
    [[TwitterClient sharedInstance] retweet:tweet.tweetId completion:nil];
}

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didProfilePicTapped:(User *)user {
    [self onProfilePicTapped:user];
}

- (void)ComposeViewController:(ComposeViewController *)composeViewController didTweet:(Tweet *)tweet {
}

#pragma mark - gesture controls

// Need to allow parent container to handle pan gesture while the table view scroll still working
// See http://stackoverflow.com/questions/17614609/table-view-doesnt-scroll-when-i-use-gesture-recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Disable default table scroll control. We will control it in onPan by ourselves
    return NO;
}

// TODO: allow pan to toggle menu
- (void)onPan:(UIPanGestureRecognizer *)sender {
    CGPoint velocity = [sender velocityInView:self.view];
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.currentBannerHeightConstraint = self.profileBannerHeightConstraint.constant;
        self.currentTableViewTopConstraint = self.tableViewTopConstraint.constant;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:self.view];
        CGFloat newHeight = (self.currentBannerHeightConstraint + translation.y);
        
        // Keep updating the table position
        self.tableViewTopConstraint.constant = self.currentTableViewTopConstraint + translation.y;

        // If new table view is still below navigation bar or we are moving up, update the banner and profile image size
        if (self.tableViewTopConstraint.constant > self.navigationStatusBarHeight || velocity.y < 0) {
            // Expand the banner
            if (newHeight >= self.navigationStatusBarHeight) {
                self.profileBannerHeightConstraint.constant = newHeight;
                [self removeProfileBannerBlurEffect];
            } else {
                [self addProfileBannerBlurEffect];
            }
        }
        
        if (self.tableViewTopConstraint.constant < self.navigationStatusBarHeight) {
            // Persist the user profile image the bottom of the navigation bar
            self.bigProfileTableTopAlignment.constant = 0 -  (0 - self.tableViewTopConstraint.constant + self.navigationStatusBarHeight - 16);
        } else {
            // align the profile image with table view
            self.bigProfileTableTopAlignment.constant = 16;
        }
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        // If we are below the desired position, move it back up
        if (self.profileBannerHeightConstraint.constant >= self.desiredBannerHeight && velocity.y <= 100 && velocity.y >= -100) {
            [self resetLayout];
        } else {
            // Otherwise, simulate the normal table scroll based on velocity
            // TODO: need to handle the case we scroll to the end of the table (maybe consider using a flag
            // when reaching the last cell in the table
            if (velocity.y > 100 || velocity.y < -100) {
                CGFloat newTopConstraint = self.tableViewTopConstraint.constant + velocity.y / 4;;
                // Make sure we don't stretch too much with current frame height. Otherwise, we will cause autolayout exception
                if (newTopConstraint > self.view.frame.size.height) {
                    self.tableViewTopConstraint.constant = self.view.frame.size.height;
                } else {
                    self.tableViewTopConstraint.constant = newTopConstraint;
                }
                // If we are moving down, bound it at the desired position
                if (velocity.y > 0 && self.tableViewTopConstraint.constant > self.desiredBannerHeight) {
                    [self resetLayout];
                } else if (velocity.y < 0 && self.tableViewTopConstraint.constant < self.navigationStatusBarHeight) {
                    self.profileBannerHeightConstraint.constant = self.navigationStatusBarHeight;
                    [self addProfileBannerBlurEffect];
                }
                
                if (self.tableViewTopConstraint.constant < self.navigationStatusBarHeight) {
                    self.bigProfileTableTopAlignment.constant = 0 -  (0 - self.tableViewTopConstraint.constant + self.navigationStatusBarHeight - 16);
                } else {
                    self.bigProfileTableTopAlignment.constant = 16;
                }
            }
            
            // Move the profile pic to the right side and change it to circle
            if (self.tableViewTopConstraint.constant < self.navigationStatusBarHeight) {
                self.bigProfileLeadingConstraint.constant = self.view.frame.size.width - 48 - 8;
                self.bigProfileImageView.layer.cornerRadius = 23;
                self.bigProfileImageView.clipsToBounds = YES;
                UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
                self.bigProfileImageView.layer.borderColor = twitterBlue.CGColor;
                self.bigProfileImageView.layer.borderWidth = 1.5;
            }
            
            [self.view setNeedsLayout];
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
            }];
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
    return mcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row > 0) {
        TweetDetailViewController *tdvc = [[TweetDetailViewController alloc] init];
        tdvc.tweet = self.tweets[indexPath.row - 1];
        tdvc.indexPath = indexPath;
        tdvc.delegate = self;
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:tdvc];
        [self presentViewController:nvc animated:YES completion:nil];
    }
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

// See http://www.binpress.com/tutorial/a-primer-on-ios-8-visual-effects/159
- (void)addProfileBannerBlurEffect {
    if (self.isBannerBlurViewOn) {
        return;
    }
    self.isBannerBlurViewOn = YES;
    // Blur Effect
    if (self.bannerBlurView == nil) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.bannerBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        // Vibrancy Effect
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        self.bannerVibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        [self.bannerVibrancyEffectView addSubview: self.userNameLabel];
    }
    
    [self.bannerBlurView setFrame:self.profileBannerView.bounds];
    [self.profileBannerView addSubview:self.bannerBlurView];
    [self.bannerVibrancyEffectView setFrame:self.profileBannerView.bounds];
    self.userNameLabel.frame = self.navigationController.navigationBar.frame;
    [self.userNameLabel sizeToFit];
    self.userNameLabel.center = self.navigationController.navigationBar.center;
    
    // Add Vibrancy View to Blur View
    [self.bannerBlurView.contentView addSubview:self.bannerVibrancyEffectView];
}

- (void)removeProfileBannerBlurEffect {
    if (self.isBannerBlurViewOn) {
        [self.bannerBlurView removeFromSuperview];
        self.isBannerBlurViewOn = NO;
    }
}

- (void)setNavigationBarStyle {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    // Set navigation bar style to be transparent
    // http://stackoverflow.com/questions/19082963/how-to-make-completely-transparent-navigation-bar-in-ios-7
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Previous-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenu)];
}

- (void)setdefaultBigProfilePicSetting {
    self.bigProfileTableTopAlignment.constant = 16;
    self.bigProfileLeadingConstraint.constant = 8;
    self.bigProfileImageView.layer.cornerRadius = 3;
    self.bigProfileImageView.clipsToBounds = YES;
    self.bigProfileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.bigProfileImageView.layer.borderWidth = 2.5;
}

- (void)resetLayout {
    [self removeProfileBannerBlurEffect];
    self.profileBannerHeightConstraint.constant = self.desiredBannerHeight;
    self.tableViewTopConstraint.constant = self.profileBannerHeightConstraint.constant;
    [self setdefaultBigProfilePicSetting];
    [self.view setNeedsLayout];
    [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

// Back to original state when clicked the user profile pic
- (void)onbigProfilePicTapped:(UITapGestureRecognizer *)sender {
    [self resetLayout];
}

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
    cvc.delegate = self;
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
