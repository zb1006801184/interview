# iOS 面试题 - 基础知识

## 1. Objective-C 和 Swift 的区别？

### 1.1 语言特性对比

| 特性 | Objective-C | Swift |
|------|-------------|-------|
| 语言类型 | 动态语言 | 静态语言 |
| 类型安全 | 弱类型 | 强类型 |
| 空值处理 | nil | Optional |
| 语法风格 | 消息传递 | 函数调用 |
| 内存管理 | MRC/ARC | ARC |
| 性能 | 运行时开销较大 | 编译时优化，性能更好 |

### 1.2 代码示例

```objc
// Objective-C
NSString *name = @"iOS";
NSArray *array = @[@"1", @"2", @"3"];
id object = array[0]; // 弱类型，编译时不检查

// Swift
let name: String = "iOS"
let array: [String] = ["1", "2", "3"]
let object: String? = array.first // 强类型，Optional
```

## 2. 什么是面向对象编程（OOP）？

面向对象编程是一种编程范式，核心概念包括：

### 2.1 四大特性

- **封装（Encapsulation）**：将数据和操作数据的方法封装在一起
- **继承（Inheritance）**：子类可以继承父类的属性和方法
- **多态（Polymorphism）**：同一接口可以有不同的实现
- **抽象（Abstraction）**：隐藏实现细节，只暴露接口

### 2.2 代码示例

```objc
// 封装
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
- (void)introduce;
@end

// 继承
@interface Student : Person
@property (nonatomic, assign) NSInteger grade;
@end

// 多态
Person *person1 = [[Person alloc] init];
Person *person2 = [[Student alloc] init];
[person1 introduce]; // 调用 Person 的方法
[person2 introduce]; // 调用 Student 的方法（如果重写）
```

## 3. iOS 应用的生命周期？

### 3.1 应用状态

- **Not Running**：应用未启动或已终止
- **Inactive**：应用在前台但不接收事件
- **Active**：应用在前台并接收事件
- **Background**：应用在后台执行代码
- **Suspended**：应用在后台但不执行代码

### 3.2 生命周期方法

```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 应用启动完成
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // 应用即将进入非活动状态
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // 应用已进入后台
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // 应用即将进入前台
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 应用已激活
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // 应用即将终止
}
```

## 4. ViewController 的生命周期？

### 4.1 生命周期方法顺序

```
1. init / initWithNibName:bundle:
2. loadView
3. viewDidLoad
4. viewWillAppear:
5. viewWillLayoutSubviews
6. viewDidLayoutSubviews
7. viewDidAppear:
8. viewWillDisappear:
9. viewDidDisappear:
10. dealloc
```

### 4.2 代码示例

```objc
- (instancetype)init {
    if (self = [super init]) {
        // 初始化
    }
    return self;
}

- (void)loadView {
    // 创建视图（如果使用代码创建）
    self.view = [[UIView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 视图加载完成，只调用一次
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 视图即将显示，每次显示都会调用
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 视图已显示
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 视图即将消失
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 视图已消失
}

- (void)dealloc {
    // 释放资源
}
```

## 5. 什么是 Category（分类）？

Category 是 Objective-C 的一个特性，可以在不修改原类的情况下为类添加方法。

### 5.1 基本用法

```objc
// NSString+Extension.h
@interface NSString (Extension)
- (BOOL)isValidEmail;
- (NSString *)reverseString;
@end

// NSString+Extension.m
@implementation NSString (Extension)
- (BOOL)isValidEmail {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (NSString *)reverseString {
    NSMutableString *reversed = [NSMutableString string];
    for (NSInteger i = self.length - 1; i >= 0; i--) {
        [reversed appendString:[self substringWithRange:NSMakeRange(i, 1)]];
    }
    return reversed;
}
@end
```

### 5.2 Category 的特点

- 可以为系统类添加方法
- 不能添加实例变量（可以使用关联对象）
- 方法名冲突时，Category 的方法会覆盖原类方法
- 可以添加属性，但需要实现 getter/setter

## 6. 什么是 Extension（扩展）？

Extension 是 Category 的特殊形式，也称为匿名 Category。

### 6.1 与 Category 的区别

| 特性 | Category | Extension |
|------|----------|-----------|
| 声明位置 | .h 和 .m 文件 | .m 文件 |
| 可见性 | 公开 | 私有 |
| 添加方法 | 可以 | 可以 |
| 添加属性 | 需要关联对象 | 可以直接添加 |
| 添加实例变量 | 不可以 | 不可以 |

### 6.2 分类的作用


### 6.2 代码示例

```objc
// Person.m
@interface Person ()
@property (nonatomic, strong) NSString *privateName; // 私有属性
- (void)privateMethod; // 私有方法
@end

@implementation Person
- (void)privateMethod {
    // 实现私有方法
}
@end
```

## 7. 什么是 Protocol（协议）？

Protocol 定义了一组方法，类可以遵循协议并实现这些方法。

### 7.1 基本用法

```objc
// 定义协议
@protocol UITableViewDataSource <NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
@end

// 遵循协议
@interface ViewController : UIViewController <UITableViewDataSource>
@end

// 实现协议方法
@implementation ViewController
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    return cell;
}
@end
```

### 7.2 Protocol 的特性

- `@required`：必须实现的方法（默认）
- `@optional`：可选实现的方法
- 可以定义属性
- 支持多继承（一个类可以遵循多个协议）

## 8. 什么是 Delegate（代理）？

Delegate 是一种设计模式，用于对象之间的通信。

### 8.1 基本用法

```objc
// 定义协议
@protocol CustomViewDelegate <NSObject>
- (void)customView:(CustomView *)view didTapButton:(UIButton *)button;
@optional
- (BOOL)customViewShouldAllowTap:(CustomView *)view;
@end

// 声明代理属性
@interface CustomView : UIView
@property (nonatomic, weak) id<CustomViewDelegate> delegate;
@end

// 调用代理方法
@implementation CustomView
- (void)buttonTapped:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(customView:didTapButton:)]) {
        [self.delegate customView:self didTapButton:button];
    }
}
@end
```

### 8.2 Delegate 的特点

- 使用 `weak` 修饰，避免循环引用
- 一对一的通信
- 需要检查 `respondsToSelector:` 判断是否实现了可选方法

## 9. 什么是 Notification（通知）？

Notification 是 iOS 中的观察者模式实现，用于一对多的通信。

### 9.1 基本用法

```objc
// 发送通知
[[NSNotificationCenter defaultCenter] postNotificationName:@"UserDidLogin" 
                                                    object:self 
                                                  userInfo:@{@"userId": @123}];

// 注册通知
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(userDidLogin:) 
                                             name:@"UserDidLogin" 
                                           object:nil];

// 处理通知
- (void)userDidLogin:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *userId = userInfo[@"userId"];
}

// 移除通知
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

### 9.2 Notification 的特点

- 一对多的通信
- 解耦发送者和接收者
- 需要手动移除观察者（iOS 9+ 可以自动移除）

## 10. 什么是 KVO（键值观察）？

KVO 是一种观察者模式，用于监听对象属性的变化。

### 10.1 基本用法

```objc
// 注册观察者
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
            context:nil];

// 实现观察方法
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    if ([keyPath isEqualToString:@"name"]) {
        NSString *oldValue = change[NSKeyValueChangeOldKey];
        NSString *newValue = change[NSKeyValueChangeNewKey];
        NSLog(@"name 从 %@ 变为 %@", oldValue, newValue);
    }
}

// 移除观察者
- (void)dealloc {
    [person removeObserver:self forKeyPath:@"name"];
}
```

## 11. 什么是 KVC（键值编码）？

KVC 是一种通过字符串访问对象属性的机制。

### 11.1 基本用法

```objc
// 设置值
[person setValue:@"John" forKey:@"name"];
[person setValue:@25 forKeyPath:@"age"];

// 获取值
NSString *name = [person valueForKey:@"name"];
NSNumber *age = [person valueForKeyPath:@"age"];

// 键路径
[person setValue:@"Beijing" forKeyPath:@"address.city"];
```

### 11.2 KVC 的查找顺序

1. `set<Key>:` 或 `_set<Key>:`
2. `setIs<Key>:`
3. 访问实例变量：`_<key>`, `_is<Key>`, `<key>`, `is<Key>`

## 12. 什么是单例模式？

单例模式确保一个类只有一个实例，并提供全局访问点。

### 12.1 实现方式

```objc
// 方式1：GCD
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// 方式2：传统方式
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

### 12.2 单例的优缺点

**优点**：
- 全局唯一实例
- 节省内存
- 方便访问

**缺点**：
- 难以测试
- 隐藏依赖关系
- 线程安全问题需要注意

## 13. 什么是工厂模式？

工厂模式用于创建对象，而不需要指定具体的类。

### 13.1 简单工厂模式

```objc
typedef NS_ENUM(NSInteger, AnimalType) {
    AnimalTypeDog,
    AnimalTypeCat
};

@interface AnimalFactory : NSObject
+ (Animal *)createAnimalWithType:(AnimalType)type;
@end

@implementation AnimalFactory
+ (Animal *)createAnimalWithType:(AnimalType)type {
    switch (type) {
        case AnimalTypeDog:
            return [[Dog alloc] init];
        case AnimalTypeCat:
            return [[Cat alloc] init];
        default:
            return nil;
    }
}
@end
```

## 14. 什么是 MVC 架构模式？

MVC（Model-View-Controller）是 iOS 开发中最常用的架构模式。

### 14.1 组成部分

- **Model**：数据和业务逻辑
- **View**：用户界面
- **Controller**：协调 Model 和 View

### 14.2 数据流向

```
用户操作 -> View -> Controller -> Model
Model 变化 -> Controller -> View 更新
```

### 14.3 代码示例

```objc
// Model
@interface User : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger age;
@end

// View
@interface UserView : UIView
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *ageLabel;
- (void)configureWithUser:(User *)user;
@end

// Controller
@interface UserViewController : UIViewController
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UserView *userView;
@end
```

## 15. 什么是 MVVM 架构模式？

MVVM（Model-View-ViewModel）是 MVC 的改进版本。

### 15.1 组成部分

- **Model**：数据和业务逻辑
- **View**：用户界面
- **ViewModel**：视图模型，处理视图逻辑

### 15.2 与 MVC 的区别

| 特性 | MVC | MVVM |
|------|-----|------|
| Controller | 厚重，包含业务逻辑 | 轻量，只负责协调 |
| ViewModel | 无 | 处理视图逻辑 |
| 数据绑定 | 手动 | 自动（使用 KVO/RAC） |

## 16. 什么是响应式编程？

响应式编程是一种编程范式，关注数据流和变化传播。

### 16.1 ReactiveCocoa 示例

```objc
// 监听文本框变化
[[self.textField.rac_textSignal 
    filter:^BOOL(NSString *text) {
        return text.length > 3;
    }]
    subscribeNext:^(NSString *text) {
        NSLog(@"输入：%@", text);
    }];
```

## 17. 什么是懒加载？

懒加载是一种延迟初始化技术，在需要时才创建对象。

### 17.1 实现方式

```objc
- (NSArray *)dataArray {
    if (_dataArray == nil) {
        _dataArray = @[@"1", @"2", @"3"];
    }
    return _dataArray;
}

// 使用懒加载属性
@property (nonatomic, strong, lazy) NSArray *lazyArray = ({
    @[@"1", @"2", @"3"];
});
```

### 17.2 优点

- 节省内存
- 提高启动速度
- 按需创建

## 18. 什么是属性（Property）？

Property 是 Objective-C 中用于封装实例变量的机制。

### 18.1 属性修饰符

```objc
// 原子性
@property (atomic) NSString *atomicName;      // 原子性（默认）
@property (nonatomic) NSString *nonAtomicName; // 非原子性

// 读写权限
@property (readonly) NSString *readonlyName;   // 只读
@property (readwrite) NSString *readwriteName; // 读写（默认）

// 内存管理
@property (strong) NSString *strongName;       // 强引用（默认）
@property (weak) id weakDelegate;              // 弱引用
@property (copy) NSString *copyName;           // 拷贝
@property (assign) NSInteger assignValue;      // 直接赋值
@property (retain) NSString *retainName;       // 保留（MRC）
```

### 18.2 属性自动合成

```objc
// 自动生成 getter/setter 和实例变量
@property (nonatomic, strong) NSString *name;
// 等价于
- (void)setName:(NSString *)name;
- (NSString *)name;
NSString *_name;
```

## 19. 什么是 SEL 和 IMP？

### 19.1 SEL（选择器）

SEL 是方法选择器，表示方法的名称。

```objc
SEL selector = @selector(doSomething);
if ([self respondsToSelector:selector]) {
    [self performSelector:selector];
}
```

### 19.2 IMP（方法实现）

IMP 是指向方法实现的函数指针。

```objc
IMP imp = [self methodForSelector:@selector(doSomething)];
void (*func)(id, SEL) = (void *)imp;
func(self, @selector(doSomething));
```

## 20. 什么是 id 类型？

`id` 是 Objective-C 中的通用对象类型，可以指向任何对象。

### 20.1 特点

- 动态类型，编译时不检查类型
- 可以指向任何对象
- 不需要类型转换

### 20.2 代码示例

```objc
id object = @"String";
object = @[@1, @2, @3];
object = [[NSObject alloc] init];

// 运行时检查类型
if ([object isKindOfClass:[NSString class]]) {
    NSString *str = (NSString *)object;
}
```

## 21. 什么是 instancetype？

`instancetype` 是 Objective-C 的关键字，表示返回调用该方法的类的实例。

### 21.1 与 id 的区别

```objc
// 使用 id
+ (id)createObject {
    return [[self alloc] init];
}
// 返回类型是 id，需要类型转换

// 使用 instancetype
+ (instancetype)createObject {
    return [[self alloc] init];
}
// 返回类型是调用类的类型，不需要类型转换
```

## 22. 什么是 @synthesize 和 @dynamic？

### 22.1 @synthesize

`@synthesize` 用于指定属性对应的实例变量名。

```objc
@synthesize name = _customName;
// 将 name 属性关联到 _customName 实例变量
```

### 22.2 @dynamic

`@dynamic` 告诉编译器不要自动生成 getter/setter，需要手动实现。

```objc
@dynamic name;
// 需要手动实现 -name 和 -setName: 方法
```

## 23. 什么是 @autoreleasepool？

`@autoreleasepool` 用于创建自动释放池，管理自动释放的对象。

### 23.1 基本用法

```objc
@autoreleasepool {
    NSString *str = [NSString stringWithFormat:@"Hello %@", @"World"];
    // str 会被添加到自动释放池
}
// 自动释放池结束时，str 会被释放
```

### 23.2 应用场景

- 循环中创建大量临时对象
- 主线程 RunLoop 的每个循环
- 子线程需要及时释放对象

## 24. 什么是 @property 的 copy 和 strong？

### 24.1 copy

`copy` 会创建对象的副本，适用于不可变对象。

```objc
@property (nonatomic, copy) NSString *name;

// 使用 copy
NSMutableString *mutableStr = [NSMutableString stringWithString:@"Hello"];
person.name = mutableStr;
[mutableStr appendString:@" World"];
// person.name 仍然是 "Hello"，因为 copy 创建了副本
```

### 24.2 strong

`strong` 是强引用，适用于可变对象。

```objc
@property (nonatomic, strong) NSMutableArray *items;

// 使用 strong
NSMutableArray *array = [NSMutableArray array];
person.items = array;
[array addObject:@"1"];
// person.items 也会包含 "1"，因为是同一个对象
```

## 25. 什么是方法交换（Method Swizzling）？

方法交换是 Runtime 的特性，可以在运行时交换两个方法的实现。

### 25.1 基本用法

```objc
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(swizzled_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)swizzled_viewWillAppear:(BOOL)animated {
    [self swizzled_viewWillAppear:animated]; // 实际调用原方法
    NSLog(@"viewWillAppear 被调用");
}
```

## 26. 什么是 Associated Objects（关联对象）？

关联对象允许在运行时为对象添加属性，常用于 Category。

### 26.1 基本用法

```objc
// 添加关联对象
objc_setAssociatedObject(self, &key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

// 获取关联对象
id value = objc_getAssociatedObject(self, &key);

// 移除关联对象
objc_setAssociatedObject(self, &key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
```

### 26.2 关联策略

- `OBJC_ASSOCIATION_ASSIGN`：弱引用
- `OBJC_ASSOCIATION_RETAIN_NONATOMIC`：强引用，非原子
- `OBJC_ASSOCIATION_COPY_NONATOMIC`：拷贝，非原子
- `OBJC_ASSOCIATION_RETAIN`：强引用，原子
- `OBJC_ASSOCIATION_COPY`：拷贝，原子

## 27. 什么是消息转发（Message Forwarding）？

消息转发是 Objective-C 的运行时机制，当对象无法响应消息时，会触发消息转发流程。

### 27.1 转发流程

1. `+resolveInstanceMethod:` 或 `+resolveClassMethod:`
2. `-forwardingTargetForSelector:`
3. `-methodSignatureForSelector:` 和 `-forwardInvocation:`

### 27.2 代码示例

```objc
// 第一步：动态添加方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(dynamicMethod)) {
        class_addMethod(self, sel, (IMP)dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

// 第二步：转发给其他对象
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(forwardMethod)) {
        return self.otherObject;
    }
    return [super forwardingTargetForSelector:aSelector];
}

// 第三步：完整转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(fullForwardMethod)) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (anInvocation.selector == @selector(fullForwardMethod)) {
        [anInvocation invokeWithTarget:self.otherObject];
    } else {
        [super forwardInvocation:anInvocation];
    }
}
```

## 28. 什么是类簇（Class Cluster）？

类簇是一种设计模式，使用抽象基类隐藏具体的实现类。

### 28.1 常见类簇

- `NSString`：实际返回 `__NSCFString`、`NSTaggedPointerString` 等
- `NSArray`：实际返回 `__NSArrayI`、`__NSArrayM` 等
- `NSNumber`：实际返回 `__NSCFNumber`、`NSTaggedPointerString` 等

### 28.2 代码示例

```objc
NSString *str1 = @"Hello"; // NSTaggedPointerString
NSString *str2 = [NSString stringWithFormat:@"Hello %@", @"World"]; // __NSCFString
NSArray *array = @[@1, @2]; // __NSArrayI
```

## 29. 什么是 Tagged Pointer？

Tagged Pointer 是苹果的优化技术，将小对象直接存储在指针中，而不是堆上。

### 29.1 特点

- 小对象（如小字符串、小数字）直接存储在指针中
- 不需要分配堆内存
- 提高性能，减少内存占用

### 29.2 判断方式

```objc
NSString *str = @"Hello";
NSLog(@"%p", str); // 如果是指针值很大，可能是 Tagged Pointer
```

## 30. iOS 基础知识的常见面试题总结

1. **Objective-C 和 Swift 的区别？** - 动态 vs 静态、类型安全、语法风格
2. **什么是面向对象编程？** - 封装、继承、多态、抽象
3. **iOS 应用的生命周期？** - Not Running、Inactive、Active、Background、Suspended
4. **ViewController 的生命周期？** - viewDidLoad、viewWillAppear、viewDidAppear 等
5. **Category 和 Extension 的区别？** - 公开 vs 私有、添加属性
6. **什么是 Protocol？** - 定义方法集合，类可以遵循
7. **Delegate 和 Notification 的区别？** - 一对一 vs 一对多
8. **什么是单例模式？** - 确保唯一实例，全局访问
9. **MVC 和 MVVM 的区别？** - Controller 的职责不同
10. **属性的修饰符有哪些？** - atomic/nonatomic、strong/weak/copy/assign
11. **什么是 SEL 和 IMP？** - 方法选择器和实现指针
12. **id 和 instancetype 的区别？** - 动态类型 vs 返回类型推断
13. **copy 和 strong 的区别？** - 创建副本 vs 强引用
14. **什么是方法交换？** - 运行时交换方法实现
15. **什么是关联对象？** - 运行时添加属性
16. **消息转发的流程？** - resolveInstanceMethod、forwardingTargetForSelector、forwardInvocation
17. **什么是类簇？** - 抽象基类隐藏实现
18. **什么是 Tagged Pointer？** - 小对象存储在指针中

