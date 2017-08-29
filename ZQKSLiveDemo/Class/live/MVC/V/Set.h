//
//  set.h
//  ZQKSLiveDemo
//
//  Created by 肖兆强 on 2017/8/28.
//  Copyright © 2017年 BTV. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "XLiveViewController.h"
#import "NYSliderPopover.h"

@protocol setDelegate <NSObject>

- (void)setDelegate:(UIView *)set withRecognize:(NSString *)recognize;
- (void)setDelegate:(UIView *)set withFps:(int)fps;
- (void)setDelegate:(UIView *)set withRate:(int)rate;
@end

@interface Set : UIView


@property (nonatomic ,assign)BOOL isBegin;
@property (nonatomic ,copy)NSString *recognizeSegment_selected;
@property (nonatomic ,assign)int fpsSegment_selected;
@property (nonatomic ,assign)NSInteger rateValue ;

@property (nonatomic ,strong)NYSliderPopover *rate;

@property (nonatomic ,strong)id<setDelegate> delegate;

@end
