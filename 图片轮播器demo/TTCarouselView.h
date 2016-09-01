//
//  TTCarouselView.h
//  图片轮播器demo
//
//  Created by 涂世展 on 16/8/20.
//  Copyright © 2016年 涂世展. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TTCarouselView;

typedef void(^ClickBlock)(NSInteger index);

/**
 *  轮播器图片的切换模式
 */
typedef enum {
    
    ChangeModeDefault, //滚动
    ChangeModeFade   //淡入淡出
    
} ChangeMode;
/**
 *  pageControl的显示位置
 */
typedef enum {
    
    PositionNone,           //默认值 == PositionBottomCenter
    PositionHide,           //隐藏
    PositionTopCenter,      //中上
    PositionBottomLeft,     //左下
    PositionBottomCenter,   //中下
    PositionBottomRight     //右下
    
}PageControlPosition;
/**
 *  代理
 */
@protocol TTCarouselViewDelegate <NSObject>

- (void)carouselView:(TTCarouselView *)carouselView clickImageAtIndex:(NSInteger)index;

@end
@interface TTCarouselView : UIView

#pragma mark 属性属性
/**
 *  设置图片的切换模式,默认是ChangeModeDefault模式
 */
@property (nonatomic, assign) ChangeMode changeMode;

/**
 *  pageControl的位置,默认是center
    当只有一张图片的时候,隐藏
 */
@property (nonatomic, assign) PageControlPosition pagePosition;

/**
 *  需要轮播的图片数组,可以是本地图片,也可以是网路路径
 */
@property (nonatomic, strong) NSArray *imageArray;

/**
 *  是否开启自动缓存,默认是YES
 */
@property (nonatomic, assign) BOOL autoCache;
/**
 *  图片的轮播时间
 */
@property (nonatomic, assign) NSTimeInterval time;
/**
 *  设置图片的内容模式，默认为UIViewContentModeScaleToFill
 */
@property (nonatomic, assign) UIViewContentMode contentMode;
/**
 *  点击图片后要执行的操作，会返回图片在数组中的索引
 */
@property (nonatomic, copy) ClickBlock imageClickBlock;
/**
 *  代理，用来处理图片的点击
 */
@property (nonatomic, weak) id<TTCarouselViewDelegate> delegate;

#pragma mark 方法方法
/**
 *  开启定时器
 *  默认已开启，调用该方法会重新开启
 */
- (void)startTimer;


/**
 *  停止定时器
 *  停止后，如果手动滚动图片，定时器会重新开启
 */
- (void)stopTimer;
/**
 *  清除沙盒中的图片缓存
 */
+ (void)clearDiskCache;
/**
 *  设置分页控件指示器的颜色
 *  不设置则为系统默认
 *
 *  @param color        其他页码的颜色
 *  @param currentColor 当前页码的颜色
 */
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor;

/**
 *  设置分页控件指示器的图片
 *  两个图片必须同时设置，否则设置无效
 *  不设置则为系统默认
 *
 *  @param pageImage    其他页码的图片
 *  @param currentImage 当前页码的图片
 */
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage;
@end
