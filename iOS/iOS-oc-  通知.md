# iOS 面试题 - 通知

## 1. 什么是通知（Notification）？

通知（Notification）是 iOS 开发中实现观察者模式的一种机制，用于在对象之间传递消息。它允许一个对象向多个观察者广播消息，实现解耦的通信方式。

### 1.1 通知的特点

- **一对多通信**：一个通知可以被多个观察者接收
- **解耦**：发送者和接收者不需要知道彼此的存在
- **异步通信**：通知是异步发送的
- **跨模块通信**：可以在不同模块间传递消息
- **基于字符串**：通过通知名称（字符串）来标识通知

### 1.2 通知的组成部分

- **NSNotificationCenter**：通知中心，负责管理通知的发送和接收
- **NSNotification**：通知对象，包含通知名称、发送对象和用户信息
- **Observer**：观察者，接收通知的对象

## 2. 通知的基本用法？

### 2.1 发送通知

```objc
// Objective-C
// 发送简单通知
[[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" object:nil];

// 发送带用户信息的通知
NSDictionary *userInfo = @{@"key": @"value"};
[[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" 
                                                      object:self 
                                                    userInfo:userInfo];
```

```swift
// Swift
// 发送简单通知
NotificationCenter.default.post(name: NSNotification.Name("MyNotification"), object: nil)

// 发送带用户信息的通知
let userInfo = ["key": "value"]
NotificationCenter.default.post(name: NSNotification.Name("MyNotification"), 
                                object: self, 
                                userInfo: userInfo)
```

### 2.2 注册观察者

```objc
// Objective-C
// 注册观察者
[[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(handleNotification:) 
                                              name:@"MyNotification" 
                                            object:nil];

// 处理通知的方法
- (void)handleNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    id object = notification.object;
    NSString *name = notification.name;
    NSLog(@"收到通知：%@", name);
}

// 移除观察者
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

```swift
// Swift
// 注册观察者（使用 selector）
NotificationCenter.default.addObserver(self, 
                                       selector: #selector(handleNotification(_:)), 
                                       name: NSNotification.Name("MyNotification"), 
                                       object: nil)

@objc func handleNotification(_ notification: Notification) {
    let userInfo = notification.userInfo
    let object = notification.object
    let name = notification.name
    print("收到通知：\(name)")
}

// 使用闭包注册观察者（推荐）
var observer: NSObjectProtocol?

override func viewDidLoad() {
    super.viewDidLoad()
    observer = NotificationCenter.default.addObserver(
        forName: NSNotification.Name("MyNotification"),
        object: nil,
        queue: .main
    ) { notification in
        print("收到通知：\(notification.name)")
    }
}

// 移除观察者
deinit {
    if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

## 3. NotificationCenter 的默认中心和自定义中心？

### 3.1 默认中心（defaultCenter）

```objc
// 获取默认通知中心
NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
```

- 应用程序级别的单例
- 所有对象共享同一个通知中心
- 最常用的通知中心

### 3.2 自定义通知中心

```objc
// 创建自定义通知中心
NSNotificationCenter *customCenter = [[NSNotificationCenter alloc] init];

// 使用自定义通知中心
[customCenter postNotificationName:@"MyNotification" object:nil];
```

- 可以创建多个通知中心
- 用于隔离不同模块的通知
- 较少使用，一般使用默认中心即可

## 4. 通知的 object 参数有什么作用？

`object` 参数用于过滤通知，只接收特定对象发送的通知。

### 4.1 使用 object 参数

```objc
// 发送通知时指定 object
[[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" 
                                                      object:self];

// 只接收特定对象发送的通知
[[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(handleNotification:) 
                                              name:@"MyNotification" 
                                            object:specificObject];

// object 为 nil 时，接收所有对象发送的该名称通知
[[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(handleNotification:) 
                                              name:@"MyNotification" 
                                            object:nil];
```

### 4.2 object 参数的作用

- **过滤通知**：只接收特定对象发送的通知
- **提高性能**：减少不必要的通知处理
- **精确控制**：在多个对象发送同名通知时，只处理特定对象的通知

## 5. 通知和代理（Delegate）的区别？

| 特性 | 通知 | 代理 |
|------|------|------|
| 通信方式 | 一对多 | 一对一 |
| 耦合度 | 低耦合 | 相对高耦合 |
| 使用场景 | 跨模块通信、全局事件 | 组件间通信、回调 |
| 性能 | 相对较慢（字符串匹配） | 相对较快（直接调用） |
| 类型安全 | 弱类型（字符串） | 强类型（协议） |
| 返回值 | 无返回值 | 可以有返回值 |

### 5.1 使用场景对比

**使用通知的场景：**
- 多个对象需要接收同一事件
- 跨模块通信
- 全局事件（如登录状态变化）
- 解耦需求高的场景

**使用代理的场景：**
- 一对一通信
- 需要返回值
- 需要类型安全
- 组件间直接通信

## 6. 通知的线程问题？

### 6.1 通知在哪个线程执行？

```objc
// 通知在发送通知的线程中执行
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 在后台线程发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" object:nil];
    // 观察者的方法会在后台线程执行
});
```

### 6.2 指定通知执行的队列

```swift
// Swift - 使用闭包方式可以指定队列
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("MyNotification"),
    object: nil,
    queue: .main  // 指定在主队列执行
) { notification in
    // 这个闭包会在主队列执行
    print("收到通知")
}

// Objective-C - 需要手动切换到主线程
- (void)handleNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 更新 UI
    });
}
```

## 7. 系统通知有哪些？

iOS 系统提供了很多预定义的通知，常用的有：

### 7.1 UI 相关通知

```objc
// 应用进入前台
UIApplicationDidBecomeActiveNotification

// 应用进入后台
UIApplicationDidEnterBackgroundNotification

// 应用即将进入前台
UIApplicationWillEnterForegroundNotification

// 应用即将终止
UIApplicationWillTerminateNotification

// 键盘显示
UIKeyboardWillShowNotification
UIKeyboardDidShowNotification

// 键盘隐藏
UIKeyboardWillHideNotification
UIKeyboardDidHideNotification

// 键盘大小改变
UIKeyboardWillChangeFrameNotification
UIKeyboardDidChangeFrameNotification
```

### 7.2 使用系统通知示例

```objc
// 监听应用进入后台
[[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(applicationDidEnterBackground:) 
                                              name:UIApplicationDidEnterBackgroundNotification 
                                            object:nil];

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"应用进入后台");
}

// 监听键盘显示
[[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(keyboardWillShow:) 
                                              name:UIKeyboardWillShowNotification 
                                            object:nil];

- (void)keyboardWillShow:(NSNotification *)notification {
    NSValue *keyboardFrame = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect frame = [keyboardFrame CGRectValue];
    NSLog(@"键盘高度：%f", frame.size.height);
}
```

```swift
// Swift
// 监听应用进入后台
NotificationCenter.default.addObserver(
    self,
    selector: #selector(applicationDidEnterBackground),
    name: UIApplication.didEnterBackgroundNotification,
    object: nil
)

@objc func applicationDidEnterBackground() {
    print("应用进入后台")
}

// 监听键盘显示
NotificationCenter.default.addObserver(
    self,
    selector: #selector(keyboardWillShow(_:)),
    name: UIResponder.keyboardWillShowNotification,
    object: nil
)

@objc func keyboardWillShow(_ notification: Notification) {
    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
        print("键盘高度：\(keyboardFrame.height)")
    }
}
```

## 8. 通知的内存管理？

### 8.1 必须移除观察者

```objc
// 在 dealloc 中移除观察者
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

**原因：**
- NotificationCenter 持有观察者的强引用
- 如果不移除，会导致观察者无法释放
- 可能造成内存泄漏

### 8.2 iOS 9+ 的自动移除

```objc
// iOS 9+ 系统会自动移除观察者
// 但为了兼容性和明确性，建议手动移除
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

### 8.3 Swift 中的内存管理

```swift
// 使用闭包方式注册观察者
var observer: NSObjectProtocol?

override func viewDidLoad() {
    super.viewDidLoad()
    observer = NotificationCenter.default.addObserver(
        forName: NSNotification.Name("MyNotification"),
        object: nil,
        queue: .main
    ) { notification in
        // 处理通知
    }
}

// 必须保存 observer 并在 deinit 中移除
deinit {
    if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

## 9. 通知的命名规范？

### 9.1 通知名称定义

```objc
// 使用常量定义通知名称（推荐）
// .h 文件
extern NSString * const MyNotificationName;

// .m 文件
NSString * const MyNotificationName = @"MyNotificationName";
```

```swift
// Swift - 使用扩展定义通知名称
extension Notification.Name {
    static let myNotification = Notification.Name("MyNotification")
}

// 使用
NotificationCenter.default.post(name: .myNotification, object: nil)
NotificationCenter.default.addObserver(
    forName: .myNotification,
    object: nil,
    queue: .main
) { notification in
    // 处理通知
}
```

### 9.2 命名规范

- 使用有意义的名称
- 使用常量而非硬编码字符串
- 遵循系统通知的命名风格
- 使用驼峰命名法

## 10. 通知和 KVO 的区别？

| 特性 | 通知 | KVO |
|------|------|-----|
| 观察对象 | 任意对象 | 特定对象的属性 |
| 通信方式 | 一对多 | 一对一 |
| 使用方式 | 字符串名称 | KeyPath |
| 性能 | 相对较慢 | 相对较快 |
| 类型安全 | 弱类型 | 相对强类型 |
| 使用场景 | 跨模块通信 | 属性变化监听 |

### 10.1 使用场景对比

**使用通知：**
- 多个对象需要接收同一事件
- 跨模块通信
- 全局事件

**使用 KVO：**
- 监听特定对象的属性变化
- 需要精确的属性变化通知
- 一对一通信

## 11. 通知的优缺点？

### 11.1 优点

- **解耦**：发送者和接收者不需要知道彼此
- **一对多**：一个通知可以被多个观察者接收
- **跨模块**：可以在不同模块间传递消息
- **简单易用**：API 简单，容易理解

### 11.2 缺点

- **类型不安全**：使用字符串，容易出错
- **性能开销**：字符串匹配和遍历观察者
- **调试困难**：通知的发送和接收关系不明确
- **内存管理**：需要手动移除观察者
- **线程安全**：需要注意线程问题

## 12. 通知的最佳实践？

### 12.1 使用常量定义通知名称

```swift
extension Notification.Name {
    static let userDidLogin = Notification.Name("UserDidLogin")
    static let userDidLogout = Notification.Name("UserDidLogout")
}
```

### 12.2 使用结构化的 UserInfo

```swift
extension Notification {
    struct UserInfoKeys {
        static let userId = "userId"
        static let userName = "userName"
    }
}

// 发送通知
let userInfo: [String: Any] = [
    Notification.UserInfoKeys.userId: "123",
    Notification.UserInfoKeys.userName: "张三"
]
NotificationCenter.default.post(name: .userDidLogin, object: nil, userInfo: userInfo)
```

### 12.3 及时移除观察者

```swift
class ViewController: UIViewController {
    private var observers: [NSObjectProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let observer1 = NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { notification in
            // 处理通知
        }
        observers.append(observer1)
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
```

### 12.4 使用闭包而非 selector（Swift）

```swift
// 推荐：使用闭包
NotificationCenter.default.addObserver(
    forName: .myNotification,
    object: nil,
    queue: .main
) { notification in
    // 处理通知
}

// 不推荐：使用 selector（需要 @objc 标记）
@objc func handleNotification(_ notification: Notification) {
    // 处理通知
}
```

## 13. 通知的替代方案？

### 13.1 Combine 框架（iOS 13+）

```swift
import Combine

class ViewModel {
    @Published var name: String = ""
}

class ViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 使用 Combine 替代通知
        viewModel.$name
            .sink { [weak self] name in
                self?.updateUI(name: name)
            }
            .store(in: &cancellables)
    }
}
```

### 13.2 RxSwift

```swift
import RxSwift

// 使用 RxSwift 的 NotificationCenter 扩展
NotificationCenter.default.rx
    .notification(.userDidLogin)
    .subscribe(onNext: { notification in
        // 处理通知
    })
    .disposed(by: disposeBag)
```

### 13.3 自定义事件总线

```swift
class EventBus {
    static let shared = EventBus()
    private var observers: [String: [(Any) -> Void]] = [:]
    
    func subscribe<T>(_ type: T.Type, observer: @escaping (T) -> Void) {
        let key = String(describing: type)
        if observers[key] == nil {
            observers[key] = []
        }
        observers[key]?.append { value in
            if let typedValue = value as? T {
                observer(typedValue)
            }
        }
    }
    
    func post<T>(_ event: T) {
        let key = String(describing: T.self)
        observers[key]?.forEach { $0(event) }
    }
}
```

## 14. 通知的线程安全问题？

### 14.1 NotificationCenter 的线程安全

- NotificationCenter 是线程安全的
- 可以在任意线程发送和接收通知
- 但观察者的方法会在发送通知的线程执行

### 14.2 处理线程问题

```swift
// 方式1：指定队列
NotificationCenter.default.addObserver(
    forName: .myNotification,
    object: nil,
    queue: .main  // 在主队列执行
) { notification in
    // 更新 UI
}

// 方式2：手动切换线程
NotificationCenter.default.addObserver(
    forName: .myNotification,
    object: nil,
    queue: nil
) { notification in
    DispatchQueue.main.async {
        // 更新 UI
    }
}
```

## 15. 通知的调试技巧？

### 15.1 打印通知信息

```swift
// 添加通知日志
NotificationCenter.default.addObserver(
    forName: nil,  // 监听所有通知
    object: nil,
    queue: nil
) { notification in
    print("通知名称：\(notification.name)")
    print("发送对象：\(notification.object ?? "nil")")
    print("用户信息：\(notification.userInfo ?? [:])")
}
```

### 15.2 使用断点调试

```swift
// 在观察者方法中添加断点
@objc func handleNotification(_ notification: Notification) {
    // 设置断点，查看调用栈
    print("收到通知")
}
```

## 16. 通知的实际应用场景？

### 16.1 用户登录/登出

```swift
extension Notification.Name {
    static let userDidLogin = Notification.Name("UserDidLogin")
    static let userDidLogout = Notification.Name("UserDidLogout")
}

// 登录成功后发送通知
func login() {
    // 登录逻辑
    NotificationCenter.default.post(name: .userDidLogin, object: nil)
}

// 多个地方监听登录状态
NotificationCenter.default.addObserver(
    forName: .userDidLogin,
    object: nil,
    queue: .main
) { _ in
    // 更新 UI
    // 刷新数据
}
```

### 16.2 数据更新通知

```swift
extension Notification.Name {
    static let dataDidUpdate = Notification.Name("DataDidUpdate")
}

// 数据更新后发送通知
func updateData() {
    // 更新数据
    NotificationCenter.default.post(name: .dataDidUpdate, object: nil)
}
```

### 16.3 主题切换

```swift
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

// 切换主题
func changeTheme() {
    // 切换主题逻辑
    NotificationCenter.default.post(name: .themeDidChange, object: nil)
}
```

## 17. 通知的性能优化？

### 17.1 减少通知数量

- 避免频繁发送通知
- 合并多个通知为一个
- 使用 object 参数过滤不需要的通知

### 17.2 优化观察者方法

```swift
// 避免在观察者方法中执行耗时操作
NotificationCenter.default.addObserver(
    forName: .myNotification,
    object: nil,
    queue: .main
) { notification in
    // 快速处理，耗时操作放到后台队列
    DispatchQueue.global().async {
        // 耗时操作
    }
}
```

## 18. 总结

通知是 iOS 开发中重要的通信机制，具有以下特点：

1. **解耦通信**：发送者和接收者不需要知道彼此
2. **一对多**：一个通知可以被多个观察者接收
3. **简单易用**：API 简单，容易理解
4. **内存管理**：需要手动移除观察者
5. **线程安全**：NotificationCenter 是线程安全的
6. **类型安全**：使用字符串，类型安全性较弱

在实际开发中，应该：
- 使用常量定义通知名称
- 及时移除观察者
- 注意线程问题
- 考虑使用 Combine 或 RxSwift 等现代方案
- 遵循最佳实践

