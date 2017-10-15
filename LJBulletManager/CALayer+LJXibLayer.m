//
//  CALayer+LJXibLayer.m
//  LJBulletManager
//
//  Created by 孙伟伟 on 2017/10/13.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import "CALayer+LJXibLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation CALayer (LJXibLayer)

- (void)setBorderUIColor:(UIColor *)borderUIColor
{
    self.borderColor = borderUIColor.CGColor;
}

- (UIColor*)borderUIColor
{
    return [UIColor colorWithCGColor:self.borderColor];
}

@end
