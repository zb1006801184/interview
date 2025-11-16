# iOS 面试题 - 性能优化

本文档整理了 iOS 开发中性能优化相关的面试题，涵盖了启动优化、卡顿优化、内存优化、网络优化、图片优化等多个方面。

---

## 一、启动优化

### 1. App 启动流程分为哪几个阶段？

**答案：**

App 启动分为三个阶段：

1. **main() 函数之前（pre-main）**
   - 加载可执行文件（Mach-O）
   - 加载动态库（dyld）
   - Rebase 和 Bind
   - ObjC 类的注册
   - 执行 +load 方法
   - 执行 C++ 构造函数

2. **main() 函数之后（post-main）**
   - 执行 main() 函数
   - 执行 UIApplicationMain()
   - 创建 Application 对象
   - 创建 AppDelegate 对象
   - 执行 didFinishLaunchingWithOptions
   - 创建主窗口和根视图控制器

3. **首屏渲染完成**
   - 视图控制器的 viewDidLoad
   - 视图控制器的 viewWillAppear
   - 视图控制器的 viewDidAppear

### 2. 如何优化 App 启动时间？

**答案：**

#### 2.1 pre-main 阶段优化

1. **减少动态库数量**
   - 合并动态库，减少 dyld 加载时间
   - 使用静态库替代动态库（如果可能）

2. **减少 ObjC 类、方法、分类数量**
   - 清理未使用的类和方法
   - 合并功能相似的方法

3. **减少 +load 方法**
   - 将 +load 中的逻辑延迟到 +initialize 或首屏渲染后
   - 使用 `__attribute__((constructor))` 替代 +load（如果可能）

4. **减少 C++ 全局对象**
   - 减少 C++ 静态对象的构造时间

5. **使用 Swift 替代 ObjC**
   - Swift 的启动性能更好

#### 2.2 post-main 阶段优化

1. **延迟初始化**
   - 将非首屏必需的初始化延迟到首屏渲染后
   - 使用懒加载

2. **减少首屏视图层级**
   - 简化首屏视图结构
   - 使用更轻量的视图组件

3. **异步处理**
   - 将网络请求、数据解析等耗时操作放到后台线程
   - 使用异步加载图片

4. **减少主线程阻塞**
   - 避免在主线程进行文件 I/O、数据库操作等

**代码示例：**

```objc
// 延迟初始化示例
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 首屏必需的操作
    [self setupUI];
    
    // 延迟非必需的操作
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupNonEssentialFeatures];
    });
}

// 懒加载示例
- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [self loadDataFromNetwork];
    }
    return _dataArray;
}
```

### 3. 如何测量 App 启动时间？

**答案：**

1. **使用 Xcode 的启动时间统计**
   - 在 Xcode 中运行 App，查看控制台输出的启动时间

2. **使用 Instruments 的 Time Profiler**
   - 分析启动过程中的耗时操作

3. **代码埋点**
   - 在 main() 函数开始和首屏渲染完成时记录时间戳

**代码示例：**

```objc
// main.m
CFAbsoluteTime startTime;

int main(int argc, char * argv[]) {
    startTime = CFAbsoluteTimeGetCurrent();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

// AppDelegate.m
extern CFAbsoluteTime startTime;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CFAbsoluteTime launchTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"启动时间: %.2f 秒", launchTime);
    return YES;
}

// 首屏渲染完成
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CFAbsoluteTime renderTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"首屏渲染时间: %.2f 秒", renderTime);
}
```

---

## 二、卡顿优化

### 4. 什么是卡顿？卡顿产生的原因是什么？

**答案：**

卡顿是指 App 界面出现掉帧、不流畅的现象。iOS 设备通常以 60 FPS（每秒 60 帧）运行，即每帧需要在 16.67ms 内完成渲染。如果某一帧的渲染时间超过 16.67ms，就会出现掉帧。

**卡顿产生的原因：**

1. **主线程阻塞**
   - 在主线程进行耗时操作（网络请求、文件 I/O、数据库操作、复杂计算等）

2. **视图层级过深**
   - 视图层级过深导致布局计算耗时

3. **视图渲染复杂**
   - 复杂的绘制操作（圆角、阴影、模糊等）
   - 大量的视图更新

4. **内存压力**
   - 内存不足导致频繁的垃圾回收

5. **GPU 渲染瓶颈**
   - 离屏渲染（Offscreen Rendering）
   - 过多的纹理和图层

### 5. 如何检测和定位卡顿？

**答案：**

1. **使用 Instruments 的 Time Profiler**
   - 分析主线程的耗时操作

2. **使用 Instruments 的 Core Animation**
   - 检测离屏渲染、图层混合等问题

3. **使用 CADisplayLink 监控 FPS**
   - 实时监控帧率

4. **代码埋点**
   - 监控主线程的耗时操作

**代码示例：**

```objc
// FPS 监控
@interface FPSMonitor : NSObject
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
@property (nonatomic, assign) NSInteger frameCount;
@end

@implementation FPSMonitor

- (void)startMonitoring {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    
    self.frameCount++;
    NSTimeInterval interval = link.timestamp - self.lastTimestamp;
    
    if (interval >= 1.0) {
        NSInteger fps = self.frameCount / interval;
        NSLog(@"FPS: %ld", (long)fps);
        
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

@end
```

### 6. 如何优化卡顿？

**答案：**

#### 6.1 主线程优化

1. **异步处理耗时操作**
   - 将网络请求、文件 I/O、数据库操作等放到后台线程

2. **减少主线程的计算量**
   - 将复杂计算放到后台线程
   - 使用缓存减少重复计算

**代码示例：**

```objc
// 异步处理网络请求
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSData *data = [NSData dataWithContentsOfURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新 UI
        self.imageView.image = [UIImage imageWithData:data];
    });
});

// 异步处理数据库操作
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *results = [self fetchDataFromDatabase];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataArray = results;
        [self.tableView reloadData];
    });
});
```

#### 6.2 视图优化

1. **减少视图层级**
   - 使用更扁平化的视图结构
   - 避免不必要的容器视图

2. **减少视图数量**
   - 使用 UITableView/UICollectionView 的复用机制
   - 避免创建过多的子视图

3. **优化视图布局**
   - 使用 Auto Layout 时，减少约束的复杂度
   - 使用 frame 布局（如果可能）

4. **减少视图更新频率**
   - 批量更新视图
   - 使用 setNeedsDisplay 替代 setNeedsDisplayInRect（如果可能）

**代码示例：**

```objc
// 批量更新视图
- (void)updateViews {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    // 批量更新多个视图
    self.label1.text = @"Text 1";
    self.label2.text = @"Text 2";
    self.label3.text = @"Text 3";
}

// 使用 cell 复用
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}
```

#### 6.3 渲染优化

1. **减少离屏渲染**
   - 避免使用 cornerRadius + masksToBounds
   - 使用 CAShapeLayer 替代 cornerRadius（如果可能）
   - 避免使用 shadowPath（如果可能）

2. **减少图层混合**
   - 避免使用半透明视图
   - 使用 opaque 属性

3. **优化图片渲染**
   - 使用合适尺寸的图片
   - 使用图片缓存
   - 异步加载图片

**代码示例：**

```objc
// 避免离屏渲染
// 不推荐
view.layer.cornerRadius = 10;
view.layer.masksToBounds = YES;

// 推荐：使用 CAShapeLayer
CAShapeLayer *maskLayer = [CAShapeLayer layer];
maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:view.bounds 
                                            cornerRadius:10].CGPath;
view.layer.mask = maskLayer;

// 设置 opaque 属性
view.opaque = YES;
view.backgroundColor = [UIColor whiteColor];
```

---

## 三、内存优化

### 7. 如何检测内存问题？

**答案：**

1. **使用 Instruments 的 Leaks**
   - 检测内存泄漏

2. **使用 Instruments 的 Allocations**
   - 分析内存分配情况
   - 检测内存峰值

3. **使用 Instruments 的 VM Tracker**
   - 分析虚拟内存使用情况

4. **代码埋点**
   - 监控内存使用情况

**代码示例：**

```objc
// 内存监控
- (void)logMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    
    if (kerr == KERN_SUCCESS) {
        NSLog(@"内存使用: %.2f MB", info.resident_size / 1024.0 / 1024.0);
    }
}
```

### 8. 如何优化内存使用？

**答案：**

#### 8.1 避免内存泄漏

1. **避免循环引用**
   - 使用 weak 引用打破循环引用
   - 注意 block 中的循环引用

2. **及时释放资源**
   - 在 dealloc 中释放资源
   - 使用 @autoreleasepool 及时释放临时对象

**代码示例：**

```objc
// 避免 block 循环引用
__weak typeof(self) weakSelf = self;
[self.networkManager requestWithCompletion:^(NSData *data) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
        [strongSelf handleData:data];
    }
}];

// 使用 @autoreleasepool
for (int i = 0; i < 1000; i++) {
    @autoreleasepool {
        NSData *data = [self loadLargeData];
        [self processData:data];
    }
}
```

#### 8.2 减少内存占用

1. **使用懒加载**
   - 延迟对象的创建

2. **及时释放不需要的对象**
   - 使用 weak 引用
   - 及时清空缓存

3. **优化图片内存**
   - 使用合适尺寸的图片
   - 及时释放图片缓存
   - 使用 imageNamed: 时注意内存管理

4. **优化数据结构**
   - 使用更轻量的数据结构
   - 避免存储冗余数据

**代码示例：**

```objc
// 懒加载
- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [self loadData];
    }
    return _dataArray;
}

// 优化图片内存
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

// 及时释放图片缓存
[[SDImageCache sharedImageCache] clearMemory];
```

---

## 四、网络优化

### 9. 如何优化网络请求？

**答案：**

1. **减少请求次数**
   - 合并多个请求
   - 使用批量接口

2. **减少请求数据量**
   - 使用压缩（gzip）
   - 只请求必要的数据
   - 使用分页加载

3. **优化请求时机**
   - 预加载数据
   - 延迟非必需请求

4. **使用缓存**
   - 缓存响应数据
   - 使用 ETag 和 Last-Modified

5. **优化网络库**
   - 使用连接池
   - 使用 HTTP/2
   - 使用 CDN

**代码示例：**

```objc
// 使用缓存
- (void)loadDataWithCache {
    // 先尝试从缓存加载
    NSData *cachedData = [self.cache objectForKey:@"data"];
    if (cachedData) {
        [self handleData:cachedData];
        return;
    }
    
    // 从网络加载
    [self.networkManager requestWithCompletion:^(NSData *data) {
        // 缓存数据
        [self.cache setObject:data forKey:@"data"];
        [self handleData:data];
    }];
}

// 使用 ETag
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
NSString *etag = [self getETagForURL:url];
if (etag) {
    [request setValue:etag forHTTPHeaderField:@"If-None-Match"];
}

[NSURLSession.sharedSession dataTaskWithRequest:request 
                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 304) {
        // 使用缓存
        [self useCachedData];
    } else {
        // 更新数据
        NSString *newETag = httpResponse.allHeaderFields[@"ETag"];
        [self saveETag:newETag forURL:url];
        [self handleData:data];
    }
}];
```

### 10. 如何处理网络请求的并发和优先级？

**答案：**

1. **使用 NSOperationQueue**
   - 控制并发数量
   - 设置请求优先级
   - 支持取消操作

2. **使用 NSURLSession**
   - 使用不同的 session configuration
   - 设置请求优先级

**代码示例：**

```objc
// 使用 NSOperationQueue
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 3; // 最大并发数

NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    [self.networkManager requestWithCompletion:^(NSData *data) {
        [self handleData:data];
    }];
}];
operation.queuePriority = NSOperationQueuePriorityHigh;
[queue addOperation:operation];

// 使用 NSURLSession 优先级
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
request.networkServiceType = NSURLNetworkServiceTypeBackground; // 后台优先级
// 或
request.networkServiceType = NSURLNetworkServiceTypeVoIP; // 高优先级
```

---

## 五、图片优化

### 11. 如何优化图片加载和显示？

**答案：**

1. **使用合适尺寸的图片**
   - 根据显示尺寸加载对应尺寸的图片
   - 避免加载过大的图片

2. **使用图片缓存**
   - 使用 SDWebImage 等第三方库
   - 实现内存缓存和磁盘缓存

3. **异步加载图片**
   - 在后台线程解码图片
   - 在主线程更新 UI

4. **使用图片格式优化**
   - 使用 WebP 格式（如果支持）
   - 使用 HEIF 格式（iOS 11+）

5. **优化图片渲染**
   - 使用 CALayer 的 contentsGravity
   - 避免频繁创建 UIImage

**代码示例：**

```objc
// 异步加载和缓存图片
- (void)loadImageWithURL:(NSURL *)url {
    // 先尝试从缓存加载
    UIImage *cachedImage = [self.imageCache objectForKey:url.absoluteString];
    if (cachedImage) {
        self.imageView.image = cachedImage;
        return;
    }
    
    // 异步加载
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        
        // 调整图片尺寸
        image = [self resizeImage:image toSize:self.imageView.bounds.size];
        
        // 缓存图片
        [self.imageCache setObject:image forKey:url.absoluteString];
        
        // 更新 UI
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    });
}

// 使用 SDWebImage
[self.imageView sd_setImageWithURL:url 
                   placeholderImage:placeholder 
                            options:SDWebImageRetryFailed | SDWebImageLowPriority];
```

### 12. 如何处理大图片的内存问题？

**答案：**

1. **使用图片解码优化**
   - 使用 ImageIO 框架解码
   - 使用 downsampling 技术

2. **分块加载**
   - 对于超大图片，使用分块加载

3. **及时释放**
   - 使用完成后及时释放图片对象

**代码示例：**

```objc
// 使用 ImageIO 解码大图片
- (UIImage *)downsampleImageAtURL:(NSURL *)imageURL toSize:(CGSize)pointSize {
    NSDictionary *imageSourceOptions = @{
        (__bridge NSString *)kCGImageSourceShouldCache: @NO
    };
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, 
                                                              (__bridge CFDictionaryRef)imageSourceOptions);
    
    CGFloat maxDimensionInPixels = MAX(pointSize.width, pointSize.height);
    NSDictionary *downsampleOptions = @{
        (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately: @YES,
        (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize: @(maxDimensionInPixels)
    };
    
    CGImageRef downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, 
                                                                      (__bridge CFDictionaryRef)downsampleOptions);
    UIImage *image = [UIImage imageWithCGImage:downsampledImage];
    
    CGImageRelease(downsampledImage);
    CFRelease(imageSource);
    
    return image;
}
```

---

## 六、数据库优化

### 13. 如何优化 Core Data 性能？

**答案：**

1. **使用合适的存储类型**
   - 根据数据量选择合适的存储类型（SQLite、Binary、In-Memory）

2. **优化查询**
   - 使用索引
   - 使用谓词优化查询
   - 使用 fetchLimit 和 fetchOffset

3. **批量操作**
   - 使用批量更新和删除
   - 使用 batch faulting

4. **异步操作**
   - 在后台线程进行数据库操作

**代码示例：**

```objc
// 批量操作
NSBatchUpdateRequest *batchUpdate = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Person"];
batchUpdate.propertiesToUpdate = @{@"age": @25};
batchUpdate.predicate = [NSPredicate predicateWithFormat:@"age < 18"];
NSBatchUpdateResult *result = [context executeRequest:batchUpdate error:&error];

// 使用 fetchLimit
NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
request.fetchLimit = 20;
request.fetchOffset = 0;
NSArray *results = [context executeFetchRequest:request error:&error];

// 异步操作
NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] 
                                             initWithConcurrencyType:NSPrivateQueueConcurrencyType];
backgroundContext.parentContext = mainContext;

[backgroundContext performBlock:^{
    // 数据库操作
    [self insertDataInContext:backgroundContext];
    
    NSError *error = nil;
    [backgroundContext save:&error];
    
    [mainContext performBlock:^{
        [mainContext save:&error];
    }];
}];
```

### 14. 如何优化 SQLite 性能？

**答案：**

1. **使用事务**
   - 批量操作时使用事务

2. **使用索引**
   - 为经常查询的字段创建索引

3. **优化查询语句**
   - 使用 EXPLAIN QUERY PLAN 分析查询
   - 避免 SELECT *
   - 使用 LIMIT

4. **使用 WAL 模式**
   - 启用 Write-Ahead Logging

**代码示例：**

```objc
// 使用事务
[db beginTransaction];
for (int i = 0; i < 1000; i++) {
    [db executeUpdate:@"INSERT INTO Person (name, age) VALUES (?, ?)", 
     [NSString stringWithFormat:@"Person %d", i], @(i)];
}
[db commit];

// 创建索引
[db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_age ON Person(age)"];

// 使用 WAL 模式
[db executeUpdate:@"PRAGMA journal_mode=WAL"];
```

---

## 七、其他优化

### 15. 如何优化列表滚动性能？

**答案：**

1. **使用 cell 复用**
   - UITableView/UICollectionView 的 cell 复用机制

2. **减少 cell 的复杂度**
   - 简化 cell 的视图层级
   - 减少 cell 中的子视图数量

3. **异步加载数据**
   - 异步加载图片和数据

4. **优化布局计算**
   - 缓存 cell 高度
   - 使用 estimatedRowHeight（如果可能）

5. **减少主线程操作**
   - 在后台线程处理数据

**代码示例：**

```objc
// 缓存 cell 高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    NSNumber *cachedHeight = self.heightCache[key];
    if (cachedHeight) {
        return cachedHeight.floatValue;
    }
    
    CGFloat height = [self calculateHeightForIndexPath:indexPath];
    self.heightCache[key] = @(height);
    return height;
}

// 异步加载图片
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSURL *imageURL = self.imageURLs[indexPath.row];
    
    // 异步加载图片
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self loadImageFromURL:imageURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                cell.imageView.image = image;
            }
        });
    });
    
    return cell;
}
```

### 16. 如何使用 Instruments 进行性能分析？

**答案：**

Instruments 是 Xcode 提供的性能分析工具，常用的工具包括：

1. **Time Profiler**
   - 分析 CPU 使用情况
   - 找出耗时操作

2. **Allocations**
   - 分析内存分配
   - 检测内存泄漏

3. **Leaks**
   - 检测内存泄漏

4. **Core Animation**
   - 分析渲染性能
   - 检测离屏渲染

5. **Network**
   - 分析网络请求

6. **Energy Log**
   - 分析电量消耗

**使用步骤：**

1. 在 Xcode 中选择 Product > Profile（或按 Cmd+I）
2. 选择要使用的工具
3. 运行 App 并执行相关操作
4. 分析结果并优化

### 17. 如何优化 App 的电量消耗？

**答案：**

1. **减少 CPU 使用**
   - 优化算法
   - 减少不必要的计算

2. **优化网络请求**
   - 减少请求频率
   - 使用批量请求
   - 使用缓存

3. **优化定位服务**
   - 使用合适的定位精度
   - 及时停止定位服务

4. **优化定时器**
   - 减少定时器的使用
   - 使用合适的定时器间隔

5. **优化后台任务**
   - 减少后台任务
   - 使用后台任务的最佳实践

**代码示例：**

```objc
// 优化定位服务
- (void)startLocationService {
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 降低精度
    self.locationManager.distanceFilter = 100; // 设置距离过滤
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocationService {
    [self.locationManager stopUpdatingLocation];
}

// 优化定时器
- (void)setupTimer {
    // 使用合适的间隔
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 
                                                  target:self 
                                                selector:@selector(timerFired:) 
                                                userInfo:nil 
                                                 repeats:YES];
}
```

---

## 八、性能优化最佳实践

### 18. 性能优化的优先级是什么？

**答案：**

性能优化的优先级应该根据影响程度和优化成本来确定：

1. **高优先级**
   - 启动时间优化（直接影响用户体验）
   - 卡顿优化（直接影响用户体验）
   - 内存泄漏修复（可能导致崩溃）

2. **中优先级**
   - 内存使用优化
   - 网络请求优化
   - 图片加载优化

3. **低优先级**
   - 代码结构优化
   - 算法优化（如果性能已经满足需求）

### 19. 性能优化的原则是什么？

**答案：**

1. **测量优先**
   - 先测量，再优化
   - 使用数据驱动优化

2. **关注用户体验**
   - 优化用户能感知到的性能
   - 优先优化高频场景

3. **平衡性能和代码质量**
   - 不要过度优化
   - 保持代码可读性和可维护性

4. **持续优化**
   - 性能优化是一个持续的过程
   - 定期检查和优化

### 20. 如何建立性能监控体系？

**答案：**

1. **关键指标监控**
   - 启动时间
   - FPS
   - 内存使用
   - 网络请求耗时
   - 崩溃率

2. **埋点统计**
   - 在关键位置埋点
   - 收集性能数据

3. **异常监控**
   - 监控异常情况
   - 及时告警

4. **数据分析**
   - 分析性能数据
   - 找出性能瓶颈

**代码示例：**

```objc
// 性能监控类
@interface PerformanceMonitor : NSObject
+ (instancetype)sharedInstance;
- (void)startMonitoring;
- (void)stopMonitoring;
- (void)logEvent:(NSString *)event duration:(NSTimeInterval)duration;
@end

@implementation PerformanceMonitor

- (void)logEvent:(NSString *)event duration:(NSTimeInterval)duration {
    // 上报到服务器
    NSDictionary *data = @{
        @"event": event,
        @"duration": @(duration),
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    [self reportToServer:data];
}

@end

// 使用示例
- (void)viewDidLoad {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    [super viewDidLoad];
    // ... 初始化代码 ...
    CFAbsoluteTime duration = CFAbsoluteTimeGetCurrent() - startTime;
    [[PerformanceMonitor sharedInstance] logEvent:@"viewDidLoad" duration:duration];
}
```

---

## 总结

性能优化是 iOS 开发中的重要环节，需要从多个方面进行考虑：

1. **启动优化**：减少 pre-main 和 post-main 阶段的耗时
2. **卡顿优化**：保证 60 FPS 的流畅度
3. **内存优化**：避免内存泄漏，减少内存占用
4. **网络优化**：减少请求次数和数据量，使用缓存
5. **图片优化**：使用合适尺寸的图片，异步加载
6. **数据库优化**：优化查询，使用批量操作
7. **其他优化**：列表滚动、电量消耗等

在进行性能优化时，要遵循"测量优先"的原则，使用 Instruments 等工具进行性能分析，建立性能监控体系，持续优化 App 的性能。

