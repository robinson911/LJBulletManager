# LJBulletManager
ios 弹幕
网上找了好多弹幕demo，发现很多都会重叠，体验很不好。所以在参考部分网上弹幕源码的基础上，遂有了本篇弹幕碰撞检测。

本弹幕优点如下（这个是最初版本，以后慢慢优化）：

一. 可以很好的避免弹幕间的碰撞

其实针对碰撞，主要解决水平运动时，前后两个弹幕不碰撞就可以了。

所以我们主要针对同一个轨道上，前后弹幕是否碰撞展开研究，就可以了。

倘若刚刚生产的弹幕，在同一轨道上会发生碰撞，我们就选择下一个轨道再进行判断，直到找到不发生碰撞的轨道。（此处可能会有极少弹幕丢失，以后再优化）

1. 当前一个弹幕的运行时间变成0时（此处我们默认每一个弹幕的运行时间是5s），也就说明前一个弹幕已经移动到屏幕外面了，后一个弹幕可以发射了。

2.当前一个弹幕的运行时间大于0时，我们判断前一个弹幕是否完全进入屏幕，倘如完全进入屏幕的话，接着判断后一个弹幕是否能追得上前一个弹幕（是否发生碰撞）。

3.当前一个弹幕的运行时间大于0时，我们判断前一个弹幕是否完全进入屏幕，倘如未完全进入屏幕的话，判断下一个轨道（从1开始）。
具体判断代码如下：
我们假定弹幕的运行时间是5s，弹幕向前走一步，时间减少0.2s。

![image](https://github.com/robinson911/LJBulletManager/blob/master/2.png)

二.弹幕重用，避免内存急剧增大

![image](https://github.com/robinson911/LJBulletManager/blob/master/4.png)
![image](https://github.com/robinson911/LJBulletManager/blob/master/6.png)

三. demo截图

![image](https://github.com/robinson911/LJBulletManager/blob/master/8.png)
