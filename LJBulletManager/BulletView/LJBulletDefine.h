//
//  LJBulletDefine.h
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/10/12.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef struct {
    CGFloat time;
    CGFloat interval;
} HJDanmakuTime;

NS_INLINE CGFloat HJMaxTime(HJDanmakuTime time) {
    return time.time + time.interval;
}
//刷新
static const CGFloat ljFrameInterval = 0.2;
//弹幕高度
#define CellHeight 25
//弹幕的间隔
#define CellSpace  5
//运行时间
#define Duration   5.0

@interface LJBulletDefine : NSObject

+ (CGSize)getTextCGSize:(NSString*)str Font:(UIFont*)font;

@end
