# iOS 面试题 - KVO

## 1. 什么是 KVO？

KVO（Key-Value Observing）是键值观察，是 Objective-C 对观察者模式的实现。它允许对象监听其他对象属性的变化，当属性值发生变化时，会自动通知观察者。

### 1.1 KVO 的特点

- 观察者模式的一种实现
- 自动通知属性变化
- 可以监听多个属性
- 支持一对多的通知

## 2. KVO 的基本用法？

### 2.1 注册观察者

```objc
// 注册观察者
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
            context:nil];
```

### 2.2 实现观察方法

```objc
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
```

### 2.3 移除观察者

```objc
- (void)dealloc {
    [person removeObserver:self forKeyPath:@"name"];
}
```

## 3. KVO 的观察选项（Options）？

### 3.1 选项类型

- `NSKeyValueObservingOptionNew`：提供新值
- `NSKeyValueObservingOptionOld`：提供旧值
- `NSKeyValueObservingOptionInitial`：注册时立即触发一次
- `NSKeyValueObservingOptionPrior`：变化前后各触发一次

### 3.2 代码示例

```objc
// 只获取新值
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew 
            context:nil];

// 获取新旧值
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
            context:nil];

// 注册时立即触发
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionInitial 
            context:nil];
```

## 4. KVO 的实现原理？

### 4.1 动态创建子类

当对象被观察时，Runtime 会动态创建一个子类：
- 类名格式：`NSKVONotifying_原类名`
- 重写被观察属性的 setter 方法
- 重写 `class` 方法，返回原类
- 添加 `dealloc`、`_isKVOA` 方法

### 4.2 重写 setter 方法

```objc
// 伪代码
- (void)setName:(NSString *)name {
    [self willChangeValueForKey:@"name"];
    [super setName:name];
    [self didChangeValueForKey:@"name"];
}
```

### 4.3 通知机制

- `willChangeValueForKey:`：通知观察者即将变化
- `didChangeValueForKey:`：通知观察者已经变化

## 5. 如何验证 KVO 的实现原理？

### 5.1 查看类名

```objc
Person *person = [[Person alloc] init];
NSLog(@"注册前：%@", object_getClass(person)); // Person

[person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
NSLog(@"注册后：%@", object_getClass(person)); // NSKVONotifying_Person
```

### 5.2 查看方法列表

```objc
unsigned int count;
Method *methods = class_copyMethodList(object_getClass(person), &count);
for (unsigned int i = 0; i < count; i++) {
    Method method = methods[i];
    SEL selector = method_getName(method);
    NSLog(@"方法：%@", NSStringFromSelector(selector));
}
free(methods);
// 输出：setName:、class、dealloc、_isKVOA
```

## 6. KVO 的触发条件？

### 6.1 必须使用 KVC 或 setter 方法

```objc
// 方式1：使用 setter 方法（会触发 KVO）
person.name = @"New Name";

// 方式2：使用 KVC（会触发 KVO）
[person setValue:@"New Name" forKey:@"name"];

// 方式3：直接访问实例变量（不会触发 KVO）
person->_name = @"New Name";
```

### 6.2 手动触发

```objc
// 手动触发
[self willChangeValueForKey:@"name"];
_name = @"New Name";
[self didChangeValueForKey:@"name"];
```

## 7. 如何手动控制 KVO？

### 7.1 禁用自动通知

```objc
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"name"]) {
        return NO; // 禁用自动通知
    }
    return [super automaticallyNotifiesObserversForKey:key];
}
```

### 7.2 手动触发

```objc
- (void)setName:(NSString *)name {
    if (_name != name) {
        [self willChangeValueForKey:@"name"];
        _name = name;
        [self didChangeValueForKey:@"name"];
    }
}
```

## 8. KVO 的依赖键（Dependent Keys）？

### 8.1 定义依赖关系

当一个属性的值依赖于其他属性时，可以定义依赖关系。

```objc
// 定义 fullName 依赖于 firstName 和 lastName
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"fullName"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"firstName", @"lastName"]];
    }
    return keyPaths;
}
```

### 8.2 使用 @keyPathsForValuesAffecting

```objc
+ (NSSet<NSString *> *)keyPathsForValuesAffectingFullName {
    return [NSSet setWithObjects:@"firstName", @"lastName", nil];
}
```

## 9. KVO 的集合观察？

### 9.1 观察数组变化

```objc
// 注册观察
[person addObserver:self 
         forKeyPath:@"items" 
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld 
            context:nil];

// 实现观察方法
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    if ([keyPath isEqualToString:@"items"]) {
        NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
        NSArray *newValues = change[NSKeyValueChangeNewKey];
        NSArray *oldValues = change[NSKeyValueChangeOldKey];
        
        switch (changeKind) {
            case NSKeyValueChangeInsertion:
                NSLog(@"插入：%@", newValues);
                break;
            case NSKeyValueChangeRemoval:
                NSLog(@"删除：%@", oldValues);
                break;
            case NSKeyValueChangeReplacement:
                NSLog(@"替换：%@ -> %@", oldValues, newValues);
                break;
            default:
                break;
        }
    }
}

// 使用 KVC 方法修改数组
[[person mutableArrayValueForKey:@"items"] addObject:@"新项"];
```

### 9.2 集合操作方法

- `mutableArrayValueForKey:`：获取可变数组代理
- `mutableSetValueForKey:`：获取可变集合代理
- `mutableOrderedSetValueForKey:`：获取可变有序集合代理

## 10. KVO 的 context 参数？

### 10.1 context 的作用

context 用于区分不同的观察，避免在 `observeValueForKeyPath:ofObject:change:context:` 中判断 keyPath。

### 10.2 使用方式

```objc
// 定义 context
static void *PersonNameContext = &PersonNameContext;
static void *PersonAgeContext = &PersonAgeContext;

// 注册观察
[person addObserver:self 
         forKeyPath:@"name" 
            options:NSKeyValueObservingOptionNew 
            context:PersonNameContext];

[person addObserver:self 
         forKeyPath:@"age" 
            options:NSKeyValueObservingOptionNew 
            context:PersonAgeContext];

// 实现观察方法
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    if (context == PersonNameContext) {
        // 处理 name 变化
    } else if (context == PersonAgeContext) {
        // 处理 age 变化
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

## 11. KVO 的注意事项？

### 11.1 必须移除观察者

```objc
- (void)dealloc {
    [person removeObserver:self forKeyPath:@"name"];
}
```

### 11.2 避免重复移除

```objc
@try {
    [person removeObserver:self forKeyPath:@"name"];
} @catch (NSException *exception) {
    // 已经移除过，忽略异常
}
```

### 11.3 观察者必须实现观察方法

如果观察者没有实现 `observeValueForKeyPath:ofObject:change:context:`，会抛出异常。

### 11.4 属性必须是 KVC 兼容的

属性必须支持 KVC，即必须有对应的 setter 方法或实例变量。

## 12. KVO 的性能影响？

### 12.1 性能开销

- 动态创建子类
- 方法查找和调用
- 通知所有观察者

### 12.2 优化建议

- 避免观察过多属性
- 及时移除观察者
- 使用 context 区分观察
- 合理使用观察选项

## 13. KVO 与 Notification 的区别？

| 特性 | KVO | Notification |
|------|-----|--------------|
| 观察对象 | 对象的属性 | 通知名称 |
| 通知方式 | 自动 | 手动发送 |
| 观察者数量 | 多个 | 多个 |
| 解耦程度 | 较低 | 较高 |
| 性能 | 较好 | 较差 |

## 14. KVO 与 Delegate 的区别？

| 特性 | KVO | Delegate |
|------|-----|----------|
| 观察对象 | 对象的属性 | 对象的事件 |
| 通知方式 | 自动 | 手动调用 |
| 观察者数量 | 多个 | 一个 |
| 使用场景 | 属性变化 | 事件回调 |

## 15. 如何实现 KVO 的自动移除？

### 15.1 使用关联对象

```objc
@interface NSObject (KVOAutoRemove)
@end

@implementation NSObject (KVOAutoRemove)
+ (void)load {
    Method originalMethod = class_getInstanceMethod(self, NSSelectorFromString(@"dealloc"));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(kvo_dealloc));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)kvo_dealloc {
    // 自动移除所有 KVO 观察
    // 实现逻辑...
    [self kvo_dealloc];
}
@end
```

### 15.2 iOS 9+ 自动移除

iOS 9+ 系统会自动移除观察者，但仍建议手动移除。

## 16. KVO 的常见问题？

### 16.1 观察者未移除导致崩溃

```objc
// 问题：观察者已释放，但未移除观察
// 解决：在 dealloc 中移除观察
```

### 16.2 重复移除导致崩溃

```objc
// 问题：重复移除观察者
// 解决：使用 @try-@catch 或记录移除状态
```

### 16.3 观察方法未实现导致崩溃

```objc
// 问题：观察者未实现 observeValueForKeyPath:ofObject:change:context:
// 解决：必须实现观察方法
```

### 16.4 直接访问实例变量不触发 KVO

```objc
// 问题：直接访问实例变量不会触发 KVO
person->_name = @"New Name"; // 不会触发

// 解决：使用 setter 或 KVC
person.name = @"New Name"; // 会触发
```

## 17. KVO 的实际应用场景？

### 17.1 数据绑定

```objc
// 观察模型数据变化，自动更新 UI
[model addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionNew context:nil];
```

### 17.2 状态监听

```objc
// 监听下载进度
[downloadTask addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
```

### 17.3 配置变化

```objc
// 监听配置变化
[config addObserver:self forKeyPath:@"theme" options:NSKeyValueObservingOptionNew context:nil];
```

## 18. 如何调试 KVO？

### 18.1 打印观察信息

```objc
// 查看对象的观察者
id info = [person observationInfo];
NSLog(@"观察信息：%@", info);
```

### 18.2 使用断点

在 `observeValueForKeyPath:ofObject:change:context:` 中设置断点，查看调用栈。

### 18.3 使用 Instruments

使用 Time Profiler 分析 KVO 的性能影响。

## 19. KVO 的最佳实践？

### 19.1 及时移除观察者

```objc
- (void)dealloc {
    [person removeObserver:self forKeyPath:@"name"];
}
```

### 19.2 使用 context 区分观察

```objc
static void *PersonNameContext = &PersonNameContext;
[person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:PersonNameContext];
```

### 19.3 在观察方法中判断 keyPath

```objc
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    if ([keyPath isEqualToString:@"name"]) {
        // 处理 name 变化
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

### 19.4 避免观察过多属性

- 只观察必要的属性
- 考虑使用其他方式（如 Delegate、Block）

## 20. KVO 的常见面试题总结

1. **什么是 KVO？** - 键值观察，观察者模式的实现
2. **KVO 的基本用法？** - addObserver、observeValueForKeyPath、removeObserver
3. **KVO 的实现原理？** - 动态创建子类，重写 setter 方法
4. **KVO 的触发条件？** - 使用 setter 或 KVC
5. **如何手动控制 KVO？** - automaticallyNotifiesObserversForKey
6. **KVO 的依赖键？** - keyPathsForValuesAffectingValueForKey
7. **KVO 的集合观察？** - mutableArrayValueForKey
8. **KVO 的 context 参数？** - 区分不同的观察
9. **KVO 的注意事项？** - 必须移除观察者、避免重复移除
10. **KVO 与 Notification 的区别？** - 观察对象、通知方式
11. **KVO 的性能影响？** - 动态创建子类、方法调用
12. **如何调试 KVO？** - 打印观察信息、使用断点

## 21. KVO 的高级用法

### 21.1 观察嵌套属性

```objc
// 观察 person.address.city
[person addObserver:self forKeyPath:@"address.city" options:NSKeyValueObservingOptionNew context:nil];
```

### 21.2 观察多个属性

```objc
// 观察多个属性
NSArray *keyPaths = @[@"name", @"age", @"address"];
for (NSString *keyPath in keyPaths) {
    [person addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
}
```

### 21.3 使用 Block 回调（第三方库）

```objc
// 使用 ReactiveCocoa 等第三方库
[person rac_observeKeyPath:@"name" options:NSKeyValueObservingOptionNew observer:nil block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
    NSLog(@"name 变化：%@", value);
}];
```

