# iOS 面试题 - RunLoop

## 1. 什么是 RunLoop？

RunLoop 是 iOS 开发中一个重要的概念，它是一个事件处理循环，用于管理和调度线程上的任务。RunLoop 可以让线程在没有任务时进入休眠状态，在有任务时被唤醒执行任务，从而避免线程空转浪费 CPU 资源。

## 2. RunLoop 的作用是什么？

- **保持程序持续运行**：主线程的 RunLoop 在程序启动后就会一直运行，保证程序不会退出
- **处理各种事件**：处理触摸事件、定时器事件、网络事件等
- **节省 CPU 资源**：当没有事件需要处理时，让线程进入休眠状态，有事件时再唤醒
- **线程保活**：可以让子线程保持活跃状态，等待任务执行

## 3. RunLoop 与线程的关系？

- **一一对应关系**：每个线程都有且仅有一个 RunLoop（通过 `[NSRunLoop currentRunLoop]` 获取）
- **主线程 RunLoop**：主线程的 RunLoop 在程序启动时自动创建并运行
- **子线程 RunLoop**：子线程的 RunLoop 默认不创建，需要手动获取才会创建（懒加载）
- **线程销毁**：线程销毁时，对应的 RunLoop 也会被销毁

## 4. RunLoop 的几种模式（Mode）？

### 4.1 常见的 Mode

- **NSDefaultRunLoopMode（kCFRunLoopDefaultMode）**：默认模式，大多数情况下使用
- **UITrackingRunLoopMode**：界面跟踪模式，用于 ScrollView 滑动时
- **NSRunLoopCommonModes（kCFRunLoopCommonModes）**：占位模式，包含 Default 和 Tracking 模式
- **UIInitializationRunLoopMode**：应用启动时的模式
- **GSEventReceiveRunLoopMode**：接收系统事件的模式

### 4.2 Mode 的作用

RunLoop 在同一时间只能运行在一个 Mode 下，切换 Mode 时需要退出当前 Mode，再进入新的 Mode。这样可以隔离不同场景下的 Source/Timer/Observer，避免相互影响。

## 5. RunLoop 的内部结构？

RunLoop 主要包含以下几个部分：

- **Source0**：需要手动触发的源（如触摸事件、performSelector:onThread:）
- **Source1**：基于 mach_port 的源，由系统内核触发（如屏幕点击事件）
- **Timer**：定时器源（NSTimer、CADisplayLink）
- **Observer**：观察者，用于监听 RunLoop 的状态变化

## 6. RunLoop 的运行流程？

```
1. 通知 Observer：即将进入 RunLoop
2. 通知 Observer：即将处理 Timer
3. 通知 Observer：即将处理 Source0
4. 处理 Source0
5. 如果有 Source1，跳转到第 9 步
6. 通知 Observer：线程即将休眠
7. 线程休眠，等待被唤醒（Source1、Timer、外部手动唤醒）
8. 通知 Observer：线程刚被唤醒
9. 处理唤醒时收到的事件
   - 如果是 Timer，处理 Timer 回调
   - 如果是 Source1，处理 Source1
   - 如果是被手动唤醒，处理 Source0
10. 根据结果决定是否继续循环
11. 通知 Observer：即将退出 RunLoop
```

## 7. 为什么 NSTimer 在滑动时失效？

当 ScrollView 滑动时，RunLoop 会切换到 `UITrackingRunLoopMode` 模式，而 NSTimer 默认添加到 `NSDefaultRunLoopMode` 模式。由于 RunLoop 同一时间只能运行在一个 Mode 下，所以 Timer 在滑动时不会被触发。

**解决方案**：
- 将 Timer 添加到 `NSRunLoopCommonModes` 中
- 使用 GCD 定时器（dispatch_source_t）

```objc
// 方式1：添加到 CommonModes
NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

// 方式2：使用 GCD 定时器
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
dispatch_source_set_event_handler(timer, ^{
    // 定时器回调
});
dispatch_resume(timer);
```

## 8. RunLoop 的应用场景？

### 8.1 线程保活

```objc
// 子线程保活
- (void)keepThreadAlive {
    self.thread = [[NSThread alloc] initWithBlock:^{
        @autoreleasepool {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            // 添加 Port 或 Timer，防止 RunLoop 退出
            [runLoop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
            [runLoop run];
        }
    }];
    [self.thread start];
}
```

### 8.2 延迟执行

```objc
// 使用 performSelector:withObject:afterDelay: 实现延迟执行
[self performSelector:@selector(doSomething) withObject:nil afterDelay:2.0 inModes:@[NSDefaultRunLoopMode]];
```

### 8.3 监控卡顿

通过添加 Observer 监听 RunLoop 的状态变化，计算每个状态之间的耗时，如果超过阈值则认为发生了卡顿。

#### 8.3.1 监控原理

主线程的 RunLoop 负责处理 UI 事件和界面更新。正常情况下，RunLoop 会在一个循环中快速处理事件并进入休眠状态。如果某个阶段耗时过长，说明主线程被阻塞，发生了卡顿。

**关键监控点：**
- `kCFRunLoopBeforeSources` → `kCFRunLoopBeforeWaiting`：处理 Source 的耗时
- `kCFRunLoopAfterWaiting` → `kCFRunLoopBeforeWaiting`：处理唤醒后事件的耗时

如果这两个阶段耗时超过阈值（通常为 50ms，约 3 帧），则认为发生了卡顿。

#### 8.3.2 实现方式

**方式一：基于信号量的超时检测**
- 在主线程的 RunLoop 中添加 Observer，监听所有状态变化
- 在 Observer 回调中记录当前状态，并通过信号量通知监控线程
- 在子线程中使用信号量等待，设置超时时间为阈值（如 50ms）
- 如果信号量等待超时，且当前状态为 `BeforeSources` 或 `AfterWaiting`，则认为发生卡顿
- 记录主线程堆栈信息用于分析

**方式二：精确计算状态间耗时**
- 在主线程的 RunLoop 中添加 Observer，监听所有状态变化
- 在 `BeforeSources` 或 `AfterWaiting` 时记录开始时间
- 在 `BeforeWaiting` 时计算与开始时间的差值
- 如果耗时超过阈值，则记录卡顿并获取堆栈信息

#### 8.3.3 关键要点

1. **监控时机**：主要监控 `BeforeSources` 和 `AfterWaiting` 到 `BeforeWaiting` 的耗时
2. **阈值设置**：通常设置为 50ms（约 3 帧），可根据需求调整
3. **性能影响**：Observer 回调应尽量轻量，避免在回调中执行耗时操作
4. **堆栈获取**：建议采样或异步处理，避免频繁获取堆栈影响性能
5. **使用场景**：建议仅在 发生卡顿的时候 获取堆栈信息，避免频繁获取堆栈影响性能。

### 8.4 自动释放池的释放时机

RunLoop 在进入休眠前和退出时会释放自动释放池，这样可以及时释放临时对象。

#### 8.4.1 核心机制

主线程的 RunLoop 在启动时会自动注册两个 Observer，用于管理 AutoreleasePool 的生命周期。这两个 Observer 通过监听 RunLoop 的状态变化，在合适的时机创建和释放 AutoreleasePool。

#### 8.4.2 两个 Observer 的作用

**Observer 1：监听 `kCFRunLoopEntry`**
- **时机**：RunLoop 进入时
- **操作**：创建并 push 一个新的 AutoreleasePool
- **优先级**：最高（order = -2147483647），确保最先执行

**Observer 2：监听 `kCFRunLoopBeforeWaiting` 和 `kCFRunLoopExit`**
- **时机1**：RunLoop 即将进入休眠前（`kCFRunLoopBeforeWaiting`）
  - **操作**：pop 当前的 AutoreleasePool（释放其中的对象），并 push 一个新的 AutoreleasePool
- **时机2**：RunLoop 退出时（`kCFRunLoopExit`）
  - **操作**：pop 当前的 AutoreleasePool（释放其中的对象）
- **优先级**：最低（order = 2147483647），确保最后执行

#### 8.4.3 完整流程

1. **RunLoop 循环开始**：触发 `kCFRunLoopEntry`，创建新的 AutoreleasePool
2. **处理事件**：在处理 Timer、Source0、Source1 等事件时，所有被标记为 `autorelease` 的对象会被添加到当前的 AutoreleasePool 中
3. **即将休眠**：触发 `kCFRunLoopBeforeWaiting`，释放旧的 AutoreleasePool（pop），并创建新的 AutoreleasePool（push）
4. **线程休眠**：等待被唤醒
5. **被唤醒**：处理新的事件，重复上述过程
6. **RunLoop 退出**：触发 `kCFRunLoopExit`，释放 AutoreleasePool（pop）

#### 8.4.4 设计原因

- **及时释放**：在每次事件循环结束时释放临时对象，避免内存累积
- **自动管理**：主线程无需手动管理 AutoreleasePool，系统自动处理
- **性能优化**：在休眠前统一释放，减少内存峰值，提高内存使用效率

#### 8.4.5 子线程的情况

子线程的 RunLoop 默认不会自动创建和管理 AutoreleasePool。如果子线程需要运行 RunLoop，需要手动使用 `@autoreleasepool` 来管理自动释放池的生命周期。

#### 8.4.6 关键要点总结

1. **主线程自动管理**：主线程的 RunLoop 自动管理 AutoreleasePool，子线程需要手动管理
2. **释放时机**：RunLoop 进入休眠前（`BeforeWaiting`）和退出时（`Exit`）
3. **循环创建**：每个 RunLoop 循环都会创建新的 AutoreleasePool，确保临时对象及时释放
4. **Observer 机制**：通过 Observer 机制实现，优先级最高和最低，确保在正确时机执行
5. **内存优化**：这种设计让主线程的事件处理过程中的临时对象能够及时释放，避免内存泄漏和内存峰值过高

## 9. RunLoop 的底层实现？

RunLoop 的底层实现基于 **Mach** 内核的消息机制：

- **mach_msg()**：用于线程间通信，RunLoop 通过调用这个函数进入休眠
- **mach_port**：用于线程间通信的端口
- **Source1** 基于 mach_port 实现，当有事件到达时，内核会通过 mach_msg 唤醒线程

## 10. 如何手动唤醒 RunLoop？

- 通过 `CFRunLoopWakeUp()` 函数手动唤醒
- 添加 Source0 到 RunLoop 并标记为待处理
- 添加 Timer 到 RunLoop

## 11. RunLoop 的退出条件？

- 超时时间到期（如果设置了超时时间）
- 被手动停止（`CFRunLoopStop()`）
- Mode 中没有 Source0、Source1、Timer（会立即退出）

## 12. performSelector:onThread: 的实现原理？

`performSelector:onThread:` 的实现依赖于 RunLoop：

1. 在目标线程的 RunLoop 中添加一个 Source0
2. 将 selector 和参数封装后放入 Source0
3. 唤醒目标线程的 RunLoop
4. RunLoop 被唤醒后处理 Source0，执行 selector

## 13. 如何监控 RunLoop 的状态变化？

```objc
CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(
    kCFAllocatorDefault,
    kCFRunLoopAllActivities, // 监听所有活动
    YES,
    0,
    ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"RunLoop 进入");
                break;
            case kCFRunLoopBeforeTimers:
                NSLog(@"RunLoop 即将处理 Timer");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"RunLoop 即将处理 Source");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"RunLoop 即将休眠");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"RunLoop 被唤醒");
                break;
            case kCFRunLoopExit:
                NSLog(@"RunLoop 退出");
                break;
            default:
                break;
        }
    }
);

CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
```

## 14. RunLoop 与 AutoreleasePool 的关系？

- App 启动后，主线程的 RunLoop 注册了两个 Observer
- 第一个 Observer 监听 `kCFRunLoopEntry`，回调中创建 AutoreleasePool
- 第二个 Observer 监听 `kCFRunLoopBeforeWaiting` 和 `kCFRunLoopExit`，回调中释放旧的 AutoreleasePool 并创建新的

这样可以保证在 RunLoop 的每个循环中，临时对象都能及时释放。

## 15. 如何让子线程的 RunLoop 持续运行？

```objc
// 方式1：添加 Port
NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
[runLoop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
[runLoop run]; // 会一直运行，直到调用 CFRunLoopStop

// 方式2：添加 Timer
NSTimer *timer = [NSTimer timerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] 
                                         target:self 
                                       selector:@selector(doNothing) 
                                       userInfo:nil 
                                        repeats:YES];
[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
[runLoop run];
```

## 16. RunLoop 与事件响应链的关系？

当用户触摸屏幕时：
1. 系统内核通过 Source1 将触摸事件传递给主线程的 RunLoop
2. RunLoop 被唤醒，处理 Source1
3. Source1 触发 Source0，将事件分发给应用程序
4. 应用程序通过事件响应链找到合适的响应者处理事件

## 17. 如何实现一个常驻线程？

```objc
@interface ThreadManager : NSObject
@property (nonatomic, strong) NSThread *thread;
@end

@implementation ThreadManager

- (instancetype)init {
    if (self = [super init]) {
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntry) object:nil];
        [self.thread start];
    }
    return self;
}

- (void)threadEntry {
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        // 添加 Port，防止 RunLoop 退出
        [runLoop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

- (void)executeTask:(void(^)(void))task {
    [self performSelector:@selector(runTask:) onThread:self.thread withObject:task waitUntilDone:NO];
}

- (void)runTask:(void(^)(void))task {
    if (task) {
        task();
    }
}

@end
```

## 18. RunLoop 与 GCD 的关系？

- **GCD 的 dispatch_async 到主队列**：会唤醒主线程的 RunLoop，通过 Source1 实现
- **GCD 的定时器**：不依赖 RunLoop，基于内核实现，更加精确
- **RunLoop 的 Timer**：依赖 RunLoop，在滑动时可能失效

## 19. 如何检测主线程卡顿？

通过监听 RunLoop 的状态变化，计算 `kCFRunLoopBeforeSources` 到 `kCFRunLoopBeforeWaiting` 之间的耗时，如果超过阈值（如 50ms），则认为发生了卡顿。

## 20. RunLoop 的常见面试题总结

1. **RunLoop 是什么？** - 事件处理循环机制
2. **RunLoop 的作用？** - 保持程序运行、处理事件、节省资源、线程保活
3. **RunLoop 与线程的关系？** - 一一对应，主线程自动创建，子线程懒加载
4. **RunLoop 的 Mode 有哪些？** - Default、Tracking、CommonModes 等
5. **为什么 Timer 在滑动时失效？** - Mode 切换导致
6. **如何让 Timer 在滑动时也工作？** - 添加到 CommonModes 或使用 GCD 定时器
7. **RunLoop 的底层实现？** - 基于 Mach 内核的消息机制
8. **RunLoop 的应用场景？** - 线程保活、延迟执行、监控卡顿等

