//
//  ContainerViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/25/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "ContainerViewController.h"
#import "MenuViewController.h"
#import <QuartzCore/QuartzCore.h>

#define D2R(x) (x * (M_PI/180.0)) // macro to convert degrees to radians

@interface ContainerViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *leftMenuView;

@property (nonatomic, strong) MenuViewController *menuViewController;

@property (nonatomic, strong) UINavigationController *menuViewNavigationController;

@property (nonatomic, strong) UIViewController *childContentViewController;

- (IBAction)onPanContentView:(UIPanGestureRecognizer *)sender;
- (IBAction)onTapContentView:(UITapGestureRecognizer *)sender;

@property (nonatomic, assign) BOOL isMenuVisible;
@property (nonatomic, assign) BOOL viewDidAppearCount;
@property (nonatomic, assign) CGPoint currentContentViewCenter;
@property (nonatomic, assign) CGFloat currentContentViewLeadingConstraintValue;

@end

@implementation ContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isMenuVisible = NO;
    self.childContentViewController = nil;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.barTintColor = twitterBlue;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.navigationController.navigationBarHidden = YES;

    // Set the initial rotation position for the menu
    CATransform3D left = CATransform3DIdentity;
    left.m34 = 1.0/ -500;
    left = CATransform3DRotate(left, 90.0f * M_PI / 180.0f, 0, 1, 0);
    self.leftMenuView.layer.transform = left;
    
    [self displayMenuContainer];
    
    self.viewDidAppearCount = 0;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewDidAppearCount ++;
    
    // TODO: handle the rotation

    // Border shadow
    CALayer *layer = self.contentView.layer;
    layer.shadowOffset = CGSizeMake(1, 1);
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowRadius = 4.0f;
    layer.shadowOpacity = 0.80f;
    CGRect myrect = CGRectMake(layer.bounds.origin.x, layer.bounds.origin.y, layer.bounds.size.width, layer.bounds.size.height);
    layer.shadowPath = [[UIBezierPath bezierPathWithRect:myrect] CGPath];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - add/remove child view controllers

- (void)displayMenuContainer {
    self.menuViewController = [[MenuViewController alloc] initWithParentContainerViewController:self];
    self.menuViewNavigationController = [[UINavigationController alloc] initWithRootViewController:self.menuViewController];
    
    [self displayChildController:self.menuViewNavigationController containerView:self.leftMenuView];
}

- (void) displayContentController:(UIViewController*)content {
    if (self.childContentViewController != nil) {
        [self hideChildController:self.childContentViewController];
    }
    self.childContentViewController = content;
    self.isMenuVisible = YES;
    [self displayChildController:content containerView:self.contentView];
    [self toggleMenuWithCompletion:^(BOOL finished) {
    }];
}

// TODO: try out to use auto layout constraints to make sure child is always taking the full screen of the container
// Right now hardcoded to create the child frame/center based on overall view frame/center.
// Otherwise, we will have see child is not taking the full content container while we are doing
// scale animation later on against content container.
- (void) displayChildController:(UIViewController*) child containerView:(UIView *)containerView {
    [self addChildViewController:child];                 // 1
    child.view.frame = self.view.frame;           // 2
    child.view.center = CGPointMake(self.view.center.x, self.view.center.y);
    [containerView addSubview:child.view];
    [child didMoveToParentViewController:self];          // 3
}

- (void) hideChildController:(UIViewController*) child
{
    [child willMoveToParentViewController:nil];  // 1
    [child.view removeFromSuperview];            // 2
    [child removeFromParentViewController];      // 3
}

#pragma mark - gestures

- (void)toggleMenu {
    [self toggleMenuWithCompletion:^(BOOL finished) {
    }];
}

- (void)toggleMenuWithCompletion:(void (^)(BOOL finished))completion {
    CGFloat newCenterX;
    CGFloat newLeadingConstraint;
    CGFloat newScale;
    
    if (self.isMenuVisible) {
        newCenterX = self.view.frame.size.width / 2;
        newLeadingConstraint = 0;
        newScale = 1;
        self.isMenuVisible = NO;
    } else {
        newLeadingConstraint = self.view.frame.size.width - 200;
        newScale = 0.8;
        self.isMenuVisible = YES;
    }
    
    if (self.isMenuVisible) {
        self.contentViewLeadingConstraint.constant = newLeadingConstraint;
        self.contentViewTrailingConstraint.constant = 0 - newLeadingConstraint;
        [self.contentView setNeedsLayout];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.contentView layoutIfNeeded];
        } completion:^(BOOL finished) {
            // http://www.thinkandbuild.it/introduction-to-3d-drawing-in-core-animation-part-1/
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.contentView.transform = CGAffineTransformMakeScale(newScale, newScale);
                CATransform3D left = CATransform3DIdentity;
                //Add the perspective
                left.m34 = 1.0/ -500;
                left = CATransform3DScale(left, newScale, newScale, newScale);
                self.leftMenuView.layer.transform = left;
            } completion:^(BOOL finished) {
                completion(finished);
            }];
        }];
    } else {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.contentView.transform = CGAffineTransformMakeScale(newScale, newScale);
            CATransform3D left = CATransform3DIdentity;
            left.m34 = 1.0/ -500;
            left = CATransform3DRotate(left, 90.0f * M_PI / 180.0f, 0, 1, 0);
            
            self.leftMenuView.layer.transform = left;
        } completion:^(BOOL finished) {
            self.contentViewLeadingConstraint.constant = newLeadingConstraint;
            self.contentViewTrailingConstraint.constant = 0 - newLeadingConstraint;
            [self.contentView setNeedsLayout];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.contentView layoutIfNeeded];
            } completion:^(BOOL finished) {
                completion(finished);
            }];
        }];
        
    }
}

// TODO: add tap gesture recongnizere to toggle menu as well
- (IBAction)onPanContentView:(UIPanGestureRecognizer *)sender {
    CGPoint velocity = [sender velocityInView:self.view];
    
    // Disallow sliding right while we already reach right end
    if (self.isMenuVisible && velocity.x > 0) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        //self.currentContentViewCenter = self.contentView.center;
        self.currentContentViewLeadingConstraintValue = self.contentViewLeadingConstraint.constant;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:self.view];
        CGFloat newLeadingConstraint = self.currentContentViewLeadingConstraintValue + translation.x;
        if (newLeadingConstraint < self.view.frame.size.width - 200 && velocity.x < 0) {
            newLeadingConstraint = self.view.frame.size.width - 200;
        }
        self.contentViewLeadingConstraint.constant = newLeadingConstraint;
        self.contentViewTrailingConstraint.constant = 0 - newLeadingConstraint;
        // http://stackoverflow.com/questions/20609206/setneedslayout-vs-setneedsupdateconstraints-and-layoutifneeded-vs-updateconstra
        [self.contentView setNeedsLayout];
        [self.contentView layoutIfNeeded];
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if (velocity.x > 0) { // moving right
            self.isMenuVisible = NO;
            [self toggleMenu];
        } else { // moving left
            self.isMenuVisible = YES;
            [self toggleMenu];
        }
    }
}

- (IBAction)onTapContentView:(UITapGestureRecognizer *)sender {
    if (self.isMenuVisible) {
        [self toggleMenu];
    } else {
        // This is needed for subview's table selection to be called
        // see http://stackoverflow.com/questions/8952688/didselectrowatindexpath-not-being-called/9248827#9248827
        sender.cancelsTouchesInView = NO;
    }
}

@end
