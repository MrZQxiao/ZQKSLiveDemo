//
//  CLiveViewController.h
//  ZQKSLiveDemo
//
//  Created by 肖兆强 on 2017/8/28.
//  Copyright © 2017年 BTV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveSetting.h"

@class Set;







@interface XLiveViewController : UIViewController


/**
 设置
 */
@property (nonatomic,strong)LiveSetting *setting;


/**
 推流地址
 */
@property (nonatomic,copy)NSString *rtmpURL;


@property (nonatomic ,strong)Set *setView;



@end
