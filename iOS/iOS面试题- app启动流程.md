# iOS 面试题 - app启动流程

## 1. iOS 应用的完整启动流程是什么？

iOS 应用的启动流程可以分为以下几个主要阶段：

### 1.1 启动流程概览

```
1. 系统启动应用进程
2. dyld 加载动态库
3. Runtime 初始化
4. main 函数执行
5. UIApplicationMain 创建
6. AppDelegate 初始化
7. 主运行循环启动
8. 视图控制器加载
9. 界面渲染完成
```

### 1.2 详细流程说明

#### 阶段一：系统启动应用进程

- 用户点击应用图标
- iOS 系统创建新进程
- 分配内存空间
- 加载应用的可执行文件（Mach-O）

#### 阶段二：dyld 动态链接

dyld（dynamic link editor）负责加载动态库：

```objc
// dyld 加载流程
1. 加载主可执行文件
2. 加载依赖的动态库（递归加载）
3. 符号绑定（Symbol Binding）
4. 初始化静态变量
5. 调用 +load 方法
```

#### 阶段三：Runtime 初始化

Objective-C Runtime 进行初始化：

```objc
// Runtime 初始化过程
1. 注册类（Class Registration）
2. 注册分类（Category Registration）
3. 调用 +load 方法（所有类和分类）
4. 调用 C++ 静态构造函数
```

#### 阶段四：main 函数执行

```objc
// main.m
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

#### 阶段五：UIApplicationMain 创建

```objc
// UIApplicationMain 函数的作用
1. 创建 UIApplication 单例对象
2. 创建 AppDelegate 对象
3. 设置 AppDelegate 为 UIApplication 的代理
4. 启动主运行循环（Main RunLoop）
```

#### 阶段六：AppDelegate 初始化

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. 创建窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // 2. 创建根视图控制器
    ViewController *rootVC = [[ViewController alloc] init];
    self.window.rootViewController = rootVC;
    
    // 3. 显示窗口
    [self.window makeKeyAndVisible];
    
    return YES;
}
```

#### 阶段七：主运行循环启动

主运行循环（Main RunLoop）开始处理事件：

```objc
// RunLoop 处理的事件类型
1. Source0：用户交互事件（触摸、点击等）
2. Source1：系统事件（端口通信等）
3. Timer：定时器事件
4. Observer：观察者事件（用于界面刷新）
```

#### 阶段八：视图控制器加载

```objc
// ViewController 生命周期
1. init / initWithNibName:bundle:
2. loadView
3. viewDidLoad
4. viewWillAppear:
5. viewDidAppear:
```

#### 阶段九：界面渲染完成

- 视图层级构建完成
- Auto Layout 约束计算完成
- 界面渲染到屏幕
- 应用启动完成

## 2. dyld 的加载流程是什么？

### 2.1 dyld 简介

dyld（dynamic link editor）是 macOS 和 iOS 系统的动态链接器，负责加载应用和动态库。

### 2.2 dyld 加载流程

```
1. 加载主可执行文件（Mach-O）
   ↓
2. 递归加载依赖的动态库
   ↓
3. 符号绑定（Symbol Binding）
   ↓
4. 初始化静态变量
   ↓
5. 调用 +load 方法
```

### 2.3 代码示例

```objc
// 查看应用加载的动态库
// 在 main 函数中添加断点，使用 LLDB 命令：
// image list

// 查看符号绑定信息
// dyld 会将未定义的符号绑定到实际地址
```

### 2.4 dyld 优化

iOS 13+ 引入了 dyld3，主要优化：

- **启动闭包（Launch Closure）**：预计算启动信息
- **进程外验证**：在应用启动前验证代码签名
- **更快的符号绑定**：优化符号查找速度

## 3. +load 和 +initialize 的区别？

### 3.1 +load 方法

```objc
// +load 方法特点
1. 在 main 函数之前调用
2. 所有类和分类的 +load 都会调用
3. 调用顺序：父类 -> 子类 -> 分类
4. 不需要调用 [super load]
5. 线程安全，但不要做耗时操作
```

### 3.2 +initialize 方法

```objc
// +initialize 方法特点
1. 在类第一次使用时调用（懒加载）
2. 只会调用一次
3. 如果子类没有实现，会调用父类的
4. 线程安全，但不要做耗时操作
```

### 3.3 代码示例

```objc
// Person.h
@interface Person : NSObject
@end

// Person.m
@implementation Person

+ (void)load {
    NSLog(@"Person +load 被调用");
    // 在 main 函数之前调用
}

+ (void)initialize {
    NSLog(@"Person +initialize 被调用");
    // 在类第一次使用时调用
}

@end

// Student.h
@interface Student : Person
@end

// Student.m
@implementation Student

+ (void)load {
    NSLog(@"Student +load 被调用");
    // 调用顺序：Person +load -> Student +load
}

+ (void)initialize {
    NSLog(@"Student +initialize 被调用");
    // 如果 Student 没有实现，会调用 Person 的
}

@end
```

### 3.4 调用时机对比

| 特性 | +load | +initialize |
|------|-------|-------------|
| 调用时机 | main 函数之前 | 类第一次使用时 |
| 调用次数 | 每个类/分类都调用 | 每个类只调用一次 |
| 调用顺序 | 父类 -> 子类 -> 分类 | 类 -> 父类（如果子类未实现） |
| 是否需要 super | 不需要 | 不需要 |
| 使用场景 | 方法交换、注册类 | 初始化静态变量 |

## 4. UIApplicationMain 的作用是什么？

### 4.1 UIApplicationMain 函数签名

```objc
UIKIT_EXTERN int UIApplicationMain(int argc, char *argv[], 
                                   NSString * __nullable principalClassName, 
                                   NSString * __nullable delegateClassName);
```

### 4.2 参数说明

- **argc, argv**：命令行参数
- **principalClassName**：UIApplication 类名，nil 表示使用默认的 UIApplication
- **delegateClassName**：AppDelegate 类名

### 4.3 UIApplicationMain 的作用

```objc
// UIApplicationMain 内部实现（简化版）
int UIApplicationMain(int argc, char *argv[], NSString *principalClassName, NSString *delegateClassName) {
    // 1. 创建 UIApplication 单例
    UIApplication *application = [UIApplication sharedApplication];
    
    // 2. 创建 AppDelegate 对象
    Class delegateClass = NSClassFromString(delegateClassName);
    id<UIApplicationDelegate> delegate = [[delegateClass alloc] init];
    application.delegate = delegate;
    
    // 3. 启动主运行循环
    [[NSRunLoop mainRunLoop] run];
    
    return 0;
}
```

### 4.4 为什么 UIApplicationMain 不会返回？

```objc
// UIApplicationMain 启动主运行循环后，会一直运行
// 直到应用退出，所以这个函数不会返回
// 主运行循环会持续处理事件：
// - 用户交互事件
// - 系统事件
// - 定时器事件
// - 界面刷新事件
```

## 5. 应用启动时间的优化方法有哪些？

### 5.1 启动时间分类

- **冷启动（Cold Launch）**：应用完全关闭后重新启动
- **热启动（Warm Launch）**：应用在后台被系统回收内存后重新启动
- **回前台（Resume）**：应用从后台恢复到前台

### 5.2 启动时间测量

```objc
// 方法一：使用环境变量
// Edit Scheme -> Run -> Arguments -> Environment Variables
// 添加：DYLD_PRINT_STATISTICS = 1

// 方法二：代码测量
CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
// ... 启动代码 ...
CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
NSLog(@"启动耗时：%.2f 秒", endTime - startTime);

// 方法三：使用 Instruments
// Time Profiler 工具可以分析启动时间
```

### 5.3 优化方法

#### 5.3.1 减少动态库数量

```objc
// 问题：动态库加载耗时
// 解决：
1. 合并动态库
2. 使用静态库替代动态库（如果可能）
3. 延迟加载非必要的动态库
```

#### 5.3.2 优化 +load 方法

```objc
// 问题：+load 方法在 main 函数之前执行，影响启动时间
// 解决：
1. 将 +load 中的逻辑移到 +initialize 或懒加载
2. 避免在 +load 中做耗时操作
3. 使用 dispatch_once 确保只执行一次
```

#### 5.3.3 减少启动时的初始化工作

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ❌ 不好的做法：在启动时初始化所有功能
    [self initAllFeatures];
    [self loadAllData];
    [self setupAllServices];
    
    // ✅ 好的做法：延迟初始化
    [self.window makeKeyAndVisible];
    
    // 在界面显示后再初始化非关键功能
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initNonCriticalFeatures];
    });
    
    return YES;
}
```

#### 5.3.4 使用启动页优化

```objc
// LaunchScreen.storyboard
// 使用与首屏相似的启动页，减少视觉差异
// 避免在启动页加载大量资源
```

#### 5.3.5 优化主线程工作

```objc
// 问题：主线程阻塞影响启动
// 解决：
1. 将耗时操作移到后台线程
2. 使用异步加载数据
3. 延迟非关键 UI 的创建
```

#### 5.3.6 使用 dyld3 优化

```objc
// iOS 13+ 自动使用 dyld3
// 主要优化：
1. 启动闭包（Launch Closure）预计算
2. 进程外验证代码签名
3. 更快的符号绑定
```

### 5.4 启动时间优化检查清单

- [ ] 减少动态库数量
- [ ] 优化 +load 方法
- [ ] 延迟非关键功能初始化
- [ ] 使用启动页优化视觉体验
- [ ] 避免主线程阻塞
- [ ] 使用异步加载数据
- [ ] 优化首屏渲染
- [ ] 使用 Instruments 分析启动时间

## 6. 启动流程中的关键对象有哪些？

### 6.1 UIApplication

```objc
// UIApplication 是应用的核心对象
// 特点：
1. 单例对象（通过 sharedApplication 获取）
2. 管理应用的生命周期
3. 处理系统事件
4. 管理应用的状态
```

### 6.2 AppDelegate

```objc
// AppDelegate 是应用的代理对象
// 主要职责：
1. 处理应用生命周期事件
2. 处理系统通知
3. 管理应用的状态转换
4. 处理推送通知
```

### 6.3 UIWindow

```objc
// UIWindow 是应用的窗口对象
// 特点：
1. 应用的根容器
2. 管理视图层级
3. 处理触摸事件分发
4. 管理键盘和状态栏
```

### 6.4 RootViewController

```objc
// RootViewController 是应用的根视图控制器
// 特点：
1. 应用的第一个视图控制器
2. 管理应用的导航结构
3. 处理应用的主要界面逻辑
```

## 7. 启动流程中的关键方法调用顺序是什么？

### 7.1 完整调用顺序

```
1. +load 方法（所有类和分类）
   ↓
2. main 函数
   ↓
3. UIApplicationMain
   ↓
4. UIApplication 创建
   ↓
5. AppDelegate 创建
   ↓
6. application:didFinishLaunchingWithOptions:
   ↓
7. window 创建和显示
   ↓
8. RootViewController 创建
   ↓
9. viewDidLoad
   ↓
10. viewWillAppear:
   ↓
11. viewDidAppear:
   ↓
12. 主运行循环启动
```

### 7.2 代码示例

```objc
// 1. +load 方法
+ (void)load {
    NSLog(@"1. +load 被调用");
}

// 2. main 函数
int main(int argc, char * argv[]) {
    NSLog(@"2. main 函数执行");
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

// 3. AppDelegate
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"3. didFinishLaunchingWithOptions");
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    ViewController *vc = [[ViewController alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    return YES;
}

// 4. ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"4. viewDidLoad");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"5. viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"6. viewDidAppear");
}
```

## 8. 启动流程中的内存管理是怎样的？

### 8.1 启动时的内存分配

```objc
// 启动时的内存分配顺序
1. 系统为应用分配内存空间
2. 加载可执行文件到内存
3. 加载动态库到内存
4. 创建全局变量和静态变量
5. 创建 UIApplication 和 AppDelegate
6. 创建 UIWindow 和视图控制器
7. 加载视图和资源
```

### 8.2 启动时的内存优化

```objc
// 优化方法
1. 延迟加载非关键资源
2. 使用图片缓存
3. 避免在启动时加载大量数据
4. 使用懒加载初始化对象
5. 及时释放不需要的对象
```

### 8.3 代码示例

```objc
// ❌ 不好的做法：在启动时加载所有数据
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 加载大量数据到内存
    self.allData = [self loadAllDataFromDisk];
    return YES;
}

// ✅ 好的做法：延迟加载
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 只加载必要的数据
    self.essentialData = [self loadEssentialData];
    return YES;
}

// 在需要时再加载其他数据
- (void)loadMoreDataWhenNeeded {
    if (!self.allData) {
        self.allData = [self loadAllDataFromDisk];
    }
}
```

## 9. 启动流程中的异常处理是怎样的？

### 9.1 启动时的异常类型

```objc
// 常见的启动异常
1. 动态库加载失败
2. 符号绑定失败
3. +load 方法崩溃
4. didFinishLaunchingWithOptions 崩溃
5. 视图控制器初始化失败
```

### 9.2 异常处理机制

```objc
// iOS 系统的异常处理
1. 如果启动过程中发生崩溃，系统会终止应用
2. 可以使用 NSSetUncaughtExceptionHandler 捕获异常
3. 可以使用信号处理捕获底层崩溃
```

### 9.3 代码示例

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 设置异常处理
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // 使用 try-catch 保护关键代码
    @try {
        [self setupApplication];
    } @catch (NSException *exception) {
        NSLog(@"启动异常：%@", exception);
        // 处理异常，避免应用崩溃
    }
    
    return YES;
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"未捕获的异常：%@", exception);
    // 记录崩溃信息，上传到服务器
}
```

## 10. 启动流程在不同 iOS 版本中的差异？

### 10.1 iOS 13+ 的变化

```objc
// iOS 13+ 的主要变化
1. 使用 dyld3 替代 dyld2
2. SceneDelegate 引入（支持多窗口）
3. 启动闭包优化
4. 更快的符号绑定
```

### 10.2 SceneDelegate 的影响

```objc
// iOS 13+ 支持 SceneDelegate
// 应用可以有多个场景（Scene），每个场景有独立的生命周期
// 启动流程：
1. UIApplication 创建
2. SceneDelegate 创建（如果有）
3. scene:willConnectToSession:options: 调用
4. sceneDidBecomeActive: 调用
```

### 10.3 代码示例

```objc
// SceneDelegate.m (iOS 13+)
- (void)scene:(UIScene *)scene 
willConnectToSession:(UISceneSession *)session 
      options:(UISceneConnectionOptions *)connectionOptions {
    // 场景连接时的初始化
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    // 场景激活时
}
```

### 10.4 版本兼容性处理

```objc
// 处理不同版本的启动流程
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (@available(iOS 13.0, *)) {
        // iOS 13+ 使用 SceneDelegate
        // 不需要在这里创建 window
    } else {
        // iOS 13 以下使用 AppDelegate
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.rootViewController = [[ViewController alloc] init];
        [self.window makeKeyAndVisible];
    }
    return YES;
}
```

