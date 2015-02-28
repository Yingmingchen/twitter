//
//  MenuViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/25/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "MenuViewController.h"
#import "ProfileViewController.h"
#import "TweetsViewController.h"
#import "MenuCell.h"
#import "User.h"

typedef NS_ENUM(NSInteger, MenuItemIndex) {
    MenuItemIndexProfile    = 0,
    MenuItemIndexTimelines = 1,
    MenuItemIndexNotifications = 2,
    MenuItemIndexMessages = 3,
    MenuItemIndexLogout = 4,
    MenuItemIndexMax = 5
};

@interface MenuViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, weak) ContainerViewController *parentContainerViewController;

@property (nonatomic, strong) TweetsViewController *tweetsViewController;
@property (nonatomic, strong) TweetsViewController *mentionsViewController;
@property (nonatomic, strong) ProfileViewController *profileViewController;

@property (nonatomic, strong) UINavigationController *tweetsViewNavigationController;
@property (nonatomic, strong) UINavigationController *mentionsViewNavigationController;
@property (nonatomic, strong) UINavigationController *profileViewNavigationController;

@end

@implementation MenuViewController

- (MenuViewController *)initWithParentContainerViewController:(ContainerViewController *)parentContainerViewController {
    self = [super init];
    if (self) {
        self.parentContainerViewController = parentContainerViewController;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tweetsViewController = [[TweetsViewController alloc] initWithParentContainerViewController:self.parentContainerViewController tweetsViewSourceIndex:TweetsViewSourceIndexHomeTimeline];
    self.mentionsViewController = [[TweetsViewController alloc] initWithParentContainerViewController:self.parentContainerViewController tweetsViewSourceIndex:TweetsViewSourceIndexMentions];
    self.profileViewController = [[ProfileViewController alloc] initWithParentContainerViewController:self.parentContainerViewController];
    [self.profileViewController setUser:[User currentUser]];
    self.tweetsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.tweetsViewController];
    self.profileViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.profileViewController];
    self.mentionsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mentionsViewController];
    
    [self.parentContainerViewController displayContentController:self.tweetsViewNavigationController];
    
    // Set navigation bar style
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.barTintColor = twitterBlue;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    // Hide the navigation bar at the beginning
    // self.navigationController.navigationBarHidden = YES;
    
//    // Add buttons to navigation bar
//    self.title = @"Home";
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Logout-26"] style:UIBarButtonItemStylePlain target:self action:@selector(onLogout)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onCompose)];

    
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:nil] forCellReuseIdentifier:@"MenuCell"];
    
    self.tableView.rowHeight = 40;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MenuItemIndexMax;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    switch (indexPath.row) {
        case MenuItemIndexTimelines:
            [cell.iconView setImage:[UIImage imageNamed:@"timeline-24-blue"]];
            cell.titleLabel.text = @"Timelines";
            break;
        case MenuItemIndexProfile:
            [cell.iconView setImage:[UIImage imageNamed:@"User-26-blue"]];
            cell.titleLabel.text = @"Me";
            break;
        case MenuItemIndexNotifications:
            [cell.iconView setImage:[UIImage imageNamed:@"notification-24-blue"]];
            cell.titleLabel.text = @"Mentions";
            break;
        case MenuItemIndexMessages:
            [cell.iconView setImage:[UIImage imageNamed:@"message-25-blue"]];
            cell.titleLabel.text = @"Messages";
            break;
        case MenuItemIndexLogout:
            [cell.iconView setImage:[UIImage imageNamed:@"Logout-26-blue"]];
            cell.titleLabel.text = @"Logout";
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    switch (indexPath.row) {
        case MenuItemIndexTimelines:
            [self.parentContainerViewController displayContentController:self.tweetsViewNavigationController];
            break;
        case MenuItemIndexProfile:
            [self.parentContainerViewController displayContentController:self.profileViewNavigationController];
            break;
        case MenuItemIndexNotifications:
            [self.parentContainerViewController displayContentController:self.mentionsViewNavigationController];
            break;
        case MenuItemIndexMessages:
            break;
        case MenuItemIndexLogout:
        default:
            [User logout];
            break;
    }
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
