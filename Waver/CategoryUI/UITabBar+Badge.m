//
//  UITabBar+Badge.m
//  NXSliderDemo
//
//  Created by ningxia on 16/1/6.
//  Copyright © 2016年 NingXia. All rights reserved.
//

#import "UITabBar+Badge.h"
static NSUInteger badgeViewHeight = 8.0;  //圆形大小为8

@implementation UITabBar (Badge)

//显示小红点
- (void)showBadgeOnItemIndex:(int)index withTabbarItemNums:(int)num {
    //移除之前的小红点
    [self removeBadgeOnItemIndex:index];
    
    //新建小红点
    UIView *badgeView = [[UIView alloc] init];
    badgeView.tag = 888 + index;
    badgeView.layer.cornerRadius = badgeViewHeight / 2; //圆形
    badgeView.backgroundColor = [UIColor redColor]; //颜色：红色
    CGRect tabFrame = self.frame;
    
    //确定小红点的位置
    float percentX = (index + 0.6) / num;
    CGFloat x = ceilf(percentX * tabFrame.size.width);
    CGFloat y = ceilf(0.1 * tabFrame.size.height);
    badgeView.frame = CGRectMake(x, y, badgeViewHeight, badgeViewHeight);
    [self addSubview:badgeView];
}

//隐藏小红点
- (void)hideBadgeOnItemIndex:(int)index {
    //移除小红点
    [self removeBadgeOnItemIndex:index];
}

//移除小红点
- (void)removeBadgeOnItemIndex:(int)index {
    //按照tag值进行移除
    for (UIView *subView in self.subviews) {
        if (subView.tag == 888 + index) {
            [subView removeFromSuperview];
        }
    }
}

@end
