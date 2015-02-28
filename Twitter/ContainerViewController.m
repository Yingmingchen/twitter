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

@property (nonatomic, assign) BOOL isMenuVisible;
@property (nonatomic, assign) BOOL viewDidAppearCount;
@property (nonatomic, assign) CGPoint currentContentViewCenter;
@property (nonatomic, assign) CGFloat currentContentViewLeadingConstraintValue;

@end

@implementation ContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"container";
    
    NSLog(@"container view");

    self.isMenuVisible = NO;
    self.childContentViewController = nil;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    self.navigationController.navigationBar.barTintColor = twitterBlue;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    [self displayMenuContainer];
    
    self.viewDidAppearCount = 0;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    if (self.viewDidAppearCount == 0) {
//        [self displayMenuContainer];
//    }
    
    self.viewDidAppearCount ++;
    
    // Has to set it here instead of in viewDidLoad (somehow there self.view.frame is incorrect)
    // TODO: handle the rotation
//    self.contentView.frame = self.view.frame;
//    self.leftMenuView.frame = self.view.frame;
//    self.contentView.frame = self.view.frame;

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
    [self toggleMenu];
    [self displayChildController:content containerView:self.contentView];
}

- (void) displayChildController:(UIViewController*) child containerView:(UIView *)containerView {
    [self addChildViewController:child];                 // 1
    child.view.frame = containerView.frame;           // 2
    child.view.center = CGPointMake(containerView.center.x,
                                containerView.center.y);
    [containerView addSubview:child.view];
    NSLog(@"center (%lf, %lf)", child.view.center.x, child.view.center.y);
    NSLog(@"frame (%lf, %lf)", child.view.frame.size.width, child.view.frame.size.height);
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
    CGFloat newCenterX;
    CGFloat newLeadingConstraint;
    CGFloat newScale;
    
    if (self.isMenuVisible) {
        newCenterX = self.view.frame.size.width / 2;
        newLeadingConstraint = 0;
        newScale = 1;
        self.isMenuVisible = NO;
    } else {
        // newCenterX = self.view.frame.size.width * 3/2 - 200;
        newLeadingConstraint = self.view.frame.size.width - 200;
        newScale = 0.8;
        self.isMenuVisible = YES;
    }
    
    self.contentViewLeadingConstraint.constant = newLeadingConstraint;
    self.contentViewTrailingConstraint.constant = 0 - newLeadingConstraint;
    [self.contentView setNeedsLayout];
    // [self.contentView setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        //self.contentView.center = CGPointMake(newCenterX, self.contentView.center.y);
        self.contentView.transform = CGAffineTransformMakeScale(newScale, newScale);
        self.leftMenuView.transform = CGAffineTransformMakeScale(newScale, newScale);
        if (self.isMenuVisible) {
            NSLog(@"toggle with transform");
            //self.leftMenuView.layer.transform = CATransform3DRotate(self.leftMenuView.layer.transform, D2R(7.5), 0.0, 1.0, 0.0);
            //CATransform3DScale(self.leftMenuView.layer.transform, 0.95, 0.95, 0.95);
        } else {
            //self.leftMenuView.layer.transform = CATransform3DIdentity;
        }
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

// TODO: add tap gesture recongnizere to toggle menu as well when

- (IBAction)onPanContentView:(UIPanGestureRecognizer *)sender {
    CGPoint currentPoint = [sender locationInView:self.view];
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
        CGPoint newPoint = CGPointMake(self.currentContentViewCenter.x + translation.x, self.currentContentViewCenter.y);
        //self.contentView.center = newPoint;
        CGFloat newLeadingConstraint = self.currentContentViewLeadingConstraintValue + translation.x;
        if (newLeadingConstraint < 0) {
            newLeadingConstraint = 0;
        }
        self.contentViewLeadingConstraint.constant = newLeadingConstraint;
        self.contentViewTrailingConstraint.constant = 0 - newLeadingConstraint;
        // http://stackoverflow.com/questions/20609206/setneedslayout-vs-setneedsupdateconstraints-and-layoutifneeded-vs-updateconstra
        [self.contentView setNeedsLayout];
        [self.contentView layoutIfNeeded];
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"UIGestureRecognizerStateEnded with velocity %lf", velocity.x);
        if (velocity.x > 0) { // moving right
            self.isMenuVisible = NO;
            [self toggleMenu];
        } else { // moving left
            self.isMenuVisible = YES;
            [self toggleMenu];
        }
    }
}

@end
