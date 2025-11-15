# iOS 面试题 - 内存管理

## 1. 什么是内存管理？

内存管理是程序运行时对内存的分配、使用和释放的管理过程。在 iOS 开发中，主要涉及对象的内存管理，确保对象在使用时存在，不使用及时释放，避免内存泄漏和野指针。

## 2. MRC 和 ARC 的区别？

### 2.1 MRC（Manual Reference Counting）

MRC 是手动引用计数，需要开发者手动管理对象的内存。

```objc
// MRC 下需要手动管理
NSObject *obj = [[NSObject alloc] init]; // retainCount = 1
[obj retain]; // retainCount = 2
[obj release]; // retainCount = 1
[obj release]; // retainCount = 0, 对象被释放
```

### 2.2 ARC（Automatic Reference Counting）

ARC 是自动引用计数，编译器自动插入 retain/release 代码。

```objc
// ARC 下自动管理
NSObject *obj = [[NSObject alloc] init]; // 编译器自动插入 retain
// 作用域结束时，编译器自动插入 release
```

### 2.3 对比

| 特性 | MRC | ARC |
|------|-----|-----|
| 管理方式 | 手动 | 自动 |
| retain/release | 需要手动调用 | 编译器自动插入 |
| 性能 | 相同 | 相同 |
| 代码量 | 多 | 少 |
| 错误率 | 高 | 低 |

## 3. 引用计数的原理？

### 3.1 基本概念

每个对象都有一个引用计数器（retainCount），记录有多少个对象引用了它：
- 对象创建时，retainCount = 1
- 调用 retain，retainCount + 1
- 调用 release，retainCount - 1
- 当 retainCount = 0 时，对象被释放

### 3.2 代码示例

```objc
// MRC 下
NSObject *obj1 = [[NSObject alloc] init]; // retainCount = 1
NSObject *obj2 = obj1; // retainCount 仍然是 1
[obj1 retain]; // retainCount = 2
[obj1 release]; // retainCount = 1
[obj2 release]; // retainCount = 0, 对象被释放
```

## 4. 什么是强引用（Strong Reference）？

强引用会增加对象的引用计数，只要存在强引用，对象就不会被释放。

### 4.1 代码示例

```objc
@property (nonatomic, strong) NSString *name; // 强引用

- (void)example {
    NSString *str = [[NSString alloc] initWithString:@"Hello"]; // retainCount = 1
    self.name = str; // retainCount = 2
    // str 作用域结束，retainCount = 1
    // self.name 仍然持有对象，对象不会被释放
}
```

## 5. 什么是弱引用（Weak Reference）？

弱引用不会增加对象的引用计数，当对象被释放时，弱引用会自动置为 nil。

### 5.1 代码示例

```objc
@property (nonatomic, weak) id delegate; // 弱引用

- (void)example {
    NSObject *obj = [[NSObject alloc] init]; // retainCount = 1
    self.delegate = obj; // retainCount 仍然是 1
    // obj 作用域结束，retainCount = 0, 对象被释放
    // self.delegate 自动变为 nil
}
```

### 5.2 弱引用的实现原理

弱引用通过 SideTable 实现，当对象被释放时，会遍历所有弱引用，将其置为 nil。

## 6. 什么是循环引用？

循环引用是指两个或多个对象相互强引用，导致引用计数无法降为 0，对象无法释放。

### 6.1 循环引用示例

```objc
// Person.h
@interface Person : NSObject
@property (nonatomic, strong) Person *friend; // 强引用
@end

// 循环引用
Person *person1 = [[Person alloc] init];
Person *person2 = [[Person alloc] init];
person1.friend = person2; // person1 强引用 person2
person2.friend = person1; // person2 强引用 person1
// 两个对象都无法释放
```

### 6.2 解决方案

```objc
// 使用弱引用
@property (nonatomic, weak) Person *friend; // 弱引用，打破循环
```

## 7. Block 的循环引用？

### 7.1 Block 循环引用示例

```objc
@interface ViewController : UIViewController
@property (nonatomic, strong) void (^block)(void);
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // 循环引用：self -> block -> self
    self.block = ^{
        NSLog(@"%@", self.name); // self 强引用 block，block 强引用 self
    };
}
@end
```

### 7.2 解决方案

```objc
// 方式1：使用 __weak
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};

// 方式2：使用 __block（MRC）
__block ViewController *blockSelf = self;
self.block = ^{
    NSLog(@"%@", blockSelf.name);
    blockSelf = nil; // 打破循环
};
```

## 8. Delegate 的循环引用？

### 8.1 问题示例

```objc
// 错误：使用 strong
@property (nonatomic, strong) id<CustomDelegate> delegate; // 可能导致循环引用
```

### 8.2 解决方案

```objc
// 正确：使用 weak
@property (nonatomic, weak) id<CustomDelegate> delegate; // 弱引用，避免循环引用
```

## 9. NSTimer 的循环引用？

### 9.1 问题示例

```objc
@interface ViewController : UIViewController
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // 循环引用：self -> timer -> self
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                  target:self 
                                                selector:@selector(timerAction) 
                                                userInfo:nil 
                                                 repeats:YES];
}
@end
```

### 9.2 解决方案

```objc
// 方式1：使用 weak 代理对象
@interface TimerProxy : NSObject
@property (nonatomic, weak) id target;
@end

@implementation TimerProxy
- (void)timerAction {
    [self.target performSelector:@selector(timerAction)];
}
@end

// 使用
TimerProxy *proxy = [[TimerProxy alloc] init];
proxy.target = self;
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                              target:proxy 
                                            selector:@selector(timerAction) 
                                            userInfo:nil 
                                             repeats:YES];

// 方式2：使用 Block（iOS 10+）
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                             repeats:YES 
                                               block:^(NSTimer * _Nonnull timer) {
    [self timerAction];
}];

// 方式3：在 dealloc 中手动停止
- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
}
```

## 10. 什么是内存泄漏？

内存泄漏是指已分配的内存无法被释放，导致内存占用不断增加。

### 10.1 常见原因

- 循环引用
- 未释放的观察者（KVO、Notification）
- 未停止的定时器
- 未释放的 Core Foundation 对象

### 10.2 检测方法

- 使用 Instruments 的 Leaks 工具
- 使用 Xcode 的 Memory Graph Debugger
- 使用第三方工具（MLeaksFinder）

## 11. 什么是野指针？

野指针是指指向已释放内存的指针，访问野指针会导致崩溃。

### 11.1 示例

```objc
// MRC 下
NSObject *obj = [[NSObject alloc] init];
[obj release]; // 对象被释放
NSLog(@"%@", obj); // 访问野指针，可能崩溃
```

### 11.2 避免方法

- 释放后置为 nil：`obj = nil;`
- 使用 ARC（自动置为 nil）
- 使用弱引用（对象释放后自动置为 nil）

## 12. 什么是悬垂指针？

悬垂指针是指指向已释放内存的指针，与野指针类似，但通常指在对象释放后仍然持有的指针。

## 13. 什么是僵尸对象？

僵尸对象是指已经被释放但内存尚未被重新分配的对象。在调试时，可以启用 Zombie Objects 来检测对已释放对象的访问。

### 13.1 启用方法

在 Xcode 的 Scheme 中，Edit Scheme -> Run -> Diagnostics -> Enable Zombie Objects

## 14. 什么是 AutoreleasePool？

AutoreleasePool 是自动释放池，用于管理自动释放的对象。

### 14.1 工作原理

对象调用 `autorelease` 后，会被添加到当前的 AutoreleasePool 中。当 AutoreleasePool 被释放时，会对其中的所有对象调用 `release`。

### 14.2 代码示例

```objc
@autoreleasepool {
    NSString *str = [NSString stringWithFormat:@"Hello %@", @"World"];
    // str 调用 autorelease，被添加到池中
}
// 池释放时，str 被释放
```

### 14.3 应用场景

- 主线程 RunLoop 的每个循环
- 循环中创建大量临时对象
- 子线程需要及时释放对象

## 15. AutoreleasePool 的释放时机？

### 15.1 主线程

主线程的 RunLoop 在每个循环中会创建和释放 AutoreleasePool：
- RunLoop 进入时创建
- RunLoop 休眠前释放旧的，创建新的
- RunLoop 退出时释放

### 15.2 子线程

子线程需要手动创建 AutoreleasePool，否则对象可能不会及时释放。

```objc
- (void)threadMethod {
    @autoreleasepool {
        // 创建临时对象
        NSString *str = [NSString stringWithFormat:@"Hello"];
    }
    // 对象被释放
}
```

## 16. 什么是 Tagged Pointer？

Tagged Pointer 是苹果的优化技术，将小对象直接存储在指针中，而不是堆上。

### 16.1 特点

- 小对象（如小字符串、小数字）直接存储在指针中
- 不需要分配堆内存
- 不需要引用计数管理
- 提高性能，减少内存占用

### 16.2 示例

```objc
NSString *str1 = @"Hello"; // 可能是 Tagged Pointer
NSString *str2 = [NSString stringWithFormat:@"Hello %@", @"World"]; // 堆对象
```

## 17. 什么是 Copy-on-Write？

Copy-on-Write 是一种优化技术，只有在修改时才真正复制对象。

### 17.1 示例

```objc
NSMutableArray *array1 = [NSMutableArray arrayWithObjects:@1, @2, nil];
NSMutableArray *array2 = [array1 mutableCopy]; // 浅拷贝
// 此时两个数组可能共享内部存储
[array2 addObject:@3]; // 修改时才真正复制
```

## 18. 深拷贝和浅拷贝的区别？

### 18.1 浅拷贝（Shallow Copy）

只复制对象本身，不复制对象内部的引用对象。

```objc
NSArray *array1 = @[@1, @2, @3];
NSArray *array2 = [array1 copy]; // 浅拷贝
// array1 和 array2 指向不同的数组对象，但内部的元素是同一个对象
```

### 18.2 深拷贝（Deep Copy）

复制对象及其内部的所有引用对象。

```objc
NSArray *array1 = @[@1, @2, @3];
NSArray *array2 = [[NSArray alloc] initWithArray:array1 copyItems:YES]; // 深拷贝
// array1 和 array2 以及内部的元素都是不同的对象
```

### 18.3 实现深拷贝

```objc
// 方式1：使用 NSCopying 协议
- (id)copyWithZone:(NSZone *)zone {
    MyClass *copy = [[[self class] allocWithZone:zone] init];
    copy.property = [self.property copy];
    return copy;
}

// 方式2：使用归档
NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
MyClass *copy = [NSKeyedUnarchiver unarchiveObjectWithData:data];
```

## 19. 属性的 copy 和 strong 的区别？

### 19.1 copy

`copy` 会创建对象的副本，适用于不可变对象。

```objc
@property (nonatomic, copy) NSString *name;

// 使用 copy
NSMutableString *mutableStr = [NSMutableString stringWithString:@"Hello"];
person.name = mutableStr; // 会调用 copy，创建不可变副本
[mutableStr appendString:@" World"];
// person.name 仍然是 "Hello"，因为 copy 创建了副本
```

### 19.2 strong

`strong` 是强引用，适用于可变对象。

```objc
@property (nonatomic, strong) NSMutableArray *items;

// 使用 strong
NSMutableArray *array = [NSMutableArray array];
person.items = array;
[array addObject:@"1"];
// person.items 也会包含 "1"，因为是同一个对象
```

### 19.3 选择原则

- 不可变对象（NSString、NSArray 等）使用 `copy`
- 可变对象（NSMutableString、NSMutableArray 等）使用 `strong`
- 自定义对象根据需求选择

## 20. 什么是内存警告？

内存警告是系统在内存不足时发送的通知，应用应该释放不必要的内存。

### 20.1 处理内存警告

```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // 释放缓存
    [self clearCache];
    // 释放图片
    [self releaseImages];
}
```

### 20.2 内存警告级别

- `UIApplicationDidReceiveMemoryWarningNotification`：一般内存警告
- 系统可能会终止后台应用

## 21. 如何优化内存使用？

### 21.1 图片优化

```objc
// 使用合适的图片格式和大小
UIImage *image = [UIImage imageNamed:@"image.png"];
// 使用 imageWithContentsOfFile: 代替 imageNamed:（不缓存）

// 及时释放大图片
self.largeImage = nil;
```

### 21.2 缓存管理

```objc
// 使用 NSCache 代替 NSDictionary（自动释放）
NSCache *cache = [[NSCache alloc] init];
cache.countLimit = 100; // 限制数量
cache.totalCostLimit = 50 * 1024 * 1024; // 限制大小（50MB）
```

### 21.3 懒加载

```objc
- (NSArray *)dataArray {
    if (_dataArray == nil) {
        _dataArray = @[@1, @2, @3];
    }
    return _dataArray;
}
```

## 22. 什么是内存映射文件？

内存映射文件是将文件映射到内存中，可以像访问内存一样访问文件。

### 22.1 优点

- 提高文件访问性能
- 减少内存占用（按需加载）
- 多个进程可以共享

### 22.2 使用场景

- 大文件读取
- 数据库文件
- 图片缓存

## 23. 什么是内存对齐？

内存对齐是指数据在内存中的存储位置必须是对齐边界的倍数。

### 23.1 对齐规则

- 结构体的起始地址必须是其最大成员大小的倍数
- 结构体成员按照声明顺序存储
- 结构体总大小必须是最大成员大小的倍数

### 23.2 示例

```objc
struct Example {
    char a;      // 1 字节，偏移 0
    int b;       // 4 字节，偏移 4（对齐到 4 的倍数）
    char c;      // 1 字节，偏移 8
}; // 总大小 12 字节（对齐到 4 的倍数）
```

## 24. 如何检测内存泄漏？

### 24.1 使用 Instruments

1. 打开 Instruments
2. 选择 Leaks 模板
3. 运行应用
4. 查看泄漏的对象和调用栈

### 24.2 使用 Memory Graph Debugger

1. 在 Xcode 中运行应用
2. 点击 Debug Memory Graph 按钮
3. 查看对象引用关系

### 24.3 使用代码检测

```objc
// 在 dealloc 中打印日志
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}
```

## 25. 什么是 retain cycle（ retain 循环）？

retain cycle 就是循环引用，两个或多个对象相互强引用，导致无法释放。

## 26. weak 引用的实现原理？

### 26.1 SideTable

weak 引用通过 SideTable 实现：
- 每个对象都有一个 SideTable
- SideTable 中存储了所有指向该对象的 weak 引用
- 当对象被释放时，会遍历 SideTable，将所有 weak 引用置为 nil

### 26.2 代码流程

```
1. 创建 weak 引用时，将引用添加到对象的 SideTable
2. 对象释放时，调用 dealloc
3. dealloc 中遍历 SideTable，将所有 weak 引用置为 nil
4. 释放对象内存
```

## 27. 什么是 __unsafe_unretained？

`__unsafe_unretained` 是不安全的弱引用，不会增加引用计数，但对象释放后不会自动置为 nil。

### 27.1 与 weak 的区别

| 特性 | weak | __unsafe_unretained |
|------|------|---------------------|
| 引用计数 | 不增加 | 不增加 |
| 自动置 nil | 是 | 否 |
| 安全性 | 安全 | 不安全（可能野指针） |
| 性能 | 稍慢 | 稍快 |

### 27.2 使用场景

- 性能要求极高的场景
- 确定对象生命周期不会提前释放
- 兼容 iOS 4（weak 需要 iOS 5+）

## 28. 什么是 __bridge？

`__bridge` 用于 Objective-C 对象和 Core Foundation 对象之间的转换。

### 28.1 类型转换

```objc
// CFStringRef 转 NSString
CFStringRef cfString = CFStringCreateWithCString(NULL, "Hello", kCFStringEncodingUTF8);
NSString *nsString = (__bridge NSString *)cfString;
CFRelease(cfString);

// NSString 转 CFStringRef
NSString *nsString = @"Hello";
CFStringRef cfString = (__bridge CFStringRef)nsString;
// 不需要释放，因为所有权没有转移
```

### 28.2 其他桥接关键字

- `__bridge_retained`：转移所有权给 CF 对象
- `__bridge_transfer`：转移所有权给 OC 对象

## 29. 内存管理的常见面试题总结

1. **MRC 和 ARC 的区别？** - 手动 vs 自动管理
2. **引用计数的原理？** - retainCount 的增减
3. **强引用和弱引用的区别？** - 是否增加引用计数
4. **什么是循环引用？** - 对象相互强引用
5. **如何解决 Block 的循环引用？** - 使用 __weak
6. **如何解决 Delegate 的循环引用？** - 使用 weak
7. **如何解决 NSTimer 的循环引用？** - 使用 weak 代理或 Block
8. **什么是内存泄漏？** - 已分配内存无法释放
9. **什么是野指针？** - 指向已释放内存的指针
10. **什么是 AutoreleasePool？** - 自动释放池
11. **AutoreleasePool 的释放时机？** - RunLoop 循环
12. **深拷贝和浅拷贝的区别？** - 是否复制内部对象
13. **copy 和 strong 的区别？** - 创建副本 vs 强引用
14. **如何检测内存泄漏？** - Instruments、Memory Graph
15. **weak 引用的实现原理？** - SideTable
16. **__unsafe_unretained 和 weak 的区别？** - 是否自动置 nil
17. **什么是 __bridge？** - OC 和 CF 对象的转换
18. **如何优化内存使用？** - 图片优化、缓存管理、懒加载

## 30. 内存管理的最佳实践

### 30.1 避免循环引用

- Delegate 使用 weak
- Block 中使用 weakSelf
- NSTimer 使用 weak 代理

### 30.2 及时释放资源

- 在 dealloc 中移除观察者
- 停止定时器
- 释放 Core Foundation 对象

### 30.3 合理使用缓存

- 使用 NSCache 代替 NSDictionary
- 设置缓存限制
- 及时清理缓存

### 30.4 优化图片使用

- 使用合适的图片格式和大小
- 及时释放大图片
- 使用图片缓存

