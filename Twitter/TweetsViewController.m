//
//  TweetsViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/19/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "TweetsViewController.h"
#import "ComposeViewController.h"
#import "TweetDetailViewController.h"
#import "User.h"
#import "Tweet.h"
#import "TwitterClient.h"
#import "MediaTweetCell.h"

@interface TweetsViewController () <UITableViewDataSource, UITableViewDelegate, MediaTweetCellDelegate, TweetDetailViewControllerDelegate, ComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *twitterLogIconView;

@property (strong, nonatomic) NSMutableArray *tweets;
@property (nonatomic, strong) UIRefreshControl *tableRefreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *infiniteLoadingView;

@property (nonatomic, assign) BOOL isPullDownRefreshing;
@property (nonatomic, assign) BOOL isInfiniteLoading;
@property (nonatomic, assign) BOOL isLoadingOnTheFly;
@property (nonatomic, assign) BOOL isInitLoading;

@end

@implementation TweetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set navigation bar style
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.barTintColor = twitterBlue;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    // Hide the navigation bar at the beginning
    self.navigationController.navigationBarHidden = YES;
    self.backgroundView.backgroundColor = twitterBlue;

    // Add buttons to navigation bar
    self.title = @"Home";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Logout-26"] style:UIBarButtonItemStylePlain target:self action:@selector(onLogout)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onCompose)];
    
    // Setup table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 265;
    [self.tableView registerNib:[UINib nibWithNibName:@"MediaTweetCell" bundle:nil] forCellReuseIdentifier:@"MediaTweetCell"];
    self.tableView.hidden = YES;

    [self initAutoLoadingUISupport];
    
    self.tweets = [[NSMutableArray alloc] init];
    self.isInitLoading = YES;
    [self loadHomelineWithParams:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - load/reload methods

- (void)loadHomelineWithParams:(NSMutableDictionary *)params {
    self.isLoadingOnTheFly = YES;
    
    // TODO: move this under Tweet class (ORM) instead of calling it here
    NSMutableDictionary *finalParams = params;
    
    if (finalParams == nil) {
        finalParams = [[NSMutableDictionary alloc] init];
        [finalParams setObject:@(20) forKey:@"count"];
    }

    [[TwitterClient sharedInstance] homeTimelineWithParams:finalParams completion:^(NSArray *tweets, NSError *error) {
        if (!error) {
            if (self.isInfiniteLoading) {
                [self.tweets addObjectsFromArray:tweets];
            } else {
                self.tweets = [NSMutableArray arrayWithArray:tweets];
            }
            
            if (!self.isInitLoading) {
                self.backgroundView.hidden = YES;
                self.tableView.hidden = NO;
                self.navigationController.navigationBarHidden = NO;
            } else {
                self.isInitLoading = NO;
                [self loadCompletionAnimation];
            }

            [self.tableView reloadData];
        } else {
            NSLog(@"failed to load home timeline data with error %@", error);
        }

        if (self.isPullDownRefreshing) {
            [self.tableRefreshControl endRefreshing];
        }
        if (self.isInfiniteLoading) {
            [self.infiniteLoadingView stopAnimating];
        }
        
        self.isLoadingOnTheFly = NO;
        self.isPullDownRefreshing = NO;
        self.isInfiniteLoading = NO;
    }];
}

// Helper function to setup the UI for pull to refresh and infinite loading
- (void)initAutoLoadingUISupport {
    // "pull to refresh" support
    self.tableRefreshControl = [[UIRefreshControl alloc] init];
    [self.tableRefreshControl addTarget:self action:@selector(onPullDownRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.tableRefreshControl atIndex:0];
    
    // For infinite loading
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)];
    self.infiniteLoadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.infiniteLoadingView.center = tableFooterView.center;
    [tableFooterView addSubview:self.infiniteLoadingView];
    self.tableView.tableFooterView = tableFooterView;
    
    self.isPullDownRefreshing = NO;
    self.isInfiniteLoading = NO;
    self.isLoadingOnTheFly = NO;
}

- (void)onPullDownRefresh {
    if (!self.isLoadingOnTheFly) {
        self.isPullDownRefreshing = YES;
        [self loadHomelineWithParams:nil];
    }
}

#pragma mark - delegates

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didFavoriteTweet:(BOOL)value {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:mediaTweetCell];
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:indexPath, nil];
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
}

- (void)MediaTweetCell:(MediaTweetCell *)mediaTweetCell didRelyButtonClicked:(Tweet *)originlTweet {
    [self onReply:originlTweet];
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
    // TODO: resolve warning: Presenting view controllers on detached view controllers is discouraged
    [self onReply:originalTweet];
}

- (void)TweetDetailViewController:(TweetDetailViewController *)tweetDetailViewController didRetweetButtonClicked:(BOOL)value {
    NSArray *indexPathes = [[NSArray alloc] initWithObjects:tweetDetailViewController.indexPath, nil];
    Tweet *tweet = tweetDetailViewController.tweet;
    [self.tableView reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationNone];
    [[TwitterClient sharedInstance] retweet:tweet.tweetId completion:nil];
}

- (void)ComposeViewController:(ComposeViewController *)composeViewController didTweet:(Tweet *)tweet {
    // Insert the new tweet to the top
    NSMutableArray *newTweets = [NSMutableArray arrayWithObject:tweet];
    [self.tweets replaceObjectsInRange:NSMakeRange(0,0)
                    withObjectsFromArray:newTweets];
    [self.tableView reloadData];
}


#pragma mark - Table methods

// Make the separator line extends all the way to the left
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Tweet *tweet = self.tweets[indexPath.row];
    MediaTweetCell *mcell = [tableView dequeueReusableCellWithIdentifier:@"MediaTweetCell"];
    mcell.tweet = tweet;
    mcell.delegate = self;
    
    // Infinite loading
    if (indexPath.row == self.tweets.count - 1 && !self.isLoadingOnTheFly) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        // See https://dev.twitter.com/rest/public/timelines
        NSInteger max_id = [tweet.tweetId integerValue] - 1;
        [params setObject:@(max_id) forKey:@"max_id"];
        self.isInfiniteLoading = YES;
        [self loadHomelineWithParams:params];
    }
    return mcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    TweetDetailViewController *tdvc = [[TweetDetailViewController alloc] init];
    tdvc.tweet = self.tweets[indexPath.row];
    tdvc.indexPath = indexPath;
    tdvc.delegate = self;
    [self.navigationController pushViewController:tdvc animated:YES];
}

// TODO: need to fully solve this issue: http://stackoverflow.com/questions/25937827/table-view-cells-jump-when-selected-on-ios-8
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Tweet *tweet = self.tweets[indexPath.row];
    if (tweet.tweetPhotoUrl != nil) {
        return 265.0;
    } else {
        return 100.0;
    }
}

#pragma mark -- animations

- (void) loadCompletionAnimation {
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut // UIViewAnimationOptionBeginFromCurrentState
                     animations:(void (^)(void)) ^{
                         self.twitterLogIconView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.8
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseInOut // UIViewAnimationOptionBeginFromCurrentState
                                          animations:(void (^)(void)) ^{
                                              self.twitterLogIconView.transform = CGAffineTransformMakeScale(5, 5);
                                          }
                                          completion:^(BOOL finished){
                                              self.twitterLogIconView.transform = CGAffineTransformIdentity;
                                              self.backgroundView.hidden = YES;
                                              self.tableView.hidden = NO;
                                              self.navigationController.navigationBarHidden = NO;
                                          }];
                     }];
}

#pragma mark -- helper methods

- (void)onLogout {
    [User logout];
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

@end
