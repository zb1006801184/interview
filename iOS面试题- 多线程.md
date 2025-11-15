# iOS 面试题 - 多线程

## 1. 什么是多线程？

多线程是指在一个进程中同时执行多个线程，每个线程可以独立执行不同的任务。在 iOS 开发中，多线程主要用于：
- 避免阻塞主线程，保持 UI 响应
- 提高程序执行效率
- 实现并发处理

## 2. iOS 中的多线程方案有哪些？

### 2.1 主要方案

1. **NSThread**：轻量级线程，需要手动管理
2. **GCD（Grand Central Dispatch）**：C 语言 API，推荐使用
3. **NSOperation/NSOperationQueue**：基于 GCD 的面向对象封装
4. **pthread**：POSIX 线程，C 语言 API

### 2.2 对比

| 特性 | NSThread | GCD | NSOperation |
|------|----------|-----|-------------|
| 抽象层次 | 低 | 中 | 高 |
| 使用难度 | 中 | 低 | 中 |
| 功能 | 基础 | 丰富 | 丰富 |
| 取消任务 | 困难 | 不支持 | 支持 |
| 依赖关系 | 不支持 | 不支持 | 支持 |
| 优先级 | 支持 | 支持 | 支持 |

## 3. 什么是 GCD？

GCD（Grand Central Dispatch）是苹果提供的多线程编程解决方案，基于 C 语言 API。

### 3.1 核心概念

- **队列（Queue）**：任务执行的容器
- **任务（Task）**：需要执行的代码块
- **同步/异步**：任务的执行方式

### 3.2 基本用法

```objc
// 异步执行
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 后台任务
    dispatch_async(dispatch_get_main_queue(), ^{
        // 回到主线程更新 UI
    });
});
```

## 4. GCD 的队列类型？

### 4.1 串行队列（Serial Queue）

串行队列中的任务按顺序执行，同一时间只执行一个任务。

```objc
// 创建串行队列
dispatch_queue_t serialQueue = dispatch_queue_create("com.example.serial", DISPATCH_QUEUE_SERIAL);

// 执行任务
dispatch_async(serialQueue, ^{
    NSLog(@"任务1");
});
dispatch_async(serialQueue, ^{
    NSLog(@"任务2");
});
// 输出：任务1 -> 任务2（顺序执行）
```

### 4.2 并发队列（Concurrent Queue）

并发队列中的任务可以并发执行，同一时间可以执行多个任务。

```objc
// 创建并发队列
dispatch_queue_t concurrentQueue = dispatch_queue_create("com.example.concurrent", DISPATCH_QUEUE_CONCURRENT);

// 执行任务
dispatch_async(concurrentQueue, ^{
    NSLog(@"任务1");
});
dispatch_async(concurrentQueue, ^{
    NSLog(@"任务2");
});
// 输出：任务1 和 任务2 可能同时执行
```

### 4.3 主队列（Main Queue）

主队列是串行队列，所有任务在主线程执行。

```objc
dispatch_async(dispatch_get_main_queue(), ^{
    // 在主线程执行
});
```

### 4.4 全局队列（Global Queue）

全局队列是系统提供的并发队列，有不同优先级。

```objc
// 优先级从高到低
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
```

## 5. 同步和异步的区别？

### 5.1 同步（sync）

同步执行会阻塞当前线程，等待任务完成。

```objc
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog(@"同步任务");
});
NSLog(@"同步任务完成后执行");
// 输出：同步任务 -> 同步任务完成后执行
```

### 5.2 异步（async）

异步执行不会阻塞当前线程，立即返回。

```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog(@"异步任务");
});
NSLog(@"立即执行");
// 输出：立即执行 -> 异步任务（顺序可能不同）
```

### 5.3 死锁问题

```objc
// 死锁：在主队列同步执行任务
dispatch_sync(dispatch_get_main_queue(), ^{
    NSLog(@"死锁");
});
// 主线程被阻塞，等待主队列执行任务，但主队列需要主线程空闲才能执行
```

## 6. 什么是 dispatch_group？

dispatch_group 用于管理一组任务的执行，可以等待所有任务完成。

### 6.1 基本用法

```objc
dispatch_group_t group = dispatch_group_create();
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

// 添加任务到组
dispatch_group_async(group, queue, ^{
    NSLog(@"任务1");
});

dispatch_group_async(group, queue, ^{
    NSLog(@"任务2");
});

// 等待所有任务完成
dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSLog(@"所有任务完成");
});
```

### 6.2 手动管理

```objc
dispatch_group_t group = dispatch_group_create();
dispatch_group_enter(group);
dispatch_async(queue, ^{
    // 任务
    dispatch_group_leave(group);
});

dispatch_group_wait(group, DISPATCH_TIME_FOREVER); // 阻塞等待
```

## 7. 什么是 dispatch_barrier？

dispatch_barrier 用于在并发队列中创建同步点，确保 barrier 之前的任务都完成后，才执行 barrier 任务。

### 7.1 基本用法

```objc
dispatch_queue_t queue = dispatch_queue_create("com.example.concurrent", DISPATCH_QUEUE_CONCURRENT);

dispatch_async(queue, ^{ NSLog(@"任务1"); });
dispatch_async(queue, ^{ NSLog(@"任务2"); });

dispatch_barrier_async(queue, ^{
    NSLog(@"Barrier 任务");
});

dispatch_async(queue, ^{ NSLog(@"任务3"); });
dispatch_async(queue, ^{ NSLog(@"任务4"); });

// 输出：任务1、任务2 并发执行 -> Barrier 任务 -> 任务3、任务4 并发执行
```

### 7.2 应用场景

- 读写锁的实现
- 确保某些任务在其他任务完成后执行

## 8. 什么是 dispatch_semaphore？

dispatch_semaphore 是信号量，用于控制并发数量。

### 8.1 基本用法

```objc
// 创建信号量，初始值为 2
dispatch_semaphore_t semaphore = dispatch_semaphore_create(2);

dispatch_async(queue, ^{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); // 信号量 -1
    // 执行任务
    dispatch_semaphore_signal(semaphore); // 信号量 +1
});
```

### 8.2 应用场景

- 限制并发数量
- 实现同步机制

## 9. 什么是 dispatch_once？

dispatch_once 确保代码只执行一次，常用于单例模式。

### 9.1 基本用法

```objc
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
```

### 9.2 特点

- 线程安全
- 性能优于 @synchronized
- 只执行一次

## 10. 什么是 dispatch_after？

dispatch_after 用于延迟执行任务。

### 10.1 基本用法

```objc
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    NSLog(@"2秒后执行");
});
```

### 10.2 注意事项

- 不是精确的定时器
- 只是将任务添加到队列，不保证精确时间

## 11. 什么是 NSOperation？

NSOperation 是基于 GCD 的面向对象封装，提供了更多功能。

### 11.1 基本用法

```objc
NSOperationQueue *queue = [[NSOperationQueue alloc] init];

NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"执行任务");
}];

[queue addOperation:operation];
```

### 11.2 子类化

```objc
@interface CustomOperation : NSOperation
@end

@implementation CustomOperation
- (void)main {
    // 执行任务
    if (self.isCancelled) {
        return;
    }
    // 任务逻辑
}
@end
```

## 12. NSOperation 的特点？

### 12.1 优势

- **取消任务**：可以取消未执行的任务
- **依赖关系**：可以设置任务之间的依赖
- **优先级**：可以设置任务优先级
- **完成回调**：可以设置完成回调

### 12.2 代码示例

```objc
NSOperationQueue *queue = [[NSOperationQueue alloc] init];

NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"任务1");
}];

NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
    NSLog(@"任务2");
}];

// 设置依赖：operation2 依赖 operation1
[operation2 addDependency:operation1];

// 设置优先级
operation1.queuePriority = NSOperationQueuePriorityHigh;

// 设置完成回调
operation1.completionBlock = ^{
    NSLog(@"任务1完成");
};

[queue addOperation:operation1];
[queue addOperation:operation2];
```

## 13. NSOperationQueue 的配置？

### 13.1 最大并发数

```objc
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 3; // 最多3个并发任务
```

### 13.2 暂停和恢复

```objc
queue.suspended = YES;  // 暂停
queue.suspended = NO;   // 恢复
```

### 13.3 取消所有任务

```objc
[queue cancelAllOperations];
```

## 14. 什么是线程安全？

线程安全是指多线程环境下，共享资源能够被正确访问，不会出现数据竞争。

### 14.1 线程不安全示例

```objc
@property (nonatomic, assign) NSInteger count;

// 多线程访问
dispatch_async(queue1, ^{
    for (int i = 0; i < 1000; i++) {
        self.count++; // 线程不安全
    }
});

dispatch_async(queue2, ^{
    for (int i = 0; i < 1000; i++) {
        self.count++; // 线程不安全
    }
});
// 最终 count 可能不是 2000
```

### 14.2 解决方案

使用锁机制保护共享资源。

## 15. iOS 中的锁机制？

### 15.1 @synchronized

```objc
@synchronized(self) {
    self.count++;
}
```

### 15.2 NSLock

```objc
NSLock *lock = [[NSLock alloc] init];
[lock lock];
self.count++;
[lock unlock];
```

### 15.3 NSRecursiveLock

递归锁，允许同一线程多次加锁。

```objc
NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
[lock lock];
// 可以再次加锁
[lock lock];
[lock unlock];
[lock unlock];
```

### 15.4 NSCondition

条件锁，可以等待条件满足。

```objc
NSCondition *condition = [[NSCondition alloc] init];
[condition lock];
while (!ready) {
    [condition wait];
}
[condition unlock];
```

### 15.5 dispatch_semaphore

使用信号量实现锁。

```objc
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
self.count++;
dispatch_semaphore_signal(semaphore);
```

### 15.6 pthread_mutex

POSIX 互斥锁。

```objc
pthread_mutex_t mutex;
pthread_mutex_init(&mutex, NULL);
pthread_mutex_lock(&mutex);
self.count++;
pthread_mutex_unlock(&mutex);
pthread_mutex_destroy(&mutex);
```

### 15.7 OSSpinLock（已废弃）

自旋锁，iOS 10+ 已废弃，使用 os_unfair_lock 代替。

```objc
os_unfair_lock_t unfairLock = &(os_unfair_lock_t){OS_UNFAIR_LOCK_INIT};
os_unfair_lock_lock(unfairLock);
self.count++;
os_unfair_lock_unlock(unfairLock);
```

## 16. 锁的性能对比？

| 锁类型 | 性能 | 特点 |
|--------|------|------|
| OSSpinLock | 最快 | 已废弃，可能优先级反转 |
| os_unfair_lock | 快 | iOS 10+，替代 OSSpinLock |
| pthread_mutex | 快 | 跨平台 |
| dispatch_semaphore | 快 | GCD 提供 |
| NSLock | 中 | 封装 pthread_mutex |
| @synchronized | 慢 | 使用方便，性能较差 |

## 17. 什么是读写锁？

读写锁允许多个读操作并发，但写操作需要独占。

### 17.1 使用 dispatch_barrier 实现

```objc
dispatch_queue_t queue = dispatch_queue_create("com.example.rw", DISPATCH_QUEUE_CONCURRENT);

// 读操作
- (id)read {
    __block id result;
    dispatch_sync(queue, ^{
        result = self.data;
    });
    return result;
}

// 写操作
- (void)write:(id)data {
    dispatch_barrier_async(queue, ^{
        self.data = data;
    });
}
```

## 18. 什么是线程同步？

线程同步是指协调多个线程的执行顺序，确保数据一致性。

### 18.1 同步方法

- 使用锁
- 使用信号量
- 使用 dispatch_group
- 使用 NSOperation 的依赖关系

## 19. 主线程和子线程的区别？

### 19.1 主线程

- UI 操作必须在主线程
- 主线程阻塞会导致界面卡顿
- 主线程有 RunLoop

### 19.2 子线程

- 可以执行耗时操作
- 不能直接更新 UI
- 默认没有 RunLoop（需要手动创建）

### 19.3 更新 UI

```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 后台任务
    dispatch_async(dispatch_get_main_queue(), ^{
        // 回到主线程更新 UI
        self.label.text = @"更新";
    });
});
```

## 20. 什么是线程池？

线程池是预先创建一定数量的线程，用于执行任务，避免频繁创建和销毁线程。

### 20.1 GCD 的线程池

GCD 内部维护线程池，自动管理线程的创建和销毁。

### 20.2 NSOperationQueue 的线程池

NSOperationQueue 内部使用 GCD，也维护线程池。

## 21. 如何避免线程死锁？

### 21.1 死锁原因

- 多个锁相互等待
- 在同一队列同步执行任务

### 21.2 避免方法

- 避免嵌套锁
- 统一锁的顺序
- 避免在主队列同步执行任务
- 使用超时机制

## 22. 什么是线程优先级反转？

线程优先级反转是指低优先级线程持有高优先级线程需要的锁，导致高优先级线程被阻塞。

### 22.1 解决方案

- 使用优先级继承
- 避免设置线程优先级
- 使用公平锁

## 23. 如何实现线程安全的单例？

### 23.1 使用 dispatch_once

```objc
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
```

### 23.2 使用 @synchronized

```objc
+ (instancetype)sharedInstance {
    static id instance = nil;
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}
```

## 24. 如何实现线程安全的数组？

### 24.1 使用锁

```objc
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) NSLock *lock;

- (void)addObject:(id)object {
    [self.lock lock];
    [self.array addObject:object];
    [self.lock unlock];
}
```

### 24.2 使用串行队列

```objc
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) dispatch_queue_t queue;

- (instancetype)init {
    if (self = [super init]) {
        _array = [NSMutableArray array];
        _queue = dispatch_queue_create("com.example.safe", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addObject:(id)object {
    dispatch_async(self.queue, ^{
        [self.array addObject:object];
    });
}
```

## 25. 什么是原子操作？

原子操作是不可分割的操作，要么全部执行，要么全部不执行。

### 25.1 atomic 属性

```objc
@property (atomic, strong) NSString *name;
```

atomic 只能保证 setter/getter 的原子性，不能保证整个操作的原子性。

### 25.2 真正的原子操作

使用 OSAtomic 或 std::atomic（C++）。

## 26. 如何检测线程问题？

### 26.1 使用 Thread Sanitizer

在 Xcode 的 Scheme 中启用 Thread Sanitizer，可以检测数据竞争。

### 26.2 使用 Instruments

使用 Time Profiler 分析线程使用情况。

## 27. 多线程的常见面试题总结

1. **iOS 中的多线程方案？** - NSThread、GCD、NSOperation
2. **GCD 的队列类型？** - 串行、并发、主队列、全局队列
3. **同步和异步的区别？** - 是否阻塞当前线程
4. **什么是 dispatch_group？** - 管理一组任务
5. **什么是 dispatch_barrier？** - 创建同步点
6. **什么是 dispatch_semaphore？** - 信号量，控制并发
7. **NSOperation 的特点？** - 取消、依赖、优先级
8. **什么是线程安全？** - 多线程环境下正确访问共享资源
9. **iOS 中的锁机制？** - @synchronized、NSLock、pthread_mutex 等
10. **如何避免死锁？** - 避免嵌套锁、统一锁顺序
11. **主线程和子线程的区别？** - UI 操作、RunLoop
12. **如何实现线程安全的单例？** - dispatch_once
13. **atomic 和 nonatomic 的区别？** - 原子性保证

## 28. 多线程的最佳实践

### 28.1 避免阻塞主线程

- 耗时操作放在后台线程
- 使用异步方法
- 及时回到主线程更新 UI

### 28.2 合理使用锁

- 尽量减少锁的粒度
- 避免嵌套锁
- 使用合适的锁类型

### 28.3 避免过度线程化

- 不要创建过多线程
- 使用 GCD 的线程池
- 合理设置并发数

### 28.4 注意内存管理

- 避免循环引用
- 及时释放资源
- 注意线程安全

