//
//  LJBulletDefine.m
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/10/12.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import "LJBulletDefine.h"

@implementation LJBulletDefine

+ (CGSize)getTextCGSize:(NSString*)str Font:(UIFont*)font
{
    CGSize size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
    return size;
}

@end
