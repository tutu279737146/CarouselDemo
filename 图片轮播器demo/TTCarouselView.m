//
//  TTCarouselView.m
//  图片轮播器demo
//
//  Created by 涂世展 on 16/8/20.
//  Copyright © 2016年 涂世展. All rights reserved.
//

#import "TTCarouselView.h"
#import <ImageIO/ImageIO.h>

#define DEFAULTTIME 2.5
#define HORMARGIN 10
#define VERMARGIN 5
#define DES_LABEL_H 20
@interface TTCarouselView()<UIScrollViewDelegate>


//轮播器图片的数组
@property (nonatomic, strong) NSMutableArray *images;
//图片描述控件，默认在底部
@property (nonatomic, strong) UILabel *describeLabel;
//滚动视图
@property (nonatomic, strong) UIScrollView *scrollView;
//分页控件
@property (nonatomic, strong) UIPageControl *pageControl;
//当前显示的imageView
@property (nonatomic, strong) UIImageView *currImageView;
//滚动显示的imageView
@property (nonatomic, strong) UIImageView *otherImageView;
//当前显示图片的索引
@property (nonatomic, assign) NSInteger currIndex;
//将要显示图片的索引
@property (nonatomic, assign) NSInteger nextIndex;
//pageControl图片大小
@property (nonatomic, assign) CGSize pageImageSize;
//定时器
@property (nonatomic, strong) NSTimer *timer;
//任务队列
@property (nonatomic, strong) NSOperationQueue *queue;
@end

static NSString *cache;

@implementation TTCarouselView
#pragma mark 初始化方法
//缓存图片的方法,设置缓存图片的文件夹
+ (void)initialize {
    cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TTCache"];
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
#pragma mark 初始化控件
- (void)initSubView {
    self.autoCache = YES;
    [self addSubview:self.scrollView];
//    [self addSubview:self.describeLabel];
    [self addSubview:self.pageControl];
}
#pragma mark 代码创建
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initSubView];
    }
    return self;
}

#pragma mark nib创建
- (void)awakeFromNib {
    [self initSubView];
}

#pragma mark- frame相关
- (CGFloat)height {
    return self.scrollView.frame.size.height;
}

- (CGFloat)width {
    return self.scrollView.frame.size.width;
}

/***************************************************/
#pragma mark- 懒加载
- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        //添加手势监听图片的点击
        [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClick)]];
        _currImageView = [[UIImageView alloc] init];
        _currImageView.clipsToBounds = YES;
        [_scrollView addSubview:_currImageView];
        _otherImageView = [[UIImageView alloc] init];
        _otherImageView.clipsToBounds = YES;
        [_scrollView addSubview:_otherImageView];
    }
    return _scrollView;
}
- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}
/***************************************************/
#pragma mark- --------设置相关方法--------
#pragma mark 设置图片的内容模式
- (void)setContentMode:(UIViewContentMode)contentMode{
    _contentMode = contentMode;
    _currImageView.contentMode = contentMode;
    _otherImageView.contentMode = contentMode;
}
#pragma mark 设置图片数组
- (void)setImageArray:(NSArray *)imageArray{
    
    if (!imageArray.count) return;
    //记录
    _imageArray = imageArray;
    //实例化一个可变的数组
    _images = [NSMutableArray array];
    //循环判断
    for (int i = 0; i < imageArray.count; i++) {
        //如果是本地的图片
        if ([imageArray[i] isKindOfClass:[UIImage class]]) {
            [_images addObject:imageArray[i]];
            //如果是网络的图片,线加载占位图片,下载完成后更换
        }else if ([imageArray[i] isKindOfClass:[NSString class]]){
            [_images addObject:[UIImage imageNamed:@"TTPlaceHolder"]];
            //调用下载网络图片的方法
//            [self downloadImages:i];
        }
    }
    //防止在滚动过程中重新给imageArray赋值时报错
    if (_currIndex >= _images.count) _currIndex = _images.count - 1;
    self.currImageView.image = _images[_currIndex];
//    self.describeLabel.text = _describeArray[_currIndex];
    self.pageControl.numberOfPages = _images.count;
    [self layoutSubviews];
}
#pragma mark 设置scrollView的contentSize
- (void)setScrollViewContentSize {
    if (_images.count > 1) {
        self.scrollView.contentSize = CGSizeMake(self.width * 5, 0);
        self.scrollView.contentOffset = CGPointMake(self.width * 2, 0);
        self.currImageView.frame = CGRectMake(self.width * 2, 0, self.width, self.height);
        if (_changeMode == ChangeModeFade) {
            //淡入淡出模式，两个imageView都在同一位置，改变透明度就可以了
            _currImageView.frame = CGRectMake(0, 0, self.width, self.height);
            _otherImageView.frame = self.currImageView.frame;
            _otherImageView.alpha = 0;
            [self insertSubview:self.currImageView atIndex:0];
            [self insertSubview:self.otherImageView atIndex:1];
        }
        [self startTimer];
    } else {
        //只要一张图片时，scrollview不可滚动，且关闭定时器
        self.scrollView.contentSize = CGSizeZero;
        self.scrollView.contentOffset = CGPointZero;
        self.currImageView.frame = CGRectMake(0, 0, self.width, self.height);
        [self stopTimer];
    }
}

#pragma mark 设置pageControl的指示器颜色
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor {
    _pageControl.pageIndicatorTintColor = color;
    _pageControl.currentPageIndicatorTintColor = currentColor;
}
#pragma mark 设置pageControl的指示器图片
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage {
    if (!image || !currentImage) return;
    self.pageImageSize = image.size;
    [self.pageControl setValue:currentImage forKey:@"_currentPageImage"];
    [self.pageControl setValue:image forKey:@"_pageImage"];
}
#pragma mark 设置pageControl的位置
- (void)setPagePosition:(PageControlPosition)pagePosition {
    _pagePosition = pagePosition;
    _pageControl.hidden = (_pagePosition == PositionHide) || (_imageArray.count == 1);
    if (_pageControl.hidden) return;
    
    CGSize size;
    if (!_pageImageSize.width) {//没有设置图片，系统原有样式
        size = [_pageControl sizeForNumberOfPages:_pageControl.numberOfPages];
        size.height = 8;
    } else {//设置图片了
        size = CGSizeMake(_pageImageSize.width * (_pageControl.numberOfPages * 2 - 1), _pageImageSize.height);
    }
    _pageControl.frame = CGRectMake(0, 0, size.width, size.height);
    
    CGFloat centerY = self.height - size.height * 0.5 - VERMARGIN - (_describeLabel.hidden?0: DES_LABEL_H);
    CGFloat pointY = self.height - size.height - VERMARGIN - (_describeLabel.hidden?0: DES_LABEL_H);
    
    if (_pagePosition == PositionNone || _pagePosition == PositionBottomCenter)
        _pageControl.center = CGPointMake(self.width * 0.5, centerY);
    else if (_pagePosition == PositionTopCenter)
        _pageControl.center = CGPointMake(self.width * 0.5, size.height * 0.5 + VERMARGIN);
    else if (_pagePosition == PositionBottomLeft)
        _pageControl.frame = CGRectMake(HORMARGIN, pointY, size.width, size.height);
    else
        _pageControl.frame = CGRectMake(self.width - HORMARGIN - size.width, pointY, size.width, size.height);
}
#pragma mark 设置定时器时间
- (void)setTime:(NSTimeInterval)time {
    _time = time;
    [self startTimer];
}
#pragma mark 定时器
- (void)startTimer {
    //如果只有一张图片，则直接返回，不开启定时器
    if (_images.count <= 1) return;
    //如果定时器已开启，先停止再重新开启
    if (self.timer) [self stopTimer];
    self.timer = [NSTimer timerWithTimeInterval:_time < 2? DEFAULTTIME: _time target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)nextPage {
    if (_changeMode == ChangeModeFade) {
        //淡入淡出模式，不需要修改scrollview偏移量，改变两张图片的透明度即可
        self.nextIndex = (self.currIndex + 1) % _images.count;
        self.otherImageView.image = _images[_nextIndex];
        
        [UIView animateWithDuration:1.2 animations:^{
            self.currImageView.alpha = 0;
            self.otherImageView.alpha = 1;
            self.pageControl.currentPage = _nextIndex;
        } completion:^(BOOL finished) {
            [self changeToNext];
        }];
        
    } else [self.scrollView setContentOffset:CGPointMake(self.width * 3, 0) animated:YES];
}
/***************************************************/
#pragma mark- -----------其它-----------
#pragma mark 布局子控件
- (void)layoutSubviews {
    [super layoutSubviews];
    //有导航控制器时，会默认在scrollview上方添加64的内边距，这里强制设置为0
    _scrollView.contentInset = UIEdgeInsetsZero;
    
    _scrollView.frame = self.bounds;
//    _describeLabel.frame = CGRectMake(0, self.height - DES_LABEL_H, self.width, DES_LABEL_H);
    //重新计算pageControl的位置
    self.pagePosition = self.pagePosition;
    [self setScrollViewContentSize];
}
#pragma mark 图片点击事件
- (void)imageClick {
    if (self.imageClickBlock) {
        self.imageClickBlock(self.currIndex);
    } else if ([_delegate respondsToSelector:@selector(carouselView:clickImageAtIndex:)]){
        [_delegate carouselView:self clickImageAtIndex:self.currIndex];
    }
}


/***************************************************/
#pragma mark 下载网络图片
- (void)downloadImages:(int)index {
    NSString *urlString = _imageArray[index];
    NSString *imageName = [urlString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *path = [cache stringByAppendingPathComponent:imageName];
    if (_autoCache) {
        //从沙盒中取图片
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            _images[index] = getImageWithData(data);
            return;
        }
    }
    //下载图片
    NSBlockOperation *download = [NSBlockOperation blockOperationWithBlock:^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if (!data) return;
        UIImage *image = getImageWithData(data);
        //取到的data有可能不是图片
        if (image) {
            self.images[index] = image;
            //如果下载的图片为当前要显示的图片，直接到主线程给imageView赋值，否则要等到下一轮才会显示
            if (_currIndex == index) [_currImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
            if (_autoCache) [data writeToFile:path atomically:YES];
        }
    }];
    [self.queue addOperation:download];
}

#pragma mark 下载图片，如果是gif则计算动画时长
UIImage *getImageWithData(NSData *data) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(imageSource);
    if (count <= 1) { //非gif
        CFRelease(imageSource);
        return [[UIImage alloc] initWithData:data];
    } else { //gif图片
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
            if (!image) continue;
            duration += durationWithSourceAtIndex(imageSource, i);
            [images addObject:[UIImage imageWithCGImage:image]];
            CGImageRelease(image);
        }
        if (!duration) duration = 0.1 * count;
        CFRelease(imageSource);
        return [UIImage animatedImageWithImages:images duration:duration];
    }
}
#pragma mark 获取每一帧图片的时长
float durationWithSourceAtIndex(CGImageSourceRef source, NSUInteger index) {
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *properties = (__bridge NSDictionary *)propertiesRef;
    NSDictionary *gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) duration = delayTime.floatValue;
    else {
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) duration = delayTime.floatValue;
    }
    CFRelease(propertiesRef);
    return duration;
}

/***************************************************/
#pragma mark 清除沙盒中的图片缓存
+ (void)clearDiskCache {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cache error:NULL];
    for (NSString *fileName in contents) {
        [[NSFileManager defaultManager] removeItemAtPath:[cache stringByAppendingPathComponent:fileName] error:nil];
    }
}
#pragma mark 当图片滚动过半时就修改当前页码
- (void)changeCurrentPageWithOffset:(CGFloat)offsetX {
    if (offsetX < self.width * 1.5) {
        NSInteger index = self.currIndex - 1;
        if (index < 0) index = self.images.count - 1;
        _pageControl.currentPage = index;
    } else if (offsetX > self.width * 2.5){
        _pageControl.currentPage = (self.currIndex + 1) % self.images.count;
    } else {
        _pageControl.currentPage = self.currIndex;
    }
}
/***************************************************/
#pragma mark 代理方法
#pragma mark- --------UIScrollViewDelegate--------
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (CGSizeEqualToSize(CGSizeZero, scrollView.contentSize)) return;
    CGFloat offsetX = scrollView.contentOffset.x;
    //滚动过程中改变pageControl的当前页码
    [self changeCurrentPageWithOffset:offsetX];
    
    //向右滚动
    if (offsetX < self.width * 2) {
        if (_changeMode == ChangeModeFade) {
            self.currImageView.alpha = offsetX / self.width - 1;
            self.otherImageView.alpha = 2 - offsetX / self.width;
        } else self.otherImageView.frame = CGRectMake(self.width, 0, self.width, self.height);
        
        self.nextIndex = self.currIndex - 1;
        if (self.nextIndex < 0) self.nextIndex = _images.count - 1;
        self.otherImageView.image = self.images[self.nextIndex];
        if (offsetX <= self.width) [self changeToNext];
        
        //向左滚动
    } else if (offsetX > self.width * 2){
        if (_changeMode == ChangeModeFade) {
            self.otherImageView.alpha = offsetX / self.width - 2;
            self.currImageView.alpha = 3 - offsetX / self.width;
        } else self.otherImageView.frame = CGRectMake(CGRectGetMaxX(_currImageView.frame), 0, self.width, self.height);
        
        self.nextIndex = (self.currIndex + 1) % _images.count;
        self.otherImageView.image = self.images[self.nextIndex];
        if (offsetX >= self.width * 3) [self changeToNext];
    }
}

- (void)changeToNext {
    if (_changeMode == ChangeModeFade) {
        self.currImageView.alpha = 1;
        self.otherImageView.alpha = 0;
    }
    //切换到下一张图片
    self.currImageView.image = self.otherImageView.image;
    self.scrollView.contentOffset = CGPointMake(self.width * 2, 0);
    self.currIndex = self.nextIndex;
    self.pageControl.currentPage = self.currIndex;
//    self.describeLabel.text = self.describeArray[self.currIndex];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self startTimer];
}

UIImage *gifImageNamed(NSString *imageName) {
    
    if (![imageName hasSuffix:@".gif"]) {
        imageName = [imageName stringByAppendingString:@".gif"];
    }
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    if (data) return getImageWithData(data);
    
    return [UIImage imageNamed:imageName];
}
@end

