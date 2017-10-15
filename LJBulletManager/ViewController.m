//
//  ViewController.m
//  LJBulletManager
//
//  Created by 孙伟伟 on 2017/10/13.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import "ViewController.h"
#import "LJBulletViewManager.h"
#import "LJBulletView.h"

@interface ViewController ()

@property (nonatomic,strong) LJBulletViewManager *ljBulletViewManager;

@end

@implementation ViewController

#pragma mark -- life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"弹幕发射demo";

    [self.view addSubview:self.ljBulletViewManager];
}

- (LJBulletViewManager*)ljBulletViewManager
{
    if (!_ljBulletViewManager)
    {
        _ljBulletViewManager = [[LJBulletViewManager alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 300)];
         [_ljBulletViewManager registerClass:[LJBulletView class] forCellReuseIdentifier:@"cell"];
    }
    return _ljBulletViewManager;
}

- (IBAction)startClicked:(id)sender {
    
   [self.ljBulletViewManager play];
}

- (IBAction)pauseClicked:(id)sender {
    
    NSLog(@"%s",__FUNCTION__);
    
    [self.ljBulletViewManager pause];
}

- (IBAction)stopClicked:(id)sender {
    
    NSLog(@"%s",__FUNCTION__);
    
    [self.ljBulletViewManager stop];
}

#pragma mark -- 发射弹幕
- (IBAction)sendClicked:(id)sender {
    
    NSLog(@"%s",__FUNCTION__);
    NSUInteger c = arc4random_uniform(13);
    NSArray *contentArray = @[@"swdedf",
                              @"我是谁谁谁谁",@"我是",@"我谁",@"我",@"谁",
                              @"我是谁谁我是谁谁谁谁我是谁谁谁谁我是谁谁谁谁我是谁谁谁谁谁谁",
                              @"测试数我的你的大家的",
                              @"6789045",
                              @"ghjkliouipohjlk",
                              @"ghjklijlqwdqefrgtouipohjlk",
                              @"wdef123456782345678io",
                              @"uej3kqefdvsjnlqeofadilqeadjpzck;"];
    
    //生产弹幕，先从缓存中取danmu。
    LJBulletView *danmaku = [self danmaForDequeueReusable:contentArray[c]];
    if (!danmaku) {
        //取不到，则创建新弹幕
        danmaku = [[LJBulletView alloc] initWithContent:contentArray[c]];
    }
    [self.ljBulletViewManager sendDanmaku:danmaku];
}

#pragma mark -- danma View重用
- (LJBulletView *)danmaForDequeueReusable:(NSString *)danmakuContent
{
    LJBulletView *_danmaku = [self.ljBulletViewManager dequeueReusableDanmaWithIdentifier:@"cell"];
    
    if (!_danmaku) return nil;
    
    CGFloat width = [LJBulletDefine getTextCGSize:danmakuContent Font:loadFont(14)].width + 1.0f;
    _danmaku.layer.borderColor = [UIColor orangeColor].CGColor;
    _danmaku.ljBulletLabel.frame = CGRectMake(0, 0, width, 25);
    _danmaku.layer.borderWidth = 0.5;
    [_danmaku setDanmuContent:danmakuContent];
    
    return _danmaku;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
