//
//  TweetDetailViewController.m
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "TweetDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "NSDate+DateTools.h"
#import "TwitterClient.h"
#import "MediaCollectionViewCell.h"
#import "ComposeViewController.h"
#import "UIImageView+MHGallery.h"
#import "MHMediaPreviewCollectionViewCell.h"
#import "MHGalleryController.h"

@interface TweetDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaCollectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *profileTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetIconTopConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *retweetIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetUserName;
@property (weak, nonatomic) IBOutlet UIImageView *tweetUserProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *tweetUserName;
@property (weak, nonatomic) IBOutlet UILabel *tweetUserScreenName;
@property (weak, nonatomic) IBOutlet UILabel *tweetText;
@property (weak, nonatomic) IBOutlet UICollectionView *mediaCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *retweetCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *retweetTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UIButton *retweetButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;

@property (nonatomic, assign) NSInteger navigationBarHeight;
@property (nonatomic, assign) NSInteger relativeProfileTopConstraint;

@end

@implementation TweetDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Tweet";
    // Setup rotation related stuff to make sure our own elements below navigation bar
    // See http://stackoverflow.com/questions/23478724/autolayout-specify-spacing-between-view-and-navigation-bar
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self applyTopBarOffsetForOrientation:currentOrientation];
    // Need to to do this here instead of inside setTweet because those IBOutlets were nil at that time.
    [self renderTweet];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pen-24"] style:UIBarButtonItemStylePlain target:self action:@selector(onReply)];
    
    self.mediaCollectionView.delegate = self;
    self.mediaCollectionView.dataSource = self;
    [self.mediaCollectionView registerNib:[UINib nibWithNibName:@"MediaCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"MediaCollectionViewCell"];
    
    self.tweetUserProfileImage.layer.cornerRadius = 3;
    self.tweetUserProfileImage.clipsToBounds = YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self applyTopBarOffsetForOrientation:toInterfaceOrientation];
}

- (void)applyTopBarOffsetForOrientation:(UIInterfaceOrientation) orientation {
    BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    self.navigationBarHeight = UIDeviceOrientationIsLandscape(orientation) && isPhone ? 52 : 64;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- collection view methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tweet.tweetPhotoUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCollectionViewCell" forIndexPath:indexPath];
    
    NSString *url = self.tweet.tweetPhotoUrls[indexPath.row];
    [cell.mediaImageView setImageWithURL:[NSURL URLWithString:url]];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    //
    // Following are the gallery view using https://github.com/mariohahn/MHVideoPhotoGallery
    //
    
    MediaCollectionViewCell *cell = (MediaCollectionViewCell *)[self.mediaCollectionView cellForItemAtIndexPath:indexPath];

    NSMutableArray *galleryData = [NSMutableArray array];
    for (NSString *url in self.tweet.tweetPhotoUrls) {
        MHGalleryItem *imageItem = [MHGalleryItem itemWithURL:url galleryType:MHGalleryTypeImage];
        [galleryData addObject:imageItem];
    }
    //MHGalleryItem *youtube = [MHGalleryItem itemWithYoutubeVideoID:@"myYoutubeID"];
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarHidden];
    gallery.galleryItems = galleryData;
    gallery.presentingFromImageView = cell.mediaImageView;
    gallery.presentationIndex = indexPath.row;
    gallery.UICustomization.hideShare = YES;
    gallery.UICustomization.backButtonState = MHBackButtonStateWithoutBackArrow;
    gallery.UICustomization.barStyle = UIBarStyleBlack;
    UIColor *twitterBlue = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    gallery.UICustomization.barTintColor = twitterBlue;
    gallery.UICustomization.barButtonsTintColor = [UIColor whiteColor];
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSInteger currentIndex,UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode mhGalleryViewMode){
        
        NSIndexPath *newIndex = [NSIndexPath indexPathForRow:currentIndex inSection:0];
        
        [self.mediaCollectionView scrollToItemAtIndexPath:newIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageView *imageView = [(MediaCollectionViewCell *)[self.mediaCollectionView cellForItemAtIndexPath:newIndex] mediaImageView];
            [blockGallery dismissViewControllerAnimated:YES dismissImageView:imageView completion:nil];
        });
        
    };
    [self presentMHGalleryController:gallery animated:YES completion:nil];
}


#pragma mark - event handlers

- (IBAction)onButtonClick:(id)sender {
    if (sender == self.retweetButton) {
        if ([self.tweet.user.userId isEqualToString:[User currentUser].userId]) {
            NSLog(@"Can't retweet your own tweet");
            return;
        }
        if (!self.tweet.retweeted) {
            self.tweet.retweetCount ++;
            self.tweet.retweeted = YES;
            [self updateRetweetUI:self.tweet];
            [self.delegate TweetDetailViewController:self didRetweetButtonClicked:YES];
        }
    } else if (sender == self.replyButton){
        [self onReply];
    } else if (sender == self.favoriteButton){
        self.tweet.favorited = !self.tweet.favorited;
        if (self.tweet.favorited) {
            self.tweet.favoriteCount ++;
            [[TwitterClient sharedInstance] favorite:self.tweet.tweetId completion:nil];
        } else {
            self.tweet.favoriteCount --;
            [[TwitterClient sharedInstance] unfavorite:self.tweet.tweetId completion:nil];
        }
        [self updateFavoriteUI:self.tweet];
        [self.delegate TweetDetailViewController:self didFavoriteTweet:self.tweet.favorited];
    }
}

- (void)onReply {
    [self.delegate TweetDetailViewController:self didRelyButtonClicked:self.tweet];
}

#pragma mark - custom setters

- (void)setTweet:(Tweet *)tweet {
    _tweet = tweet;
}

#pragma mark - helper function

- (void)renderTweet {
    Tweet *tweetToShow = self.tweet;
    
    if (self.tweet.childTweet != nil) {
        tweetToShow = self.tweet.childTweet;
        self.retweetIcon.hidden = NO;
        self.retweetUserName.hidden = NO;
        self.retweetUserName.text = [NSString stringWithFormat:@"%@ retweeted", self.tweet.user.name];
        self.relativeProfileTopConstraint = 32;
        self.retweetIconTopConstraint.constant = self.navigationBarHeight + 8;
        self.profileTopConstraint.constant = self.navigationBarHeight + self.relativeProfileTopConstraint;
    } else {
        self.retweetIcon.hidden = YES;
        self.retweetUserName.hidden = YES;
        self.relativeProfileTopConstraint = 8;
        self.profileTopConstraint.constant = self.navigationBarHeight + self.relativeProfileTopConstraint;
    }
    
    [self.tweetUserProfileImage setImageWithURL:[NSURL URLWithString:tweetToShow.user.profileImageUrl] placeholderImage:[UIImage imageNamed:@"default_profile_pic_normal_48"]];
    self.tweetUserName.text = tweetToShow.user.name;
    self.tweetUserScreenName.text = [NSString stringWithFormat:@"@%@", tweetToShow.user.screenname];
    self.tweetText.text = tweetToShow.text;
    [self.tweetText sizeToFit];
    [self updateRetweetUI:tweetToShow];
    
    self.timestampLabel.text = [tweetToShow.createAt formattedDateWithFormat:@"MM/d/yy, HH:mm"];
    //    self.timeStamp.text = tweetToShow.createAt.shortTimeAgoSinceNow;
    
    if (tweetToShow.tweetPhotoUrls.count > 0) {
        // We need to lower the this constraint's priority to 999 instead of 1000, otherwise, we get constraint confliction
        // involving UIView-Encapsulated-Layout-Height.
        // See http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i.
        self.mediaCollectionViewHeightConstraint.constant = 150.0;
    } else {
        self.mediaCollectionViewHeightConstraint.constant = 0.0;
    }
    
    [self updateFavoriteUI:tweetToShow];
}

- (void) updateRetweetUI:(Tweet *)tweet {
    self.retweetCountLabel.text = [NSString stringWithFormat:@"%ld", tweet.retweetCount];
    if (tweet.retweetCount <= 1) {
        self.retweetTextLabel.text = @"RETWEET";
    } else {
        self.retweetTextLabel.text = @"RETWEETS";
    }
    
    if (tweet.retweeted) {
        [self.retweetButton setImage:[UIImage imageNamed:@"retweet_on-16"] forState:UIControlStateNormal];
    } else {
        [self.retweetButton setImage:[UIImage imageNamed:@"retweet_default-16"] forState:UIControlStateNormal];
    }
}

- (void) updateFavoriteUI:(Tweet *)tweet {
    if (tweet.favorited) {
        [self.favoriteButton setImage:[UIImage imageNamed:@"favorite_on-16"] forState:UIControlStateNormal];
    } else {
        [self.favoriteButton setImage:[UIImage imageNamed:@"favorite_default-16"] forState:UIControlStateNormal];
    }
    
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%ld", tweet.favoriteCount];
    if (tweet.favoriteCount <= 1) {
        self.favoriteTextLabel.text = @"FAVORITE";
    } else {
        self.favoriteTextLabel.text = @"FAVORITES";
    }
}
@end
