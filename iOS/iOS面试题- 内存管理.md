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

## 4. 属性修饰词详解

属性修饰词（Property Attributes）是 Objective-C 中用于控制属性内存管理语义的关键字。正确使用属性修饰词是避免内存泄漏和循环引用的基础。

### 4.1 assign

`assign` 用于基本数据类型（如 `int`、`float`、`BOOL`、`NSInteger` 等），不改变对象的引用计数。

#### 4.1.1 基本概念

- 不增加引用计数
- 不持有对象
- 适用于基本数据类型
- 对象类型使用 `assign` 可能导致野指针

#### 4.1.2 代码示例

```objc
// 基本数据类型使用 assign
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) CGFloat height;

// 对象类型使用 assign（不推荐，可能导致野指针）
@property (nonatomic, assign) NSString *name; // ⚠️ 危险：对象释放后成为野指针
```

#### 4.1.3 使用场景

- ✅ 基本数据类型（`int`、`float`、`BOOL`、`NSInteger`、`CGFloat` 等）
- ✅ 结构体（`CGRect`、`CGSize`、`CGPoint` 等）
- ❌ 对象类型（应使用 `strong`、`weak` 或 `copy`）

#### 4.1.4 注意事项

- 对象类型使用 `assign` 时，对象释放后属性不会自动置为 `nil`，访问会导致崩溃
- ARC 环境下，对象类型的默认修饰词是 `strong`，不是 `assign`

### 4.2 strong

`strong` 是 ARC 环境下的强引用修饰词，会增加对象的引用计数，确保对象在属性持有期间不会被释放。

#### 4.2.1 基本概念

- 增加对象的引用计数（retainCount + 1）
- 持有对象，对象不会被释放
- ARC 环境下对象类型的默认修饰词
- 可能导致循环引用

#### 4.2.2 代码示例

```objc
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) UIView *customView;

- (void)example {
    NSString *str = [[NSString alloc] initWithString:@"Hello"]; // retainCount = 1
    self.name = str; // retainCount = 2（strong 会 retain）
    // str 作用域结束，retainCount = 1
    // self.name 仍然持有对象，对象不会被释放
}
```

#### 4.2.3 使用场景

- ✅ 对象类型的默认选择
- ✅ 需要持有对象的所有权
- ✅ 可变对象（`NSMutableArray`、`NSMutableString` 等）
- ❌ 可能导致循环引用的场景（应使用 `weak`）

#### 4.2.4 注意事项

- 可能导致循环引用，需要谨慎使用
- 与 MRC 下的 `retain` 语义相同

### 4.3 weak

`weak` 是弱引用修饰词，不会增加对象的引用计数，当对象被释放时，弱引用会自动置为 `nil`。

#### 4.3.1 基本概念

- 不增加对象的引用计数
- 不持有对象
- 对象释放时自动置为 `nil`，避免野指针
- 用于打破循环引用

#### 4.3.2 代码示例

```objc
@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) UIView *parentView;

- (void)example {
    NSObject *obj = [[NSObject alloc] init]; // retainCount = 1
    self.delegate = obj; // retainCount 仍然是 1（weak 不增加引用计数）
    // obj 作用域结束，retainCount = 0, 对象被释放
    // self.delegate 自动变为 nil，不会崩溃
}
```

#### 4.3.3 使用场景

- ✅ Delegate 模式（避免循环引用）
- ✅ 父子关系中的父对象引用
- ✅ Block 中避免循环引用
- ✅ 观察者模式
- ❌ 需要持有对象所有权的场景（应使用 `strong`）

#### 4.3.4 注意事项

- 弱引用对象可能随时变为 `nil`，使用前需要判断
- 性能略低于 `strong`（需要维护 SideTable）
- iOS 5.0+ 才支持

### 4.4 copy

`copy` 会创建对象的副本，适用于不可变对象，确保属性持有的是对象的独立副本。

#### 4.4.1 基本概念

- 创建对象的副本（调用 `copy` 方法）
- 持有副本，不持有原对象
- 防止外部修改影响属性值
- 适用于不可变对象

#### 4.4.2 代码示例

```objc
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *items;

- (void)example {
    NSMutableString *mutableStr = [NSMutableString stringWithString:@"Hello"];
    self.name = mutableStr; // 会调用 copy，创建不可变副本
    [mutableStr appendString:@" World"]; // 修改原对象
    // self.name 仍然是 "Hello"，因为 copy 创建了独立副本
}
```

#### 4.4.3 使用场景

- ✅ 不可变对象（`NSString`、`NSArray`、`NSDictionary`、`NSSet` 等）
- ✅ 需要防止外部修改的场景
- ✅ Block 属性（`copy` 是 Block 的标准修饰词）
- ❌ 可变对象（应使用 `strong`）

#### 4.4.4 注意事项

- 可变对象使用 `copy` 会得到不可变副本
- 性能略低于 `strong`（需要创建副本）
- 自定义对象需要实现 `NSCopying` 协议

#### 4.4.5 copy 的实现原理

```objc
// copy 属性的 setter 方法实现（简化）
- (void)setName:(NSString *)name {
    if (_name != name) {
        [_name release]; // MRC 下
        _name = [name copy]; // 调用 copy 方法创建副本
    }
}
```

### 4.5 retain

`retain` 是 MRC 环境下的强引用修饰词，等同于 ARC 下的 `strong`。

#### 4.5.1 基本概念

- MRC 环境下使用
- 增加对象的引用计数（调用 `retain` 方法）
- 持有对象
- ARC 环境下已废弃，使用 `strong` 代替

#### 4.5.2 代码示例

```objc
// MRC 下
@property (nonatomic, retain) NSString *name;

// ARC 下（retain 等同于 strong）
@property (nonatomic, retain) NSString *name; // ⚠️ 不推荐，应使用 strong
@property (nonatomic, strong) NSString *name; // ✅ 推荐
```

#### 4.5.3 使用场景

- ✅ MRC 环境下的对象类型
- ❌ ARC 环境下应使用 `strong`

#### 4.5.4 注意事项

- ARC 环境下 `retain` 和 `strong` 语义相同，但推荐使用 `strong`
- MRC 环境下需要手动管理内存

### 4.6 unsafe_unretained

`unsafe_unretained` 是不安全的弱引用，不会增加引用计数，但对象释放后不会自动置为 `nil`。

#### 4.6.1 基本概念

- 不增加对象的引用计数
- 不持有对象
- 对象释放后不会自动置为 `nil`（可能成为野指针）
- 性能略高于 `weak`

#### 4.6.2 代码示例

```objc
@property (nonatomic, unsafe_unretained) id delegate;

- (void)example {
    NSObject *obj = [[NSObject alloc] init]; // retainCount = 1
    self.delegate = obj; // retainCount 仍然是 1
    // obj 作用域结束，retainCount = 0, 对象被释放
    // self.delegate 仍然是原来的地址（野指针），访问可能崩溃
}
```

#### 4.6.3 使用场景

- ✅ 性能要求极高的场景
- ✅ 确定对象生命周期不会提前释放
- ✅ 兼容 iOS 4（`weak` 需要 iOS 5+）
- ❌ 一般场景应使用 `weak`（更安全）

#### 4.6.4 注意事项

- 对象释放后可能成为野指针，访问会导致崩溃
- 需要确保对象生命周期足够长
- 一般不推荐使用，优先使用 `weak`

### 4.7 属性修饰词对比表

| 修饰词 | 引用计数 | 自动置 nil | 适用场景 | ARC/MRC | 安全性 |
|--------|----------|------------|----------|---------|--------|
| `assign` | 不增加 | 否 | 基本数据类型 | 两者 | 安全（基本类型） |
| `strong` | 增加 | 否 | 对象类型（默认） | ARC | 安全 |
| `weak` | 不增加 | 是 | 避免循环引用 | ARC | 安全 |
| `copy` | 增加（副本） | 否 | 不可变对象 | 两者 | 安全 |
| `retain` | 增加 | 否 | 对象类型 | MRC | 安全 |
| `unsafe_unretained` | 不增加 | 否 | 特殊场景 | ARC | 不安全 |

### 4.8 属性修饰词选择原则

#### 4.8.1 基本数据类型

```objc
// ✅ 使用 assign
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) CGFloat height;
```

#### 4.8.2 对象类型

```objc
// ✅ 不可变对象使用 copy
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *items;

// ✅ 可变对象使用 strong
@property (nonatomic, strong) NSMutableArray *mutableItems;

// ✅ 一般对象使用 strong（默认）
@property (nonatomic, strong) UIView *customView;
```

#### 4.8.3 避免循环引用

```objc
// ✅ Delegate 使用 weak
@property (nonatomic, weak) id<CustomDelegate> delegate;

// ✅ 父子关系中的父对象引用使用 weak
@property (nonatomic, weak) UIView *parentView;

// ✅ Block 使用 copy（同时注意 Block 内部的循环引用）
@property (nonatomic, copy) void (^completionBlock)(void);
```

#### 4.8.4 选择流程图

```
对象类型？
├─ 否 → 使用 assign
└─ 是
   ├─ 可能导致循环引用？
   │  ├─ 是 → 使用 weak
   │  └─ 否
   │     ├─ 不可变对象（NSString、NSArray 等）？
   │     │  ├─ 是 → 使用 copy
   │     │  └─ 否 → 使用 strong
   │     └─ 可变对象 → 使用 strong
```

### 4.9 常见错误和注意事项

#### 4.9.1 错误示例

```objc
// ❌ 错误1：对象类型使用 assign
@property (nonatomic, assign) NSString *name; // 可能导致野指针

// ❌ 错误2：Delegate 使用 strong
@property (nonatomic, strong) id<CustomDelegate> delegate; // 可能导致循环引用

// ❌ 错误3：可变对象使用 copy
@property (nonatomic, copy) NSMutableArray *items; // 会得到不可变副本

// ❌ 错误4：不可变对象使用 strong（可能被外部修改）
@property (nonatomic, strong) NSString *name; // 应该使用 copy
```

#### 4.9.2 正确示例

```objc
// ✅ 正确1：基本数据类型使用 assign
@property (nonatomic, assign) NSInteger age;

// ✅ 正确2：不可变对象使用 copy
@property (nonatomic, copy) NSString *name;

// ✅ 正确3：可变对象使用 strong
@property (nonatomic, strong) NSMutableArray *items;

// ✅ 正确4：Delegate 使用 weak
@property (nonatomic, weak) id<CustomDelegate> delegate;

// ✅ 正确5：Block 使用 copy
@property (nonatomic, copy) void (^completionBlock)(void);
```

## 5. 什么是强引用（Strong Reference）？

强引用会增加对象的引用计数，只要存在强引用，对象就不会被释放。

### 5.1 代码示例

```objc
@property (nonatomic, strong) NSString *name; // 强引用

- (void)example {
    NSString *str = [[NSString alloc] initWithString:@"Hello"]; // retainCount = 1
    self.name = str; // retainCount = 2
    // str 作用域结束，retainCount = 1
    // self.name 仍然持有对象，对象不会被释放
}
```

## 6. 什么是弱引用（Weak Reference）？

弱引用不会增加对象的引用计数，当对象被释放时，弱引用会自动置为 nil。

### 6.1 代码示例

```objc
@property (nonatomic, weak) id delegate; // 弱引用

- (void)example {
    NSObject *obj = [[NSObject alloc] init]; // retainCount = 1
    self.delegate = obj; // retainCount 仍然是 1
    // obj 作用域结束，retainCount = 0, 对象被释放
    // self.delegate 自动变为 nil
}
```

### 6.2 弱引用的实现原理

弱引用通过 SideTable 实现，当对象被释放时，会遍历所有弱引用，将其置为 nil。

#### 6.2.1 SideTable 的基本结构

SideTable 是用于存储对象额外信息的辅助表，主要包含：
- **weak_table_t**：弱引用表，存储所有指向该对象的弱引用
- **RefcountMap**：引用计数表（在某些情况下使用）
- **spinlock_t**：自旋锁，保证线程安全

#### 6.2.2 弱引用的存储机制

当创建一个 weak 引用时，系统会执行以下流程：

1. **获取对象的 SideTable**
   - 通过对象地址的哈希值找到对应的 SideTable
   - iOS 系统维护多个 SideTable（通常是 8 个），通过哈希分散存储，减少锁竞争

2. **在 weak_table 中查找或创建 weak_entry**
   - `weak_table_t` 是一个哈希表
   - 每个 `weak_entry_t` 对应一个被弱引用的对象
   - `weak_entry_t` 内部使用数组或哈希表存储所有指向该对象的弱引用指针地址

3. **将弱引用指针地址添加到 weak_entry**
   - 记录弱引用变量的地址（如 `&weakObj`）
   - 不增加对象的引用计数

#### 6.2.3 对象释放时的清理过程

当对象的引用计数降为 0 时，系统会执行以下步骤：

```
1. 调用对象的 dealloc 方法
2. 在 dealloc 中调用 objc_destructInstance
3. 调用 clearDeallocating 函数
4. 从 SideTable 中获取 weak_table
5. 找到该对象对应的 weak_entry
6. 遍历 weak_entry 中所有的弱引用指针地址
7. 将每个弱引用指针指向的内容置为 nil
8. 从 weak_table 中移除该 weak_entry
9. 释放对象内存
```

#### 6.2.4 关键数据结构

```objc
// weak_table_t 结构（简化）
struct weak_table_t {
    weak_entry_t *weak_entries;        // 弱引用条目数组
    size_t num_entries;                // 条目数量
    uintptr_t mask;                    // 哈希表掩码
    uintptr_t max_hash_displacement;   // 最大哈希冲突
};

// weak_entry_t 结构（简化）
struct weak_entry_t {
    DisguisedPtr<objc_object> referent;  // 被弱引用的对象
    union {
        struct {
            weak_referrer_t *referrers;   // 弱引用指针数组
            uintptr_t out_of_line : 1;    // 是否使用动态数组
            uintptr_t num_refs : 63;      // 引用数量
            uintptr_t mask;               // 哈希表掩码
            uintptr_t max_hash_displacement;
        };
        struct {
            weak_referrer_t inline_referrers[WEAK_INLINE_COUNT]; // 内联数组（优化）
        };
    };
};
```

#### 6.2.5 性能优化

1. **内联数组优化**
   - 当弱引用数量 ≤ 4 时，使用内联数组 `inline_referrers`
   - 避免小对象分配额外内存，提高性能

2. **多个 SideTable**
   - 系统维护多个 SideTable（通常 8 个）
   - 通过对象地址哈希分散存储，减少锁竞争，提高并发性能

3. **哈希表存储**
   - 使用哈希表存储 weak_entry，提高查找效率

#### 6.2.6 线程安全

- 使用自旋锁（spinlock）保护 SideTable 的访问
- 保证多线程环境下 weak 引用的添加和清理是线程安全的

#### 6.2.7 总结

弱引用通过 SideTable 机制实现，具有以下特点：
- ✅ 不增加对象的引用计数
- ✅ 对象释放时自动将所有弱引用置为 nil，避免野指针
- ✅ 使用哈希表高效存储和查找弱引用
- ✅ 通过内联数组等优化减少内存开销
- ✅ 使用自旋锁保证线程安全

这是 ARC 中避免循环引用和野指针的核心机制。

## 7. 什么是循环引用？

循环引用是指两个或多个对象相互强引用，导致引用计数无法降为 0，对象无法释放。

### 7.1 循环引用示例

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

### 7.2 解决方案

```objc
// 使用弱引用
@property (nonatomic, weak) Person *friend; // 弱引用，打破循环
```

## 8. Block 的循环引用？

### 8.1 Block 循环引用示例

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

### 8.2 解决方案

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

## 9. Delegate 的循环引用？

### 9.1 问题示例

```objc
// 错误：使用 strong
@property (nonatomic, strong) id<CustomDelegate> delegate; // 可能导致循环引用
```

**循环引用的形成过程：**

当 delegate 使用 `strong` 修饰时，会形成以下循环引用链：

```
ViewController (委托方) 
    ↓ strong 引用
CustomView (代理方，持有 delegate)
    ↓ strong 引用 (如果 delegate 是 strong)
ViewController (委托方)
```

**具体示例：**

```objc
// 委托方：ViewController
@interface ViewController : UIViewController
@property (nonatomic, strong) CustomView *customView; // ViewController 强引用 CustomView
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.customView = [[CustomView alloc] init];
    self.customView.delegate = self; // 如果 delegate 是 strong，CustomView 强引用 ViewController
}
@end

// 代理方：CustomView
@interface CustomView : UIView
@property (nonatomic, strong) id<CustomDelegate> delegate; // ❌ 错误：使用 strong
@end

@implementation CustomView
// ...
@end
```

**循环引用链分析：**

1. **ViewController** 通过 `strong` 属性持有 **CustomView**（引用计数 +1）
2. **CustomView** 通过 `strong` 属性持有 **ViewController**（引用计数 +1）
3. 当 ViewController 想要释放时：
   - 需要先释放 CustomView（但 CustomView 被 self.customView 强引用）
   - CustomView 想要释放时，需要先释放 delegate（但 delegate 是 self，被 CustomView 强引用）
   - 形成循环：**ViewController ↔ CustomView**，两者都无法释放

**为什么使用 weak 可以解决？**

```objc
@property (nonatomic, weak) id<CustomDelegate> delegate; // ✅ 正确：使用 weak
```

使用 `weak` 后：
- **ViewController** 通过 `strong` 持有 **CustomView**
- **CustomView** 通过 `weak` 持有 **ViewController**（弱引用，不增加引用计数）
- 当 ViewController 释放时，CustomView 的 delegate 会自动置为 `nil`，不会阻止 ViewController 的释放
- 循环被打破：**ViewController → CustomView**（单向强引用）

**设计原则：**

在代理模式中，通常遵循以下原则：
- **委托方（如 ViewController）** 应该 `strong` 持有 **代理方（如 CustomView）**
- **代理方（如 CustomView）** 应该 `weak` 持有 **委托方（如 ViewController）**
- 这样形成的是单向强引用链，不会造成循环引用

### 9.2 解决方案

```objc
// 正确：使用 weak
@property (nonatomic, weak) id<CustomDelegate> delegate; // 弱引用，避免循环引用
```

## 10. NSTimer 的循环引用？

### 10.1 问题示例

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

### 10.2 解决方案

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

## 11. 什么是内存泄漏？

内存泄漏是指已分配的内存无法被释放，导致内存占用不断增加。

### 11.1 常见原因

- 循环引用
- 未释放的观察者（KVO、Notification）
- 未停止的定时器
- 未释放的 Core Foundation 对象

### 11.2 检测方法

- 使用 Instruments 的 Leaks 工具
- 使用 Xcode 的 Memory Graph Debugger
- 使用第三方工具（MLeaksFinder）
- **重写 dealloc 方法**：在对象的 `dealloc` 方法中添加日志或断点，如果对象被正确释放，`dealloc` 会被调用；如果存在内存泄漏，`dealloc` 不会被调用

#### 11.2.1 使用 dealloc 检测示例

```objc
- (void)dealloc {
    NSLog(@"✅ %@ 已释放", NSStringFromClass([self class]));
    // 如果这里没有执行，说明对象没有被释放，存在内存泄漏
}
```

**注意事项**：
- ARC 环境下不要调用 `[super dealloc]`
- 避免在 `dealloc` 中使用属性的访问器方法
- 避免在 `dealloc` 中将 `self` 作为参数传递

## 12. 什么是野指针？

野指针是指指向已释放内存的指针，访问野指针会导致崩溃。

### 12.1 示例

```objc
// MRC 下
NSObject *obj = [[NSObject alloc] init];
[obj release]; // 对象被释放
NSLog(@"%@", obj); // 访问野指针，可能崩溃
```

### 12.2 避免方法

- 释放后置为 nil：`obj = nil;`
- 使用 ARC（自动置为 nil）
- 使用弱引用（对象释放后自动置为 nil）

## 13. 什么是悬垂指针？

悬垂指针是指指向已释放内存的指针，与野指针类似，但通常指在对象释放后仍然持有的指针。

## 14. 什么是僵尸对象？

僵尸对象是指已经被释放但内存尚未被重新分配的对象。在调试时，可以启用 Zombie Objects 来检测对已释放对象的访问。

### 14.1 启用方法

在 Xcode 的 Scheme 中，Edit Scheme -> Run -> Diagnostics -> Enable Zombie Objects

## 15. 什么是 AutoreleasePool？

AutoreleasePool 是自动释放池，用于管理自动释放的对象。

### 15.1 工作原理

对象调用 `autorelease` 后，会被添加到当前的 AutoreleasePool 中。当 AutoreleasePool 被释放时，会对其中的所有对象调用 `release`。

### 15.2 代码示例

```objc
@autoreleasepool {
    NSString *str = [NSString stringWithFormat:@"Hello %@", @"World"];
    // str 调用 autorelease，被添加到池中
}
// 池释放时，str 被释放
```

### 15.3 应用场景

- 主线程 RunLoop 的每个循环
- 循环中创建大量临时对象
- 子线程需要及时释放对象

## 16. AutoreleasePool 的释放时机？

### 16.1 主线程

主线程的 RunLoop 在每个循环中会创建和释放 AutoreleasePool：
- RunLoop 进入时创建
- RunLoop 休眠前释放旧的，创建新的
- RunLoop 退出时释放

### 16.2 子线程

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

## 17. 什么是 Tagged Pointer？

Tagged Pointer 是苹果的优化技术，将小对象直接存储在指针中，而不是堆上。

### 17.1 特点

- 小对象（如小字符串、小数字）直接存储在指针中
- 不需要分配堆内存
- 不需要引用计数管理
- 提高性能，减少内存占用

### 17.2 示例

```objc
NSString *str1 = @"Hello"; // 可能是 Tagged Pointer
NSString *str2 = [NSString stringWithFormat:@"Hello %@", @"World"]; // 堆对象
```

## 18. 什么是 Copy-on-Write？

Copy-on-Write 是一种优化技术，只有在修改时才真正复制对象。

### 18.1 示例

```objc
NSMutableArray *array1 = [NSMutableArray arrayWithObjects:@1, @2, nil];
NSMutableArray *array2 = [array1 mutableCopy]; // 浅拷贝
// 此时两个数组可能共享内部存储
[array2 addObject:@3]; // 修改时才真正复制
```

## 19. 深拷贝和浅拷贝的区别？

### 19.1 浅拷贝（Shallow Copy）

只复制对象本身，不复制对象内部的引用对象。

```objc
NSArray *array1 = @[@1, @2, @3];
NSArray *array2 = [array1 copy]; // 浅拷贝
// array1 和 array2 指向不同的数组对象，但内部的元素是同一个对象
```

### 19.2 深拷贝（Deep Copy）

复制对象及其内部的所有引用对象。

```objc
NSArray *array1 = @[@1, @2, @3];
NSArray *array2 = [[NSArray alloc] initWithArray:array1 copyItems:YES]; // 深拷贝
// array1 和 array2 以及内部的元素都是不同的对象
```

### 19.3 实现深拷贝

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

## 20. 属性的 copy 和 strong 的区别？

### 20.1 copy

`copy` 会创建对象的副本，适用于不可变对象。

```objc
@property (nonatomic, copy) NSString *name;

// 使用 copy
NSMutableString *mutableStr = [NSMutableString stringWithString:@"Hello"];
person.name = mutableStr; // 会调用 copy，创建不可变副本
[mutableStr appendString:@" World"];
// person.name 仍然是 "Hello"，因为 copy 创建了副本
```

### 20.2 strong

`strong` 是强引用，适用于可变对象。

```objc
@property (nonatomic, strong) NSMutableArray *items;

// 使用 strong
NSMutableArray *array = [NSMutableArray array];
person.items = array;
[array addObject:@"1"];
// person.items 也会包含 "1"，因为是同一个对象
```

### 20.3 选择原则

- 不可变对象（NSString、NSArray 等）使用 `copy`
- 可变对象（NSMutableString、NSMutableArray 等）使用 `strong`
- 自定义对象根据需求选择

## 21. 什么是内存警告？

内存警告是系统在内存不足时发送的通知，应用应该释放不必要的内存。

### 21.1 处理内存警告

```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // 释放缓存
    [self clearCache];
    // 释放图片
    [self releaseImages];
}
```

### 21.2 内存警告级别

- `UIApplicationDidReceiveMemoryWarningNotification`：一般内存警告
- 系统可能会终止后台应用

## 22. 如何优化内存使用？

### 22.1 图片优化

```objc
// 使用合适的图片格式和大小
UIImage *image = [UIImage imageNamed:@"image.png"];
// 使用 imageWithContentsOfFile: 代替 imageNamed:（不缓存）

// 及时释放大图片
self.largeImage = nil;
```

### 22.2 缓存管理

```objc
// 使用 NSCache 代替 NSDictionary（自动释放）
NSCache *cache = [[NSCache alloc] init];
cache.countLimit = 100; // 限制数量
cache.totalCostLimit = 50 * 1024 * 1024; // 限制大小（50MB）
```

### 22.3 懒加载

```objc
- (NSArray *)dataArray {
    if (_dataArray == nil) {
        _dataArray = @[@1, @2, @3];
    }
    return _dataArray;
}
```

## 23. 什么是内存映射文件？

内存映射文件是将文件映射到内存中，可以像访问内存一样访问文件。

### 23.1 优点

- 提高文件访问性能
- 减少内存占用（按需加载）
- 多个进程可以共享

### 23.2 使用场景

- 大文件读取
- 数据库文件
- 图片缓存

## 24. 什么是内存对齐？

内存对齐是指数据在内存中的存储位置必须是对齐边界的倍数。

### 24.1 对齐规则

- 结构体的起始地址必须是其最大成员大小的倍数
- 结构体成员按照声明顺序存储
- 结构体总大小必须是最大成员大小的倍数

### 24.2 示例

```objc
struct Example {
    char a;      // 1 字节，偏移 0
    int b;       // 4 字节，偏移 4（对齐到 4 的倍数）
    char c;      // 1 字节，偏移 8
}; // 总大小 12 字节（对齐到 4 的倍数）
```

## 25. 如何检测内存泄漏？

### 25.1 使用 Instruments

1. 打开 Instruments
2. 选择 Leaks 模板
3. 运行应用
4. 查看泄漏的对象和调用栈

### 25.2 使用 Memory Graph Debugger

1. 在 Xcode 中运行应用
2. 点击 Debug Memory Graph 按钮
3. 查看对象引用关系

### 25.3 使用代码检测

```objc
// 在 dealloc 中打印日志
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}
```

## 26. 什么是 retain cycle（ retain 循环）？

retain cycle 就是循环引用，两个或多个对象相互强引用，导致无法释放。

## 27. weak 引用的实现原理？

### 27.1 SideTable

weak 引用通过 SideTable 实现：
- 每个对象都有一个 SideTable
- SideTable 中存储了所有指向该对象的 weak 引用
- 当对象被释放时，会遍历 SideTable，将所有 weak 引用置为 nil

### 27.2 代码流程

```
1. 创建 weak 引用时，将引用添加到对象的 SideTable
2. 对象释放时，调用 dealloc
3. dealloc 中遍历 SideTable，将所有 weak 引用置为 nil
4. 释放对象内存
```

## 28. 什么是 __unsafe_unretained？

`__unsafe_unretained` 是不安全的弱引用，不会增加引用计数，但对象释放后不会自动置为 nil。

### 28.1 与 weak 的区别

| 特性 | weak | __unsafe_unretained |
|------|------|---------------------|
| 引用计数 | 不增加 | 不增加 |
| 自动置 nil | 是 | 否 |
| 安全性 | 安全 | 不安全（可能野指针） |
| 性能 | 稍慢 | 稍快 |

### 28.2 使用场景

- 性能要求极高的场景
- 确定对象生命周期不会提前释放
- 兼容 iOS 4（weak 需要 iOS 5+）

## 29. 什么是 __bridge？

`__bridge` 用于 Objective-C 对象和 Core Foundation 对象之间的转换。

### 29.1 类型转换

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

### 29.2 其他桥接关键字

- `__bridge_retained`：转移所有权给 CF 对象
- `__bridge_transfer`：转移所有权给 OC 对象

## 30. 内存管理的常见面试题总结

1. **MRC 和 ARC 的区别？** - 手动 vs 自动管理
2. **引用计数的原理？** - retainCount 的增减
3. **属性修饰词有哪些？** - assign、strong、weak、copy、retain、unsafe_unretained
4. **强引用和弱引用的区别？** - 是否增加引用计数
5. **什么是循环引用？** - 对象相互强引用
6. **如何解决 Block 的循环引用？** - 使用 __weak
7. **如何解决 Delegate 的循环引用？** - 使用 weak
8. **如何解决 NSTimer 的循环引用？** - 使用 weak 代理或 Block
9. **什么是内存泄漏？** - 已分配内存无法释放
10. **什么是野指针？** - 指向已释放内存的指针
11. **什么是 AutoreleasePool？** - 自动释放池
12. **AutoreleasePool 的释放时机？** - RunLoop 循环
13. **深拷贝和浅拷贝的区别？** - 是否复制内部对象
14. **copy 和 strong 的区别？** - 创建副本 vs 强引用
15. **如何检测内存泄漏？** - Instruments、Memory Graph
16. **weak 引用的实现原理？** - SideTable
17. **__unsafe_unretained 和 weak 的区别？** - 是否自动置 nil
18. **什么是 __bridge？** - OC 和 CF 对象的转换
19. **如何优化内存使用？** - 图片优化、缓存管理、懒加载

## 31. 内存管理的最佳实践

### 31.1 避免循环引用

- Delegate 使用 weak
- Block 中使用 weakSelf
- NSTimer 使用 weak 代理

### 31.2 及时释放资源

- 在 dealloc 中移除观察者
- 停止定时器
- 释放 Core Foundation 对象

### 31.3 合理使用缓存

- 使用 NSCache 代替 NSDictionary
- 设置缓存限制
- 及时清理缓存

### 31.4 优化图片使用

- 使用合适的图片格式和大小
- 及时释放大图片
- 使用图片缓存

