//
//  LJBulletView.h
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/5/23.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LJBulletView : UIView

@property (nonatomic, assign) CGFloat px;

@property (nonatomic, assign) CGFloat py;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, copy) NSString *reuseIdentifier;

//label
@property (nonatomic, strong)UILabel *ljBulletLabel;

//轨道 trajectory, 默认轨道： -1
@property (nonatomic, assign) NSInteger yIdx;

//弹幕运行时间
@property (nonatomic, assign) float remainingTime;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
/** 数据加载*/
- (instancetype)initWithContent:(NSString *)content;

- (void)setDanmuUI:(NSString*)str;

- (void)setDanmuContent:(NSString*)contentStr;

@end
