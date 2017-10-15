//
//  LJBulletViewManager.m
//  LJMediaPalyer
//
//  Created by 孙伟伟 on 2017/5/23.
//  Copyright © 2017年 孙伟伟. All rights reserved.
//

#import "LJBulletViewManager.h"
#import <libkern/OSAtomic.h>

@interface LJBulletViewManager ()
{
    OSSpinLock _spinLock;
    dispatch_queue_t _renderQueue;
}
@property (nonatomic, strong) CADisplayLink *displayLink;

//已经使用的弹道，从中可以取出前一个弹道的弹幕，进行碰撞判断
@property(nonatomic, strong)NSMutableDictionary *showingDanmakusTrajectoryDict;

//已经开始绘制显示在界面UI上的弹幕，暂存
@property(nonatomic, strong)NSMutableArray *renderingDanmakusArray;

//用户刚刚发送过来的弹幕数据，暂存
@property (nonatomic, strong) NSMutableArray <LJBulletView *> *fetchDanmakusArray;

@property (nonatomic, strong) NSOperationQueue *sourceQueue;

@property (nonatomic, assign) BOOL isPlaying;

//弹幕重用，数据保存
@property (nonatomic, strong) NSMutableDictionary *cellClassInfo;
@property (nonatomic, strong) NSMutableDictionary *cellReusePool;

@end

@implementation LJBulletViewManager

#pragma mark -- life cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _renderingDanmakusArray = [[NSMutableArray alloc]init];
        
        _fetchDanmakusArray = [[NSMutableArray alloc]init];

        _showingDanmakusTrajectoryDict = [[NSMutableDictionary alloc]init];
        self.cellClassInfo = [NSMutableDictionary dictionary];
        self.cellReusePool = [NSMutableDictionary dictionary];

        self.sourceQueue = [NSOperationQueue new];
        self.sourceQueue.name = @"danmakuSourceQueue";
        self.sourceQueue.maxConcurrentOperationCount = 1;
        
        _renderQueue = dispatch_queue_create("renderQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

#pragma mark -- 发送数据【必须在play之后执行】
- (void)sendDanmaku:(LJBulletView *)danmaku
{
    if (!danmaku)  return;

    OSSpinLockLock(&_spinLock);
    [self.fetchDanmakusArray addObject:danmaku];
    OSSpinLockUnlock(&_spinLock);
    
    [self loadDanmakusFromFetchDanmakusArray];
}

#pragma mark -- 开始准备发射弹幕
- (void)play
{
    if (self.isPlaying) return;
    self.isPlaying = YES;
    
    [self resumeShowingDanmakus];
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        self.displayLink.frameInterval = 60.0 * ljFrameInterval;
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
}

- (void)pause
{
    if (!self.isPlaying) return;
    self.isPlaying = NO;
    
    self.displayLink.paused = YES;
    [self pauseShowingDanmakus];
}

- (void)stop
{
    self.isPlaying = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
    [self clearScreen];
}

- (void)clearScreen
{
    [self recycleDanmaku:[self.renderingDanmakusArray copy]];
    dispatch_async(_renderQueue, ^{
        [self.renderingDanmakusArray removeAllObjects];
    });
}

#pragma mark -- CADisplayLink所有视图遍历---时间递减
- (void)update
{
#pragma mark --获取显示用的数据
    [self loadDanmakusFromFetchDanmakusArray];
    [self renderDanmakusForTime];
}

#pragma mark -- View显示
- (void)renderDanmakusForTime {
    dispatch_async(_renderQueue, ^{
        [self renderShowingDanmakusForInterval];
        [self renderNewDanmakusForData];
    });
}

#pragma mark -- 弹幕绘制
- (void)renderNewDanmakusForData{
    OSSpinLockLock(&_spinLock);
    NSArray *ljArray = [NSArray arrayWithArray:[self.fetchDanmakusArray copy]];
    [self.fetchDanmakusArray removeAllObjects];
    OSSpinLockUnlock(&_spinLock);
    
    for (LJBulletView *danmaku in ljArray)
    {
        [self renderNewDanmaku:danmaku];
    }
}

#pragma mark -- 所有视图遍历---时间递减
- (void)renderShowingDanmakusForInterval
{
    NSMutableArray *disappearDanmakuArray = [NSMutableArray arrayWithCapacity:self.renderingDanmakusArray.count];
    [self.renderingDanmakusArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LJBulletView *danmaku, NSUInteger idx, BOOL *stop)
    {
        danmaku.remainingTime -= ljFrameInterval;
        
        //NSLog(@"renderDisplayingDanmakus:-%f",danmaku.remainingTime);
        
        if (danmaku.remainingTime <= 0) {
            [disappearDanmakuArray addObject:danmaku];
            
            OSSpinLockLock(&_spinLock);
            [self.renderingDanmakusArray removeObjectAtIndex:idx];
            OSSpinLockUnlock(&_spinLock);
        }
    }];
    [self recycleDanmaku:disappearDanmakuArray];
}

#pragma mark - 根据视图绘制
- (BOOL)layoutNewDanmaku:(LJBulletView *)danmaku
{
    CGFloat width = [LJBulletDefine getTextCGSize:danmaku.ljBulletLabel.text Font:danmaku.ljBulletLabel.font].width + 1.0f;
    danmaku.size = CGSizeMake(width, CellHeight);
    
    OSSpinLockLock(&_spinLock);
    CGFloat py = [self layoutPyWithLRDanmaku:danmaku];
    OSSpinLockUnlock(&_spinLock);
    
    if (py < 0) {
        return NO;
    }
    danmaku.py = py;
    danmaku.px = kScreenWidth;
    return YES;
}

#pragma mark -- view展示数据产生
- (void)loadDanmakusFromFetchDanmakusArray
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{

        OSSpinLockLock(&_spinLock);
        NSArray <LJBulletView *> *danmakuArrays = [self.fetchDanmakusArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"remainingTime <= 0"]];
        OSSpinLockUnlock(&_spinLock);

        for (LJBulletView *danmaku in danmakuArrays) {
            danmaku.remainingTime = Duration;
            
            //NSLog(@"loadDanmakusFromFetchDanmakusArray---remainingTime:%f", danmaku.remainingTime);
#pragma mark -- 给每个danmaku赋予值5s
        }
    }];
    [self.sourceQueue cancelAllOperations];
    [self.sourceQueue addOperation:operation];
}

#pragma mark -- 最后一步渲染-----显示
- (BOOL)renderNewDanmaku:(LJBulletView *)danmaku{
    if (![self layoutNewDanmaku:danmaku]) {
        return NO;
    }
    
    OSSpinLockLock(&_spinLock);
    [self.renderingDanmakusArray addObject:danmaku];
    OSSpinLockUnlock(&_spinLock);

    MainThreadAsync(^{
        LJBulletView *cell = danmaku;
        cell.frame = (CGRect){CGPointMake(danmaku.px, danmaku.py), danmaku.size};
        
        [self insertSubview:cell atIndex:20];
        
        [UIView animateWithDuration:cell.remainingTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            
            cell.frame = (CGRect){CGPointMake(-cell.size.width, cell.py), cell.size};
            
        } completion:^(BOOL finished) {
            //[cell removeFromSuperview];
        }];
    });
    return YES;
}

#pragma mark -- 通道判断&高度返回
//1.当前通道是有视图的话，进行碰撞判断
//2.当前通道没view的直接返回显示的高度
- (CGFloat)layoutPyWithLRDanmaku:(LJBulletView *)danmaku
{
    u_int8_t maxPyIndex = (CGRectGetHeight(self.bounds) / CellHeight);
    NSMutableDictionary *trajectory = self.showingDanmakusTrajectoryDict;
    for (u_int8_t index = 0; index < maxPyIndex; index++)
    {
        NSNumber *key = @(index);
        LJBulletView *tempDanmaku = trajectory[key];
        if (!tempDanmaku) {
            danmaku.yIdx = index;
            trajectory[key] = danmaku;
            
            //返回的高度
            NSLog(@"当前通道没view的直接返回显示的高度:%d----",index);
            return (CellHeight + CellSpace) * index;
        }
        //当前通道是有视图的话，进行碰撞判断
        if (![self judgeHitWithPreDanmaku:tempDanmaku danmaku:danmaku]) {
            danmaku.yIdx = index;
            trajectory[key] = danmaku;
            //NSLog(@"当前通道有视图 * index %d----",cellHeight * index);
            return (CellHeight + CellSpace) * index;
        }
    }
    return -1;
}

//弹幕碰撞检测 YES:会碰撞  NO：不会碰撞
- (BOOL)judgeHitWithPreDanmaku:(LJBulletView *)preDanmaku danmaku:(LJBulletView *)danmaku {
    //1.前一个弹幕是否还在移动？【显示时间每次递减0.2s】
    if (preDanmaku.remainingTime <= 0) {
        return NO; //说明前一个弹幕已经移出了屏幕，不会碰撞
    }
    //屏幕的宽度
    CGFloat width = CGRectGetWidth(self.bounds);
    
    //5s显示时间下的弹幕移动速度
    CGFloat preDanmakuSpeed = (width + preDanmaku.size.width) / Duration;
    
    //2.已经移入屏幕的距离与弹幕要移动的总距离比较
    if (preDanmakuSpeed * (Duration - preDanmaku.remainingTime) < preDanmaku.size.width) {
        return YES; //说明弹幕未完全进入屏幕，只有一部分进入了屏幕，会发生碰撞
    }
    
    //3.当前弹幕能否追得上前一个弹幕？
    CGFloat currentDanmakuSpeed = (width + danmaku.size.width) / Duration;
    if (currentDanmakuSpeed * preDanmaku.remainingTime > width) {
        return YES; //可以追得上，会发生碰撞
    }
    return NO;
}

- (void)pauseShowingDanmakus
{
    NSArray *danmakus = [self visibleDanmakus];
    MainThreadAsync(^{
        for (LJBulletView *danmaku in danmakus)
        {
            CALayer *layer = danmaku.layer;
            danmaku.frame = ((CALayer *)layer.presentationLayer).frame;
            [danmaku.layer removeAllAnimations];
        }
    });
}

- (void)resumeShowingDanmakus {
    NSArray *danmakusArray = [self visibleDanmakus];
    MainThreadAsync(^{
        for (LJBulletView *danmaku in danmakusArray) {
            [UIView animateWithDuration:danmaku.remainingTime delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                danmaku.frame = (CGRect){CGPointMake(-danmaku.size.width, danmaku.py), danmaku.size};
            } completion:^(BOOL finished) {
                //[danmaku removeFromSuperview];
            }];
        }
    });
}

- (NSArray *)visibleCells {
    __block NSMutableArray *visibleCells = [NSMutableArray array];
    dispatch_sync(_renderQueue, ^{
        [self.renderingDanmakusArray enumerateObjectsUsingBlock:^(LJBulletView *danmaku, NSUInteger idx, BOOL * _Nonnull stop) {
            LJBulletView *cell = danmaku;
            if (cell) {
                [visibleCells addObject:cell];
            }
        }];
    });
    return visibleCells;
}

- (NSArray *)visibleDanmakus {
    __block NSArray *renderingDanmakus = nil;
    dispatch_sync(_renderQueue, ^{
        renderingDanmakus = [NSArray arrayWithArray:self.renderingDanmakusArray];
    });
    return renderingDanmakus;
}

#pragma mark -- 弹幕重用---避免很多弹幕时，内存急剧增大
- (void)recycleDanmaku:(NSArray *)danmakuArrays
{
    if (danmakuArrays.count == 0) return;
    MainThreadAsync(^{
        for (LJBulletView *danmaku in danmakuArrays)
        {
            [danmaku.layer removeAllAnimations];
            [danmaku removeFromSuperview];
            danmaku.yIdx = -1;
            danmaku.remainingTime = 0;
            [self recycleCellToReusePool:danmaku];
        }
    });
}

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return;
    }
    self.cellClassInfo[identifier] = cellClass;
}

- (LJBulletView *)dequeueReusableDanmaWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (cells.count == 0) {
        Class cellClass = self.cellClassInfo[identifier];
        return cellClass ? [[cellClass alloc] initWithReuseIdentifier:identifier]: nil;
    }
    OSSpinLockLock(&_spinLock);
    LJBulletView *cell = cells.lastObject;
    [cells removeLastObject];
    OSSpinLockUnlock(&_spinLock);
    return cell;
}

- (void)recycleCellToReusePool:(LJBulletView *)danmakuCell
{
    NSString *identifier = danmakuCell.reuseIdentifier;
    if (!identifier) {
        return;
    }
    OSSpinLockLock(&_spinLock);
    NSMutableArray *cells = self.cellReusePool[identifier];
    if (!cells) {
        cells = [NSMutableArray array];
        self.cellReusePool[identifier] = cells;
    }
    [cells addObject:danmakuCell];
    OSSpinLockUnlock(&_spinLock);
}


@end

