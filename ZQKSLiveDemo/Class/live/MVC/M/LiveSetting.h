//
//  LiveSetting.h
//  JWZTLive
//
//  Created by 肖兆强 on 2017/5/23.
//  Copyright © 2017年 MengXianLiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LiveSetting : NSObject


@property (nonatomic,copy)NSString *videoSize;

@property (nonatomic,assign)int FPS;

@property (nonatomic,assign)int Bitrate;

@property (nonatomic,assign)Float32 micVolume;



@end
