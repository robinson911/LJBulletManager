//
//  LJBulletViewManager.h
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/5/23.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LJBulletView.h"

@interface LJBulletViewManager : UIView

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier;

- (LJBulletView *)dequeueReusableDanmaWithIdentifier:(NSString *)identifier;

//弹幕发送【必须在play之后执行】
- (void)sendDanmaku:(LJBulletView *)danmaku;
//弹幕开始准备
- (void)play;
//弹幕暂停
- (void)pause;
//弹幕停止
- (void)stop;

@end
