//
//  UITabBar+Badge.h
//  NXSliderDemo
//
//  Created by ningxia on 16/1/6.
//  Copyright © 2016年 NingXia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBar (Badge)

- (void)showBadgeOnItemIndex:(int)index withTabbarItemNums:(int)num;   //显示小红点，num为tabbar的数量，关系到小红点的显示位置
- (void)hideBadgeOnItemIndex:(int)index; //隐藏小红点

@end
