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

@property (nonatomic, strong) NSIndexPath *selectedItem;

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
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.navigationController.navigationBarHidden = YES;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:nil] forCellReuseIdentifier:@"MenuCell"];
    self.selectedItem = nil;
    self.tableView.rowHeight = 100;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MenuItemIndexMax;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    switch (indexPath.row) {
        case MenuItemIndexTimelines:
            [cell.iconView setImage:[UIImage imageNamed:@"timeline-24-blue"]];
            cell.titleLabel.text = @"Timelines";
            if (self.selectedItem == nil) {
                self.selectedItem = indexPath;
            }
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
    
    if (self.selectedItem != nil && indexPath.row == self.selectedItem.row) {
        cell.titleLabel.textColor = [UIColor whiteColor];
    } else {
        cell.titleLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    MenuCell *selectedCell = (MenuCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    MenuCell *previousSelectedCell = (MenuCell *)[self.tableView cellForRowAtIndexPath:self.selectedItem];
    
    if (indexPath.row != self.selectedItem.row) {
        previousSelectedCell.titleLabel.textColor = [UIColor lightGrayColor];
        selectedCell.titleLabel.textColor = [UIColor whiteColor];
    }
    
    self.selectedItem = indexPath;
    
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

@end
