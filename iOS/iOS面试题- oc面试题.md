# iOS 面试题 - 常见的面试题（Objective-C）

本文档整理了 Objective-C 开发中最常见的面试题，涵盖了语言特性、内存管理、多线程、设计模式等多个方面。

---

## 一、语言基础

### 1. Objective-C 的类可以多重继承吗？可以实现多个接口吗？

**答案：**

- Objective-C 的类**不支持多重继承**，但可以通过实现多个**协议（Protocol）**来达到类似效果
- 协议类似于其他语言中的接口，一个类可以实现多个协议

**代码示例：**

```objc
// 定义协议
@protocol Flyable <NSObject>
- (void)fly;
@end

@protocol Swimmable <NSObject>
- (void)swim;
@end

// 实现多个协议
@interface Duck : NSObject <Flyable, Swimmable>
@end

@implementation Duck
- (void)fly {
    NSLog(@"Duck can fly");
}

- (void)swim {
    NSLog(@"Duck can swim");
}
@end
```

### 2. `#import` 与 `#include` 有什么区别？`@class` 的作用是什么？

**答案：**

- `#import` 是 Objective-C 中用于导入头文件的指令，**自动防止重复导入**，相当于 `#include` + `#pragma once`
- `#include` 是 C/C++ 的导入方式，可能会重复导入
- `@class` 用于**前向声明**，告诉编译器某个类的存在，通常用于解决头文件的相互包含问题
- `#import<>` 用于导入**系统头文件**，`#import""` 用于导入**用户自定义的头文件**

**代码示例：**

```objc
// 使用 @class 前向声明，避免循环引用
@class Person;

@interface Company : NSObject
@property (nonatomic, strong) Person *employee;
@end

// 在 .m 文件中再使用 #import
#import "Person.h"
```

### 3. `@property` 可以有哪些修饰符？

**答案：**

`@property` 的修饰符主要分为三类：

1. **内存管理修饰符**：`strong`、`weak`、`assign`、`copy`、`retain`（MRC）
2. **读写修饰符**：`readonly`、`readwrite`（默认）
3. **原子性修饰符**：`atomic`（默认）、`nonatomic`

**代码示例：**

```objc
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;        // 强引用，非原子
@property (nonatomic, weak) id<Delegate> delegate;   // 弱引用，避免循环引用
@property (nonatomic, copy) NSString *nickname;      // 复制，用于不可变对象
@property (nonatomic, assign) NSInteger age;         // 基本数据类型
@property (readonly) NSString *ID;                   // 只读属性
@end
```

### 4. `strong`、`weak`、`assign`、`copy` 的区别是什么？

**答案：**

| 修饰符 | 作用 | 引用计数 | 使用场景 |
|--------|------|----------|----------|
| `strong` | 强引用，持有对象 | +1 | 对象属性（默认） |
| `weak` | 弱引用，不持有对象 | 不变 | 避免循环引用，delegate |
| `assign` | 直接赋值 | 不变 | 基本数据类型（int、float等） |
| `copy` | 复制对象 | +1（对新对象） | NSString、NSArray 等不可变对象 |

**代码示例：**

```objc
// strong：强引用
@property (nonatomic, strong) NSArray *strongArray;

// weak：弱引用，对象释放后自动置为 nil
@property (nonatomic, weak) id<Delegate> delegate;

// assign：基本数据类型
@property (nonatomic, assign) NSInteger count;

// copy：复制对象，防止外部修改
@property (nonatomic, copy) NSString *name;

// 使用示例
NSMutableString *mutableStr = [NSMutableString stringWithString:@"Hello"];
person.name = mutableStr;  // copy 修饰，会创建新的不可变副本
[mutableStr appendString:@" World"];  // 不会影响 person.name
```

### 5. `atomic` 和 `nonatomic` 的区别是什么？

**答案：**

- **`atomic`**（默认）：
  - 保证属性的 **setter 和 getter 操作的原子性**
  - 在多线程环境下，保证读取或写入的完整性
  - **性能较低**，因为需要加锁
  - **注意**：`atomic` 不等于线程安全，只能保证单个操作的原子性

- **`nonatomic`**：
  - **不保证原子性**，不进行加锁
  - **性能更高**
  - 在多线程环境下可能出现数据不一致

**代码示例：**

```objc
// atomic：线程安全但性能低
@property (atomic, strong) NSString *atomicName;

// nonatomic：性能高但非线程安全
@property (nonatomic, strong) NSString *nonatomicName;

// atomic 的局限性
// 虽然单个操作是原子的，但组合操作仍然不安全
self.atomicName = @"A";  // 原子操作
self.atomicName = [self.atomicName stringByAppendingString:@"B"];  // 非原子操作
```

### 6. `__weak` 和 `__block` 的作用是什么？

**答案：**

- **`__weak`**：
  - 用于声明**弱引用**
  - 常用于避免 block 中的**循环引用**
  - 对象释放后自动置为 `nil`

- **`__block`**：
  - 允许在 block 内**修改外部变量的值**
  - 会将变量从栈复制到堆
  - 可以修改基本数据类型和对象

**代码示例：**

```objc
// __weak 避免循环引用
__weak typeof(self) weakSelf = self;
self.block = ^{
    [weakSelf doSomething];  // 使用弱引用，避免循环引用
};

// __block 允许修改外部变量
__block int count = 0;
void (^block)(void) = ^{
    count++;  // 可以修改外部变量
    NSLog(@"count = %d", count);
};
block();  // count = 1
```

### 7. `@synthesize` 和 `@dynamic` 的作用是什么？

**答案：**

- **`@synthesize`**：
  - 自动生成属性的 **getter 和 setter 方法**
  - 自动生成对应的实例变量（如 `_propertyName`）
  - 在 ARC 下，如果属性有对应的实例变量，编译器会自动添加 `@synthesize`

- **`@dynamic`**：
  - 告诉编译器**不要自动生成** getter 和 setter 方法
  - 方法会在**运行时提供**（如通过 KVC、Core Data 等）

**代码示例：**

```objc
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

@implementation Person
// @synthesize name = _name;  // ARC 下通常不需要，编译器自动添加

@dynamic age;  // 告诉编译器不要生成 age 的 getter/setter
// 需要手动实现或通过其他方式提供
- (NSInteger)age {
    // 从其他地方获取 age 值
    return [self getAgeFromDatabase];
}
@end
```

---

## 二、内存管理

### 8. Objective-C 的内存管理方式有哪些？MRC 与 ARC 的核心区别是什么？

**答案：**

Objective-C 支持两种内存管理方式：

1. **MRC（Manual Reference Counting）**：手动引用计数
   - 需要手动调用 `retain`、`release`、`autorelease`
   - 开发者需要管理对象的生命周期

2. **ARC（Automatic Reference Counting）**：自动引用计数
   - 编译器自动插入引用计数代码
   - 开发者无需手动管理内存

**核心区别：**

| 特性 | MRC | ARC |
|------|-----|-----|
| 内存管理 | 手动 | 自动 |
| retain/release | 需要手动调用 | 编译器自动插入 |
| 性能 | 相同 | 相同 |
| 代码量 | 多 | 少 |
| 错误率 | 高（容易内存泄漏） | 低 |

**代码示例：**

```objc
// MRC 方式
- (void)mrcExample {
    Person *person = [[Person alloc] init];  // retainCount = 1
    [person retain];  // retainCount = 2
    [person release];  // retainCount = 1
    [person release];  // retainCount = 0，对象被释放
}

// ARC 方式（自动管理）
- (void)arcExample {
    Person *person = [[Person alloc] init];  // 编译器自动管理
    // 方法结束时自动 release
}
```

### 9. `autorelease` 的作用是什么？`@autoreleasepool` 的作用是什么？

**答案：**

- **`autorelease`**：
  - 将对象添加到**自动释放池**中
  - 延迟释放对象，直到自动释放池被销毁
  - 通常在方法返回需要释放的对象时使用

- **`@autoreleasepool`**：
  - 创建一个**自动释放池**
  - 管理其中的自动释放对象
  - 可以**减少内存峰值**，及时释放对象

**代码示例：**

```objc
// autorelease 的使用
- (NSString *)createString {
    return [[[NSString alloc] initWithFormat:@"Hello"] autorelease];  // MRC
    // ARC 下不需要 autorelease，编译器自动处理
}

// @autoreleasepool 的使用
- (void)processLargeData {
    for (int i = 0; i < 10000; i++) {
        @autoreleasepool {
            // 大量临时对象在这里创建
            NSString *temp = [NSString stringWithFormat:@"Item %d", i];
            // 循环结束时，temp 会被释放，减少内存占用
        }
    }
}
```

### 10. 什么是循环引用？如何避免？

**答案：**

**循环引用**是指两个或多个对象相互强引用，导致无法释放，造成内存泄漏。

**常见场景：**

1. Block 中捕获 `self`
2. Delegate 使用 `strong` 修饰
3. 父子对象相互强引用

**避免方法：**

1. 使用 `__weak` 或 `__unsafe_unretained`
2. Delegate 使用 `weak` 修饰
3. Block 中使用 `weakSelf`

**代码示例：**

```objc
// 循环引用示例
@interface ViewController : UIViewController
@property (nonatomic, strong) void(^block)(void);
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // 错误：循环引用
    // self -> block -> self
    self.block = ^{
        [self doSomething];  // self 强引用 block，block 强引用 self
    };
    
    // 正确：使用 weak 打破循环
    __weak typeof(self) weakSelf = self;
    self.block = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;  // 临时强引用
        [strongSelf doSomething];
    };
}
@end
```

### 11. `weak` 修饰的对象被释放后，指针会变成什么？

**答案：**

`weak` 修饰的对象被释放后，指针会**自动置为 `nil`**，这是 `weak` 的重要特性，可以避免野指针。

**代码示例：**

```objc
__weak Person *weakPerson = nil;
@autoreleasepool {
    Person *person = [[Person alloc] init];
    weakPerson = person;
    NSLog(@"weakPerson: %@", weakPerson);  // 有值
}
// person 被释放
NSLog(@"weakPerson: %@", weakPerson);  // nil，自动置为 nil
```

---

## 三、Block

### 12. 什么是 Block？它和代理的区别是什么？

**答案：**

**Block** 是 Objective-C 中的**匿名函数**或**闭包**，允许将代码块作为参数传递。

**Block 与代理的区别：**

| 特性 | Block | 代理（Delegate） |
|------|-------|------------------|
| 语法 | 简洁，内联 | 需要协议定义 |
| 回调数量 | 适合单个回调 | 适合多个回调 |
| 代码位置 | 调用处附近 | 分散在不同方法 |
| 循环引用 | 容易产生 | 相对安全（weak） |
| 使用场景 | 简单回调、异步操作 | 复杂回调、多方法 |

**代码示例：**

```objc
// Block 方式
- (void)fetchDataWithCompletion:(void(^)(NSArray *data, NSError *error))completion {
    // 异步操作
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *data = @[@"1", @"2", @"3"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(data, nil);
            }
        });
    });
}

// 使用
[self fetchDataWithCompletion:^(NSArray *data, NSError *error) {
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSLog(@"Data: %@", data);
    }
}];

// 代理方式
@protocol DataFetcherDelegate <NSObject>
- (void)dataFetcher:(DataFetcher *)fetcher didReceiveData:(NSArray *)data;
- (void)dataFetcher:(DataFetcher *)fetcher didFailWithError:(NSError *)error;
@end
```

### 13. Block 的内存管理？

**答案：**

Block 有三种类型：

1. **`_NSConcreteGlobalBlock`**：全局 Block
   - 存储在全局区
   - 不捕获外部变量或只捕获静态变量

2. **`_NSConcreteStackBlock`**：栈 Block
   - 存储在栈上
   - 捕获了外部变量

3. **`_NSConcreteMallocBlock`**：堆 Block
   - 存储在堆上
   - Block 被 copy 后变成堆 Block

**代码示例：**

```objc
// 全局 Block（不捕获变量）
void (^globalBlock)(void) = ^{
    NSLog(@"Global Block");
};

// 栈 Block（捕获变量）
int value = 10;
void (^stackBlock)(void) = ^{
    NSLog(@"Value: %d", value);  // 捕获外部变量
};

// 堆 Block（被 copy）
void (^heapBlock)(void) = [stackBlock copy];
```

---

## 四、Category 和 Extension

### 14. Category 是什么？与继承相比，何时使用 Category 更合适？

**答案：**

**Category（分类）** 允许在不修改原始类的情况下，为现有类添加新的方法。

**Category 的特点：**

- 可以为已有类添加方法
- **不能添加实例变量**（但可以通过关联对象实现）
- 可以添加属性（但需要手动实现 getter/setter）
- 方法名冲突时，Category 的方法会覆盖原类方法

**使用场景：**

- 为系统类添加方法（如 NSString、NSArray）
- 将类的实现分散到多个文件
- 为第三方库的类添加功能

**代码示例：**

```objc
// 为 NSString 添加方法
@interface NSString (Custom)
- (BOOL)isValidEmail;
@end

@implementation NSString (Custom)
- (BOOL)isValidEmail {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}
@end

// 使用
NSString *email = @"test@example.com";
BOOL isValid = [email isValidEmail];
```

### 15. Category 和 Extension 的区别是什么？

**答案：**

| 特性 | Category | Extension |
|------|----------|-----------|
| 命名 | 有名称 | 匿名 |
| 实例变量 | 不能添加 | 可以添加 |
| 实现位置 | 独立的 .m 文件 | 必须在主类的 .m 文件中 |
| 可见性 | 公开 | 私有 |
| 使用场景 | 扩展功能 | 声明私有方法和属性 |

**代码示例：**

```objc
// Category（公开）
// Person+Work.h
@interface Person (Work)
- (void)work;
@end

// Extension（私有）
// Person.m
@interface Person ()
@property (nonatomic, strong) NSString *privateProperty;
- (void)privateMethod;
@end

@implementation Person
- (void)privateMethod {
    // 私有方法实现
}
@end
```

---

## 五、多线程

### 16. 在 Objective-C 中如何实现多线程？

**答案：**

Objective-C 中实现多线程的方式：

1. **NSThread**：轻量级线程
2. **GCD（Grand Central Dispatch）**：基于 C 的并发框架
3. **NSOperation/NSOperationQueue**：基于 GCD 的面向对象封装

**代码示例：**

```objc
// 1. NSThread
NSThread *thread = [[NSThread alloc] initWithTarget:self 
                                            selector:@selector(doWork) 
                                              object:nil];
[thread start];

// 2. GCD
// 串行队列
dispatch_queue_t serialQueue = dispatch_queue_create("com.example.serial", DISPATCH_QUEUE_SERIAL);
dispatch_async(serialQueue, ^{
    // 执行任务
});

// 并发队列
dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_async(concurrentQueue, ^{
    // 执行任务
});

// 主队列
dispatch_async(dispatch_get_main_queue(), ^{
    // 更新 UI
});

// 3. NSOperation
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    // 执行任务
}];
[queue addOperation:operation];
```

### 17. `NSOperation` 和 `GCD` 的区别是什么？

**答案：**

| 特性 | GCD | NSOperation |
|------|-----|-------------|
| 语言 | C API | Objective-C 对象 |
| 取消操作 | 不支持 | 支持 |
| 依赖关系 | 不支持 | 支持 |
| 优先级 | 支持 | 支持 |
| 监听完成 | 使用 Block | 使用 completionBlock |
| 使用场景 | 简单任务 | 复杂任务 |

**代码示例：**

```objc
// GCD
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    // 任务
    dispatch_async(dispatch_get_main_queue(), ^{
        // 完成回调
    });
});

// NSOperation（支持依赖和取消）
NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"Operation 1");
}];

NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"Operation 2");
}];

[op2 addDependency:op1];  // op2 依赖 op1

NSOperationQueue *queue = [[NSOperationQueue alloc] init];
[queue addOperation:op1];
[queue addOperation:op2];
```

### 18. 如何在 Objective-C 中实现线程安全？

**答案：**

实现线程安全的方法：

1. **`@synchronized`**：互斥锁
2. **`NSLock`**：锁对象
3. **GCD 串行队列**：串行访问
4. **`dispatch_barrier_async`**：栅栏函数
5. **`atomic` 属性**：原子操作

**代码示例：**

```objc
// 1. @synchronized
- (void)threadSafeMethod {
    @synchronized(self) {
        // 临界区代码
        self.count++;
    }
}

// 2. NSLock
@property (nonatomic, strong) NSLock *lock;

- (void)threadSafeMethod2 {
    [self.lock lock];
    // 临界区代码
    self.count++;
    [self.lock unlock];
}

// 3. GCD 串行队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;

- (instancetype)init {
    if (self = [super init]) {
        _serialQueue = dispatch_queue_create("com.example.serial", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)threadSafeMethod3 {
    dispatch_async(self.serialQueue, ^{
        // 临界区代码
        self.count++;
    });
}

// 4. dispatch_barrier_async（读写锁）
- (void)readData {
    dispatch_async(self.concurrentQueue, ^{
        // 读操作
    });
}

- (void)writeData {
    dispatch_barrier_async(self.concurrentQueue, ^{
        // 写操作（独占）
    });
}
```

---

## 六、RunLoop

### 19. 什么是 RunLoop？它与线程有什么关系？

**答案：**

**RunLoop** 是事件处理循环，负责监听和处理事件（如触摸事件、定时器、网络事件等）。

**RunLoop 与线程的关系：**

- 每个线程都有一个对应的 RunLoop
- **主线程的 RunLoop 默认启动**
- 子线程的 RunLoop 需要**手动启动**
- RunLoop 使线程在有任务时工作，无任务时休眠

**代码示例：**

```objc
// 获取当前线程的 RunLoop
NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

// 在子线程中启动 RunLoop
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [runLoop run];  // 启动 RunLoop
});
```

### 20. RunLoop 的作用是什么？

**答案：**

RunLoop 的主要作用：

1. **保持程序持续运行**：主线程的 RunLoop 保证程序不会退出
2. **处理各种事件**：触摸事件、定时器、网络事件等
3. **节省 CPU 资源**：线程在没有事件时休眠
4. **线程间通信**：通过 Port 进行线程间通信

---

## 七、KVO 和 KVC

### 21. 什么是 KVO？它的实现原理是什么？

**答案：**

**KVO（Key-Value Observing）** 是键值观察机制，允许对象监听另一个对象属性的变化。

**实现原理：**

1. 当对象被观察时，Runtime 会动态创建一个**子类**
2. 重写被观察属性的 setter 方法
3. 在 setter 方法中调用 `willChangeValueForKey:` 和 `didChangeValueForKey:`
4. 通知观察者

**代码示例：**

```objc
// 观察者
@interface Observer : NSObject
@end

@implementation Observer
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    NSLog(@"%@ changed: %@", keyPath, change);
}
@end

// 被观察者
Person *person = [[Person alloc] init];
Observer *observer = [[Observer alloc] init];

[person addObserver:observer 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
            context:nil];

person.name = @"New Name";  // 触发 KVO

[person removeObserver:observer forKeyPath:@"name"];
```

### 22. 什么是 KVC？它的实现原理是什么？

**答案：**

**KVC（Key-Value Coding）** 是键值编码，提供了一种通过字符串键名间接访问对象属性的机制。

**访问顺序：**

1. 查找 `set<Key>:` 或 `_set<Key>:` 方法
2. 如果没找到，查找 `_key`、`_isKey`、`key`、`isKey` 实例变量
3. 如果都没找到，调用 `setValue:forUndefinedKey:`

**代码示例：**

```objc
Person *person = [[Person alloc] init];

// 使用 KVC 设置值
[person setValue:@"John" forKey:@"name"];
[person setValue:@25 forKey:@"age"];

// 使用 KVC 获取值
NSString *name = [person valueForKey:@"name"];
NSNumber *age = [person valueForKey:@"age"];

// 键路径
[person setValue:@"Engineer" forKeyPath:@"job.title"];
```

---

## 八、设计模式

### 23. 如何在 Objective-C 中实现单例模式？

**答案：**

单例模式确保一个类只有一个实例，并提供一个全局访问点。

**实现方式：**

使用 `dispatch_once` 确保线程安全。

**代码示例：**

```objc
// .h 文件
@interface Singleton : NSObject
+ (instancetype)sharedInstance;
@end

// .m 文件
@implementation Singleton

+ (instancetype)sharedInstance {
    static Singleton *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// 防止通过 alloc 创建实例
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

// 防止通过 copy 创建实例
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
```

### 24. 什么是代理模式？如何使用？

**答案：**

**代理模式**是一种设计模式，允许一个对象代表另一个对象处理某些操作。

**使用步骤：**

1. 定义协议
2. 声明代理属性（使用 `weak`）
3. 在需要时调用代理方法

**代码示例：**

```objc
// 定义协议
@protocol DownloadDelegate <NSObject>
- (void)downloadDidFinish:(NSData *)data;
- (void)downloadDidFail:(NSError *)error;
@end

// 使用代理的类
@interface Downloader : NSObject
@property (nonatomic, weak) id<DownloadDelegate> delegate;
- (void)startDownload;
@end

@implementation Downloader
- (void)startDownload {
    // 下载完成
    if ([self.delegate respondsToSelector:@selector(downloadDidFinish:)]) {
        [self.delegate downloadDidFinish:data];
    }
}
@end

// 实现代理
@interface ViewController : UIViewController <DownloadDelegate>
@end

@implementation ViewController
- (void)viewDidLoad {
    Downloader *downloader = [[Downloader alloc] init];
    downloader.delegate = self;
}

- (void)downloadDidFinish:(NSData *)data {
    // 处理下载完成
}
@end
```

### 25. 什么是观察者模式？NSNotificationCenter 如何使用？

**答案：**

**观察者模式**定义了一种一对多的依赖关系，当一个对象的状态发生改变时，所有依赖于它的对象都得到通知。

**NSNotificationCenter** 是 iOS 中实现观察者模式的机制。

**代码示例：**

```objc
// 发送通知
[[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated" 
                                                    object:self 
                                                  userInfo:@{@"data": data}];

// 注册观察者
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(handleNotification:) 
                                             name:@"DataUpdated" 
                                           object:nil];

// 处理通知
- (void)handleNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    // 处理通知
}

// 移除观察者
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

---

## 九、Runtime

### 26. 什么是 Runtime？它的作用是什么？

**答案：**

**Runtime** 是 Objective-C 的运行时系统，是 Objective-C 语言的核心。

**主要作用：**

1. 动态创建类和对象
2. 动态添加方法和属性
3. 消息转发机制
4. 方法交换（Method Swizzling）
5. 关联对象（Associated Objects）

### 27. Objective-C 的消息机制是什么？

**答案：**

Objective-C 的方法调用实际上是**消息发送**。

**消息发送流程：**

1. 在类的**缓存**中查找方法
2. 在当前类的**方法列表**中查找
3. 在**父类**的方法列表中查找
4. 如果找不到，进入**消息转发流程**

**代码示例：**

```objc
// 方法调用
[person sayHello];

// 编译后转换为
objc_msgSend(person, @selector(sayHello));

// 消息转发流程
// 1. 动态方法解析
+ (BOOL)resolveInstanceMethod:(SEL)sel;

// 2. 备用接收者
- (id)forwardingTargetForSelector:(SEL)aSelector;

// 3. 完整转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void)forwardInvocation:(NSInvocation *)anInvocation;
```

### 28. 什么是 `isa` 指针？它的作用是什么？

**答案：**

`isa` 指针是每个对象的隐藏成员变量，指向该对象的**类对象**。

**指向关系：**

```
实例对象 -> 类对象 -> 元类 -> 根元类 -> 根元类（指向自己）
```

**作用：**

- 对象通过 `isa` 找到类对象
- 类对象通过 `isa` 找到元类
- 用于方法查找和消息发送

---

## 十、其他常见问题

### 29. `NSCache` 和 `NSDictionary` 的区别是什么？

**答案：**

| 特性 | NSCache | NSDictionary |
|------|---------|--------------|
| 线程安全 | 是 | 否 |
| 自动清理 | 内存不足时自动清理 | 不会自动清理 |
| Key 类型 | 必须实现 NSCopying | 必须实现 NSCopying |
| 使用场景 | 缓存临时数据 | 存储持久数据 |

**代码示例：**

```objc
NSCache *cache = [[NSCache alloc] init];
cache.countLimit = 100;  // 限制数量
cache.totalCostLimit = 50 * 1024 * 1024;  // 限制总成本（50MB）

[cache setObject:image forKey:@"image1" cost:imageData.length];
UIImage *cachedImage = [cache objectForKey:@"image1"];
```

### 30. `@synchronized` 的作用是什么？

**答案：**

`@synchronized` 提供**互斥锁**，确保代码块在多线程环境下的线程安全。

**代码示例：**

```objc
- (void)threadSafeMethod {
    @synchronized(self) {
        // 临界区代码，同一时间只有一个线程可以执行
        self.count++;
    }
}

// 等价于
- (void)threadSafeMethod2 {
    NSLock *lock = [[NSLock alloc] init];
    [lock lock];
    self.count++;
    [lock unlock];
}
```

### 31. 如何检测内存泄漏？

**答案：**

检测内存泄漏的方法：

1. **Instruments - Leaks**：Xcode 自带的工具
2. **静态分析**：Product -> Analyze
3. **MLeaksFinder**：第三方工具
4. **手动检查**：检查循环引用、delegate 是否使用 weak

### 32. 如何优化 App 启动速度？

**答案：**

优化启动速度的方法：

1. **减少启动时的任务**：延迟非必要初始化
2. **使用 `@autoreleasepool`**：及时释放临时对象
3. **优化 `+load` 方法**：减少启动时的加载
4. **使用 `dispatch_async`**：异步执行非关键任务
5. **减少动态库加载**：合并动态库

### 33. 如何优化 TableView 的滚动性能？

**答案：**

优化 TableView 性能的方法：

1. **Cell 复用**：使用 `dequeueReusableCellWithIdentifier:`
2. **减少视图层级**：简化 Cell 结构
3. **异步加载图片**：使用 SDWebImage 等
4. **减少主线程任务**：将计算移到后台线程
5. **使用 `estimatedRowHeight`**：提高滚动流畅度
6. **避免在 `cellForRowAtIndexPath` 中做耗时操作**

### 34. `id` 和 `instancetype` 的区别是什么？

**答案：**

| 特性 | id | instancetype |
|------|----|--------------|
| 类型检查 | 编译时不检查 | 编译时检查 |
| 返回值 | 可以是任何类型 | 必须是当前类或其子类 |
| 使用场景 | 动态类型 | 工厂方法、初始化方法 |

**代码示例：**

```objc
// id：动态类型，编译时不检查
- (id)createObject {
    return [[NSArray alloc] init];  // 编译通过
}

// instancetype：编译时检查类型
- (instancetype)createObject {
    return [[NSArray alloc] init];  // 编译警告
}
```

### 35. `NSArray` 和 `NSMutableArray` 的区别是什么？

**答案：**

| 特性 | NSArray | NSMutableArray |
|------|---------|----------------|
| 可变性 | 不可变 | 可变 |
| 性能 | 更高 | 较低 |
| 线程安全 | 是（不可变） | 否 |
| 使用场景 | 不需要修改的数组 | 需要修改的数组 |

**代码示例：**

```objc
// NSArray：不可变
NSArray *array = @[@"1", @"2", @"3"];
// array[0] = @"4";  // 编译错误

// NSMutableArray：可变
NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:array];
[mutableArray addObject:@"4"];
[mutableArray removeObjectAtIndex:0];
```

---

## 十一、实际编程题

### 36. 实现一个线程安全的单例

```objc
@interface ThreadSafeSingleton : NSObject
+ (instancetype)sharedInstance;
@end

@implementation ThreadSafeSingleton

+ (instancetype)sharedInstance {
    static ThreadSafeSingleton *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
```

### 37. 实现一个简单的 KVO

```objc
// 使用 Runtime 实现简单的 KVO
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    // 1. 动态创建子类
    NSString *className = NSStringFromClass([self class]);
    NSString *kvoClassName = [@"NSKVO_" stringByAppendingString:className];
    
    Class kvoClass = objc_allocateClassPair([self class], [kvoClassName UTF8String], 0);
    
    // 2. 重写 setter 方法
    SEL setterSelector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", 
                                               [keyPath capitalizedString]]);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    const char *types = method_getTypeEncoding(setterMethod);
    
    class_addMethod(kvoClass, setterSelector, (IMP)kvo_setter, types);
    
    // 3. 注册类
    objc_registerClassPair(kvoClass);
    
    // 4. 修改 isa 指针
    object_setClass(self, kvoClass);
}
```

### 38. 实现一个简单的 Block 回调

```objc
typedef void(^CompletionBlock)(BOOL success, NSError *error);

@interface NetworkManager : NSObject
- (void)fetchDataWithURL:(NSString *)url completion:(CompletionBlock)completion;
@end

@implementation NetworkManager
- (void)fetchDataWithURL:(NSString *)url completion:(CompletionBlock)completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 模拟网络请求
        sleep(2);
        
        BOOL success = YES;
        NSError *error = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    });
}
@end
```

---

## 十二、总结

本文档涵盖了 Objective-C 开发中最常见的面试题，包括：

- **语言基础**：属性修饰符、内存管理、Block 等
- **内存管理**：ARC、MRC、循环引用等
- **多线程**：GCD、NSOperation、线程安全等
- **Runtime**：消息机制、动态特性等
- **设计模式**：单例、代理、观察者等
- **实际编程**：常见编程题和实现

建议在面试前：

1. 深入理解每个概念的原理
2. 多写代码实践
3. 关注最新的 iOS 开发趋势
4. 准备实际项目经验

---

**最后更新：2024年**

