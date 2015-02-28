//
//  ProfileCell.h
//  Twitter
//
//  Created by Yingming Chen on 2/26/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

typedef NS_ENUM(NSInteger, TableDataSourceIndex) {
    TableDataSourceIndexTweets    = 0,
    TableDataSourceIndexMedia = 1,
    TableDataSourceIndexFavorites = 2
};

@class ProfileCell;

@protocol ProfileCellDelegate <NSObject>

- (void)dataSourceDidChange:(TableDataSourceIndex)index;

@end

@interface ProfileCell : UITableViewCell

@property (nonatomic, strong) User * user;
@property (nonatomic, strong) id<ProfileCellDelegate> delegate;

@end
