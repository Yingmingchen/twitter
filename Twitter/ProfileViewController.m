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

@interface ProfileViewController () <UITableViewDataSource, UITableViewDelegate, MediaTweetCellDelegate, ProfileCellDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileBannerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, weak) ContainerViewController *parentContainerViewController;

@property (nonatomic, strong) NSMutableArray *tweets;
@property (nonatomic, assign) BOOL isLoadingOnTheFly;
@property (nonatomic, assign) BOOL isInfiniteLoading;

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
    //self.navigationController.navigationBarHidden = YES;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Previous-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onMenu)];
    
    // Setup table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 150;
    [self.tableView registerNib:[UINib nibWithNibName:@"ProfileCell" bundle:nil] forCellReuseIdentifier:@"ProfileCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MediaTweetCell" bundle:nil] forCellReuseIdentifier:@"MediaTweetCell"];
    
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    //UIImage *myImage = [UIImage imageNamed:@"loginHeader.png"];
    // UIImageView *imageView = self.profileBannerView;
    //self.profileBannerView.hidden = YES;
    //imageView.frame = self.profileBannerView.frame;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 150);
    
    if (self.user.profileBannerImage != nil) {
        NSLog(@"set profile banner image");
        [imageView setImageWithURL:[NSURL URLWithString:self.user.profileBannerImage] placeholderImage:[UIImage imageNamed:@"background"]];
    } else {
        // consider calling getBannerUrl()
    }
    
    return imageView;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 150;
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



- (void)onMenu {
    if (self.parentContainerViewController) {
        [self.parentContainerViewController toggleMenu];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setUser:(User *)user {
    _user = user;
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
