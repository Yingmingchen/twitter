//
//  MediaCollectionViewCell.m
//  Twitter
//
//  Created by Yingming Chen on 2/21/15.
//  Copyright (c) 2015 Yingming Chen. All rights reserved.
//

#import "MediaCollectionViewCell.h"

@implementation MediaCollectionViewCell

- (void)awakeFromNib {
    // Initialization code
    self.mediaImageView.layer.cornerRadius = 3;
    self.mediaImageView.clipsToBounds = YES;
}

@end
