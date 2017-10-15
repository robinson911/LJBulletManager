//
//  LJBulletView.m
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/5/23.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import "LJBulletView.h"

@implementation LJBulletView

#pragma mark -- 根据内容生成弹幕
- (instancetype)initWithContent:(NSString *)content
{
    self = [super init];
    if (self)
    {
        [self setDanmuUI:content];
    }
    return self;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self init]) {
        self.reuseIdentifier = reuseIdentifier;
        [self setDanmuUI:@""];
    }
    return self;
}

- (void)setDanmuUI:(NSString*)str
{
    self.userInteractionEnabled = NO;
    
    CGFloat width = [LJBulletDefine getTextCGSize:str Font:loadFont(14)].width + 1.0f;
    _ljBulletLabel = [[UILabel alloc]init];
    _ljBulletLabel.backgroundColor = [UIColor clearColor];
    _ljBulletLabel.font = loadFont(14);
    _ljBulletLabel.clipsToBounds = YES;
    _ljBulletLabel.layer.cornerRadius = 2;
    _ljBulletLabel.layer.borderWidth = 1;
    //_ljBulletLabel.layer.borderColor = [UIColor redColor].CGColor;
    _ljBulletLabel.frame = CGRectMake(0, 0, width, CellHeight);
    //self.ljBulletLabel.backgroundColor = [UIColor yellowColor];
    _ljBulletLabel.text = str;
    
    [self addSubview:_ljBulletLabel];
}

- (void)setDanmuContent:(NSString*)contentStr
{
    _ljBulletLabel.text = contentStr;
}

@end
