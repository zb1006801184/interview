# iOS 面试题 - Block

## 1. 什么是 Block？

Block 是 iOS 开发中一种封装了函数调用以及调用环境的 Objective-C 对象。它是 C 语言的扩展，可以理解为"带有自动变量（局部变量）的匿名函数"。

Block 的语法：
```objc
^返回值类型(参数列表) { 表达式 }
```

示例：
```objc
// 无返回值、无参数的 Block
void (^simpleBlock)(void) = ^{
    NSLog(@"这是一个简单的 Block");
};

// 有返回值、有参数的 Block
int (^addBlock)(int, int) = ^int(int a, int b) {
    return a + b;
};

// 调用 Block
simpleBlock();
int result = addBlock(3, 5); // result = 8
```

## 2. Block 的类型有哪些？

根据 Block 在内存中的位置，可以分为三种类型：

### 2.1 NSGlobalBlock（全局 Block）
- 存储在全局数据区
- 没有捕获任何外部变量
- 生命周期与程序相同

```objc
void (^globalBlock)(void) = ^{
    NSLog(@"全局 Block");
};
NSLog(@"%@", globalBlock); // <__NSGlobalBlock__: 0x...>
```

### 2.2 NSStackBlock（栈 Block）
- 存储在栈上
- 捕获了外部变量
- 在 ARC 环境下很少见，因为会被自动复制到堆上

```objc
// MRC 环境下
int value = 10;
void (^stackBlock)(void) = ^{
    NSLog(@"%d", value);
};
NSLog(@"%@", stackBlock); // <__NSStackBlock__: 0x...>
```

### 2.3 NSMallocBlock（堆 Block）
- 存储在堆上
- 由栈 Block 复制而来
- 需要手动管理内存（MRC）或由 ARC 自动管理

```objc
int value = 10;
void (^heapBlock)(void) = ^{
    NSLog(@"%d", value);
};
void (^copiedBlock)(void) = [heapBlock copy];
NSLog(@"%@", copiedBlock); // <__NSMallocBlock__: 0x...>
```

## 3. Block 如何捕获变量？

Block 在定义时会捕获外部变量，不同类型的变量捕获方式不同：

### 3.1 局部变量（自动变量）
- **值捕获**：捕获变量的值，在 Block 内部不能修改
- 捕获时机：Block 定义时

```objc
int value = 10;
void (^block)(void) = ^{
    NSLog(@"%d", value); // 捕获的是 value 的值 10
    // value = 20; // 编译错误：不能修改捕获的变量
};
value = 20; // 修改外部变量不影响 Block 内部的值
block(); // 输出：10
```

### 3.2 静态变量和全局变量
- **指针捕获**：捕获变量的地址，可以修改
- 不需要使用 `__block` 修饰符

```objc
static int staticValue = 10;
void (^block)(void) = ^{
    staticValue = 20; // 可以修改
    NSLog(@"%d", staticValue);
};
block(); // 输出：20
```

### 3.3 对象类型变量
- **强引用捕获**：默认是强引用，可能导致循环引用
- 可以使用 `__weak` 或 `__unsafe_unretained` 避免循环引用

```objc
// 强引用捕获（可能导致循环引用）
self.block = ^{
    NSLog(@"%@", self.name); // 强引用 self
};

// 弱引用捕获（避免循环引用）
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};
```

## 4. __block 修饰符的作用？

`__block` 修饰符用于让 Block 可以修改捕获的局部变量（自动变量）。

### 4.1 基本用法

```objc
__block int value = 10;
void (^block)(void) = ^{
    value = 20; // 可以修改
    NSLog(@"%d", value);
};
block(); // 输出：20
NSLog(@"%d", value); // 输出：20，外部变量也被修改
```

### 4.2 __block 的实现原理

使用 `__block` 修饰的变量会被包装成一个结构体（`__Block_byref_value_0`），Block 捕获的是这个结构体的指针，所以可以修改原变量的值。

```objc
// 编译器转换后的伪代码
struct __Block_byref_value_0 {
    void *__isa;
    __Block_byref_value_0 *__forwarding;
    int value;
};

__Block_byref_value_0 value = {
    0,
    &value,
    10
};
```

### 4.3 __block 与对象类型

```objc
__block NSObject *obj = [[NSObject alloc] init];
void (^block)(void) = ^{
    obj = [[NSObject alloc] init]; // 可以重新赋值
    NSLog(@"%@", obj);
};
```

## 5. Block 的内存管理？

### 5.1 MRC 环境下的内存管理

```objc
// Block 的 copy 操作
void (^block)(void) = ^{
    NSLog(@"Block");
};

// 栈 Block 需要 copy 到堆上才能保存
void (^heapBlock)(void) = [block copy];

// 使用完毕后需要 release
[heapBlock release];
```

**MRC 下需要 copy 的情况**：
- Block 作为函数返回值
- Block 赋值给 `__strong` 修饰的变量
- Block 作为 Cocoa API 中方法名含有 `usingBlock` 的参数
- Block 作为 GCD API 的参数

### 5.2 ARC 环境下的内存管理

ARC 环境下，编译器会自动处理 Block 的内存管理：
- 栈 Block 赋值给强引用变量时，会自动执行 copy 操作
- Block 从栈复制到堆时，会 retain 捕获的对象
- Block 释放时，会 release 捕获的对象

```objc
// ARC 下自动管理
void (^block)(void) = ^{
    NSLog(@"Block");
}; // 自动复制到堆上
```

## 6. Block 的循环引用问题？

### 6.1 什么是循环引用？

当 Block 捕获了对象，而该对象又强引用了这个 Block，就会形成循环引用，导致内存泄漏。

```objc
// 循环引用示例
@interface ViewController ()
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

### 6.2 如何避免循环引用？

#### 方法1：使用 __weak

```objc
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};
```

#### 方法2：使用 __unsafe_unretained

```objc
__unsafe_unretained typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};
```

**注意**：`__unsafe_unretained` 不会将对象置为 nil，如果对象已释放，访问会导致野指针崩溃。

#### 方法3：在 Block 执行完后置 nil

```objc
__block ViewController *blockSelf = self;
self.block = ^{
    NSLog(@"%@", blockSelf.name);
    blockSelf = nil; // 打破循环引用
};
```

#### 方法4：使用 @weakify 和 @strongify（ReactiveCocoa 宏）

```objc
@weakify(self);
self.block = ^{
    @strongify(self);
    if (!self) return;
    NSLog(@"%@", self.name);
};
```

### 6.3 不会造成循环引用的情况

```objc
// 情况1：Block 没有被对象强引用
- (void)test {
    void (^block)(void) = ^{
        NSLog(@"%@", self.name); // 不会循环引用，因为 block 是局部变量
    };
    block();
}

// 情况2：Block 作为参数传递，执行完就释放
- (void)test {
    [self doSomething:^{
        NSLog(@"%@", self.name); // 不会循环引用
    }];
}

// 情况3：使用 weak 修饰的属性
@property (nonatomic, weak) void (^block)(void);
```

## 7. Block 的实现原理？

### 7.1 Block 的底层结构

Block 在底层被编译成一个结构体：

```objc
// 原始代码
int value = 10;
void (^block)(void) = ^{
    NSLog(@"%d", value);
};

// 编译器转换后的结构（简化版）
struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr; // Block 执行函数的指针
};

struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0 *Desc;
    int value; // 捕获的变量
};

// Block 描述信息
struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
    void (*dispose)(struct __main_block_impl_0*);
};
```

### 7.2 Block 的 isa 指针

Block 的 isa 指针指向对应的类：
- `_NSConcreteStackBlock`：栈 Block
- `_NSConcreteGlobalBlock`：全局 Block
- `_NSConcreteMallocBlock`：堆 Block

### 7.3 Block 的 copy 操作

当 Block 从栈复制到堆时：
1. 在堆上分配内存
2. 将栈 Block 的内容复制到堆
3. 将 isa 指针指向 `_NSConcreteMallocBlock`
4. 如果捕获了对象，会调用 `retain` 增加引用计数
5. 如果使用了 `__block` 变量，也会将 `__block` 变量复制到堆

## 8. Block 与函数指针的区别？

| 特性 | Block | 函数指针 |
|------|-------|----------|
| 语法 | `^返回值类型(参数) { }` | `返回值类型 (*指针名)(参数)` |
| 捕获变量 | 可以捕获外部变量 | 不能捕获外部变量 |
| 内存管理 | 需要管理内存（MRC） | 不需要特殊管理 |
| 类型 | Objective-C 对象 | C 语言特性 |
| 调用方式 | `block()` | `(*pointer)()` 或 `pointer()` |

```objc
// 函数指针
int (*addFunc)(int, int) = add;
int result = addFunc(3, 5);

// Block
int (^addBlock)(int, int) = ^int(int a, int b) {
    return a + b;
};
int result = addBlock(3, 5);
```

## 9. Block 的应用场景？

### 9.1 回调函数

```objc
// 网络请求回调
[networkManager requestWithURL:url completion:^(NSData *data, NSError *error) {
    if (error) {
        NSLog(@"请求失败：%@", error);
    } else {
        NSLog(@"请求成功");
    }
}];
```

### 9.2 数组遍历

```objc
NSArray *array = @[@1, @2, @3, @4, @5];
[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSLog(@"索引 %lu: %@", (unsigned long)idx, obj);
    if (idx == 2) {
        *stop = YES; // 停止遍历
    }
}];
```

### 9.3 动画

```objc
[UIView animateWithDuration:0.3 animations:^{
    self.view.alpha = 0.5;
} completion:^(BOOL finished) {
    NSLog(@"动画完成");
}];
```

### 9.4 GCD

```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 后台执行任务
    dispatch_async(dispatch_get_main_queue(), ^{
        // 回到主线程更新 UI
    });
});
```

### 9.5 通知观察者

```objc
[[NSNotificationCenter defaultCenter] addObserverForName:@"TestNotification"
                                                  object:nil
                                                   queue:[NSOperationQueue mainQueue]
                                              usingBlock:^(NSNotification *note) {
    NSLog(@"收到通知：%@", note);
}];
```

## 10. Block 作为属性时如何声明？

```objc
// 方式1：使用 typedef（推荐）
typedef void (^CompletionBlock)(NSData *data, NSError *error);

@interface NetworkManager : NSObject
@property (nonatomic, copy) CompletionBlock completionBlock;
@end

// 方式2：直接声明
@interface ViewController : NSObject
@property (nonatomic, copy) void (^block)(void);
@property (nonatomic, copy) int (^addBlock)(int, int);
@end
```

**注意**：Block 属性应该使用 `copy` 修饰符，确保 Block 被复制到堆上。

## 11. Block 中修改外部变量的几种方式？

### 11.1 使用 __block

```objc
__block int value = 10;
void (^block)(void) = ^{
    value = 20;
};
```

### 11.2 使用静态变量

```objc
static int value = 10;
void (^block)(void) = ^{
    value = 20;
};
```

### 11.3 使用全局变量

```objc
int globalValue = 10;
void (^block)(void) = ^{
    globalValue = 20;
};
```

### 11.4 使用指针

```objc
NSMutableArray *array = [NSMutableArray array];
void (^block)(void) = ^{
    [array addObject:@1]; // 可以修改数组内容
    // array = [NSMutableArray array]; // 不能重新赋值
};
```

## 12. Block 的变量捕获时机？

Block 在**定义时**捕获变量的值，而不是在调用时：

```objc
int value = 10;
void (^block)(void) = ^{
    NSLog(@"%d", value); // 捕获的是定义时的值 10
};
value = 20; // 修改外部变量
block(); // 输出：10，而不是 20
```

使用 `__block` 后，捕获的是变量的地址：

```objc
__block int value = 10;
void (^block)(void) = ^{
    NSLog(@"%d", value); // 捕获的是变量的地址
};
value = 20;
block(); // 输出：20
```

## 13. Block 在 ARC 和 MRC 下的区别？

### 13.1 内存管理

- **MRC**：需要手动 `copy` 和 `release` Block
- **ARC**：编译器自动管理，栈 Block 赋值给强引用变量时自动 copy

### 13.2 循环引用处理

- **MRC**：可以使用 `__block` 打破循环引用
- **ARC**：`__block` 也会强引用对象，需要使用 `__weak`

```objc
// MRC 下可以使用 __block 打破循环引用
__block ViewController *blockSelf = self;
self.block = ^{
    NSLog(@"%@", blockSelf.name);
    blockSelf = nil;
};

// ARC 下 __block 也会强引用，需要使用 __weak
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};
```

## 14. Block 的三种类型如何判断？

```objc
// 全局 Block：没有捕获外部变量
void (^globalBlock)(void) = ^{
    NSLog(@"全局 Block");
};
NSLog(@"%@", [globalBlock class]); // __NSGlobalBlock__

// 栈 Block：捕获了外部变量，但没有被强引用（ARC 下很少见）
int value = 10;
void (^stackBlock)(void) = ^{
    NSLog(@"%d", value);
};
// 在 MRC 下可能是 __NSStackBlock__

// 堆 Block：栈 Block 被 copy 后
void (^heapBlock)(void) = [stackBlock copy];
NSLog(@"%@", [heapBlock class]); // __NSMallocBlock__

// ARC 下，赋值给强引用变量会自动 copy
void (^autoHeapBlock)(void) = ^{
    NSLog(@"%d", value);
};
NSLog(@"%@", [autoHeapBlock class]); // __NSMallocBlock__
```

## 15. Block 中访问 self 的几种情况？

```objc
// 情况1：直接访问 self（可能循环引用）
self.block = ^{
    NSLog(@"%@", self.name);
};

// 情况2：通过 weakSelf 访问（避免循环引用）
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf.name);
};

// 情况3：通过 weak-strong dance（推荐）
__weak typeof(self) weakSelf = self;
self.block = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    NSLog(@"%@", strongSelf.name);
};

// 情况4：访问 self 的属性（等同于访问 self）
self.block = ^{
    NSLog(@"%@", _name); // 也会强引用 self
};
```

## 16. Block 作为方法参数时如何声明？

```objc
// 方法定义
- (void)requestWithURL:(NSString *)url 
            completion:(void (^)(NSData *data, NSError *error))completion;

// 方法调用
[self requestWithURL:@"http://example.com" completion:^(NSData *data, NSError *error) {
    if (error) {
        NSLog(@"错误：%@", error);
    } else {
        NSLog(@"成功");
    }
}];

// 使用 typedef 更清晰
typedef void (^CompletionHandler)(NSData *data, NSError *error);
- (void)requestWithURL:(NSString *)url completion:(CompletionHandler)completion;
```

## 17. Block 中捕获 C 数组的问题？

Block 不能直接捕获 C 数组，因为 C 数组是指针，Block 无法确定数组的大小。

```objc
// 错误：不能直接捕获 C 数组
int array[5] = {1, 2, 3, 4, 5};
void (^block)(void) = ^{
    // NSLog(@"%d", array[0]); // 编译错误
};

// 解决方案1：使用指针
int *arrayPtr = array;
void (^block1)(void) = ^{
    NSLog(@"%d", arrayPtr[0]);
};

// 解决方案2：使用 NSArray
NSArray *nsArray = @[@1, @2, @3, @4, @5];
void (^block2)(void) = ^{
    NSLog(@"%@", nsArray[0]);
};
```

## 18. Block 的 copy 和 retain 的区别？

- **retain**：只是增加引用计数，不会改变 Block 的类型（栈 Block 还是栈 Block）
- **copy**：将栈 Block 复制到堆上，变成堆 Block

```objc
// MRC 下
void (^stackBlock)(void) = ^{
    NSLog(@"Block");
};

// retain 不会改变类型
void (^retainedBlock)(void) = [stackBlock retain];
NSLog(@"%@", [retainedBlock class]); // 仍然是 __NSStackBlock__

// copy 会改变类型
void (^copiedBlock)(void) = [stackBlock copy];
NSLog(@"%@", [copiedBlock class]); // __NSMallocBlock__
```

## 19. Block 与代理（Delegate）的对比？

| 特性 | Block | Delegate |
|------|-------|----------|
| 语法简洁性 | 更简洁 | 相对繁琐 |
| 回调数量 | 适合单个回调 | 适合多个回调 |
| 代码位置 | 调用处附近 | 分散在不同方法 |
| 循环引用 | 容易产生 | 相对安全 |
| 可读性 | 简单场景更好 | 复杂场景更好 |

**使用建议**：
- 简单的单个回调：使用 Block
- 多个相关回调：使用 Delegate
- 需要取消或暂停：使用 Delegate

## 20. Block 的常见面试题总结

1. **什么是 Block？** - 带有自动变量的匿名函数，是 Objective-C 对象
2. **Block 有哪几种类型？** - NSGlobalBlock、NSStackBlock、NSMallocBlock
3. **Block 如何捕获变量？** - 局部变量值捕获，静态/全局变量指针捕获
4. **__block 的作用？** - 允许 Block 修改捕获的局部变量
5. **Block 的循环引用如何解决？** - 使用 __weak、__unsafe_unretained 或 __block（MRC）
6. **Block 在 ARC 和 MRC 下的区别？** - ARC 自动管理，MRC 需要手动 copy/release
7. **Block 作为属性用什么修饰符？** - 使用 copy
8. **Block 的实现原理？** - 编译成结构体，包含 isa 指针、函数指针、捕获的变量
9. **Block 与函数指针的区别？** - Block 可以捕获变量，是对象；函数指针不能捕获变量
10. **什么时候 Block 会从栈复制到堆？** - 赋值给强引用变量、作为返回值、作为参数传递给需要 copy 的 API

## 21. Block 的高级用法

### 21.1 Block 链式调用

```objc
typedef ViewController *(^ViewControllerBlock)(NSString *);

- (ViewControllerBlock)setTitle {
    return ^ViewController *(NSString *title) {
        self.title = title;
        return self;
    };
}

// 使用
[[[self setTitle](@"标题") setTitle](@"新标题");
```

### 21.2 Block 作为返回值

```objc
- (void (^)(void))createBlock {
    return ^{
        NSLog(@"返回的 Block");
    };
}

// 使用
void (^block)(void) = [self createBlock];
block();
```

### 21.3 Block 嵌套

```objc
void (^outerBlock)(void) = ^{
    void (^innerBlock)(void) = ^{
        NSLog(@"内部 Block");
    };
    innerBlock();
};
outerBlock();
```

### 21.4 Block 递归调用

```objc
typedef void (^RecursiveBlock)(int);

RecursiveBlock recursiveBlock;
recursiveBlock = ^(int n) {
    if (n > 0) {
        NSLog(@"%d", n);
        recursiveBlock(n - 1);
    }
};
recursiveBlock(5);
```

## 22. Block 的调试技巧

### 22.1 打印 Block 的类型

```objc
void (^block)(void) = ^{
    NSLog(@"Block");
};
NSLog(@"Block 类型：%@", [block class]);
NSLog(@"Block 描述：%@", block);
```

### 22.2 使用 Instruments 检测 Block 循环引用

使用 Xcode 的 Leaks 工具可以检测 Block 导致的循环引用。

### 22.3 使用 Clang 查看 Block 的实现

```bash
clang -rewrite-objc -fobjc-arc main.m
```

可以查看 Block 被编译后的 C++ 代码，了解 Block 的底层实现。

