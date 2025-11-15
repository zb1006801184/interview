# iOS 面试题 - Runtime

## 1. 什么是 Runtime？

Runtime 是 Objective-C 的运行时系统，是 Objective-C 语言的核心。它提供了动态特性，允许在运行时创建类、添加方法、交换方法实现等。

### 1.1 Runtime 的作用

- 动态创建类和对象
- 动态添加方法和属性
- 消息转发机制
- 方法交换（Method Swizzling）
- 关联对象（Associated Objects）

## 2. Objective-C 的消息机制？

### 2.1 消息发送

Objective-C 的方法调用实际上是消息发送：

```objc
[object method:parameter];
// 编译后转换为：
objc_msgSend(object, @selector(method:), parameter);
```

### 2.2 消息查找流程

1. 在类的缓存中查找方法（`cache_getImp`）
2. 在当前类的方法列表中查找（`class_getInstanceMethod`）
3. 沿着继承链向上查找：如果当前类找不到，会在父类的方法列表中查找；如果父类也找不到，会继续在父类的父类中查找，直到找到方法实现或到达根类（`NSObject`）
4. 如果整个继承链都找不到，进入消息转发流程

### 2.3 代码示例

```objc
// 消息发送
Person *person = [[Person alloc] init];
[person sayHello];

// 等价于
objc_msgSend(person, @selector(sayHello));
```

## 3. Runtime 的数据结构？

### 3.1 objc_object

```objc
struct objc_object {
    Class isa;  // 指向类对象
};
```

### 3.2 objc_class

```objc
struct objc_class {
    Class isa;                          // 指向元类
    Class super_class;                  // 指向父类
    const char *name;                   // 类名
    long version;                       // 版本
    long info;                          // 信息
    long instance_size;                 // 实例大小
    struct objc_ivar_list *ivars;       // 实例变量列表
    struct objc_method_list **methodLists; // 方法列表
    struct objc_cache *cache;           // 方法缓存
    struct objc_protocol_list *protocols; // 协议列表
};
```

### 3.3 Method

```objc
struct objc_method {
    SEL method_name;        // 方法名
    char *method_types;     // 方法类型编码
    IMP method_imp;         // 方法实现
};
```

## 4. 什么是 isa 指针？

isa 指针指向对象的类对象，类对象的 isa 指向元类（metaclass）。

### 4.1 isa 的作用

- 对象通过 isa 找到类对象
- 类对象通过 isa 找到元类
- 用于方法查找和消息发送

### 4.2 isa 的指向关系

```
实例对象 -> 类对象 -> 元类 -> 根元类 -> 根元类（指向自己）
```

### 4.3 代码示例

```objc
Person *person = [[Person alloc] init];
Class class = object_getClass(person);        // 获取类对象
Class metaClass = object_getClass(class);     // 获取元类
```

## 5. 什么是元类（Metaclass）？

元类是类对象的类，用于存储类方法。

### 5.1 元类的作用

- 存储类方法（+ 方法）
- 类对象通过 isa 指向元类
- 所有元类的 isa 都指向根元类

### 5.2 代码示例

```objc
// 实例方法存储在类对象中
- (void)instanceMethod;

// 类方法存储在元类中
+ (void)classMethod;
```

## 6. 什么是 SEL、IMP、Method？

### 6.1 SEL（Selector）

SEL 是方法选择器，表示方法的名称。

```objc
SEL selector = @selector(sayHello);
NSLog(@"%@", NSStringFromSelector(selector)); // sayHello
```

### 6.2 IMP（Implementation）

IMP 是指向方法实现的函数指针。

```objc
IMP imp = class_getMethodImplementation([Person class], @selector(sayHello));
void (*func)(id, SEL) = (void *)imp;
func(person, @selector(sayHello));
```

### 6.3 Method

Method 是方法的结构，包含 SEL 和 IMP。

```objc
Method method = class_getInstanceMethod([Person class], @selector(sayHello));
SEL selector = method_getName(method);
IMP imp = method_getImplementation(method);
```

## 7. 什么是消息转发（Message Forwarding）？

消息转发是当对象无法响应消息时，Runtime 提供的处理机制。

### 7.1 消息转发流程

1. **动态方法解析**：`+resolveInstanceMethod:` 或 `+resolveClassMethod:`
2. **快速转发**：`-forwardingTargetForSelector:`
3. **完整转发**：`-methodSignatureForSelector:` 和 `-forwardInvocation:`

### 7.2 代码示例

```objc
// 第一步：动态添加方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(dynamicMethod)) {
        class_addMethod(self, sel, (IMP)dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@"动态添加的方法");
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

## 8. 什么是 Method Swizzling（方法交换）？

Method Swizzling 是在运行时交换两个方法的实现。

### 8.1 基本用法

```objc
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(swizzled_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // 尝试添加方法
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypes(swizzledMethod));
        
        if (didAddMethod) {
            // 添加成功，替换实现
            class_replaceMethod(class,
                              swizzledSelector,
                              method_getImplementation(originalMethod),
                              method_getTypes(originalMethod));
        } else {
            // 添加失败，直接交换
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)swizzled_viewWillAppear:(BOOL)animated {
    [self swizzled_viewWillAppear:animated]; // 实际调用原方法
    NSLog(@"viewWillAppear 被调用");
}
```

### 8.2 注意事项

- 在 `+load` 方法中执行
- 使用 `dispatch_once` 确保只执行一次
- 注意方法是否已存在
- 注意子类和父类的方法交换

## 9. 什么是 Associated Objects（关联对象）？

关联对象允许在运行时为对象添加属性，常用于 Category。

### 9.1 基本用法

```objc
// 定义关联键
static char kAssociatedObjectKey;

// 设置关联对象
objc_setAssociatedObject(self, 
                        &kAssociatedObjectKey, 
                        value, 
                        OBJC_ASSOCIATION_RETAIN_NONATOMIC);

// 获取关联对象
id value = objc_getAssociatedObject(self, &kAssociatedObjectKey);

// 移除关联对象
objc_setAssociatedObject(self, &kAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
```

### 9.2 关联策略

- `OBJC_ASSOCIATION_ASSIGN`：弱引用
- `OBJC_ASSOCIATION_RETAIN_NONATOMIC`：强引用，非原子
- `OBJC_ASSOCIATION_COPY_NONATOMIC`：拷贝，非原子
- `OBJC_ASSOCIATION_RETAIN`：强引用，原子
- `OBJC_ASSOCIATION_COPY`：拷贝，原子

### 9.3 在 Category 中使用

```objc
@interface UIView (Extension)
@property (nonatomic, strong) NSString *customProperty;
@end

@implementation UIView (Extension)
- (void)setCustomProperty:(NSString *)customProperty {
    objc_setAssociatedObject(self, @selector(customProperty), customProperty, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)customProperty {
    return objc_getAssociatedObject(self, @selector(customProperty));
}
@end
```

## 10. 如何动态创建类？

### 10.1 创建类

```objc
// 创建类
Class newClass = objc_allocateClassPair([NSObject class], "CustomClass", 0);

// 添加实例变量
class_addIvar(newClass, "_name", sizeof(NSString *), log2(sizeof(NSString *)), @encode(NSString *));

// 添加方法
void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@"动态方法");
}
class_addMethod(newClass, @selector(dynamicMethod), (IMP)dynamicMethodIMP, "v@:");

// 注册类
objc_registerClassPair(newClass);

// 使用
id instance = [[newClass alloc] init];
[instance performSelector:@selector(dynamicMethod)];
```

## 11. 如何获取类的所有方法？

### 11.1 获取实例方法

```objc
unsigned int count;
Method *methods = class_copyMethodList([Person class], &count);
for (unsigned int i = 0; i < count; i++) {
    Method method = methods[i];
    SEL selector = method_getName(method);
    NSLog(@"方法名：%@", NSStringFromSelector(selector));
}
free(methods);
```

### 11.2 获取类方法

```objc
unsigned int count;
Method *methods = class_copyMethodList(object_getClass([Person class]), &count);
for (unsigned int i = 0; i < count; i++) {
    Method method = methods[i];
    SEL selector = method_getName(method);
    NSLog(@"类方法名：%@", NSStringFromSelector(selector));
}
free(methods);
```

## 12. 如何获取类的所有属性？

### 12.1 获取属性列表

```objc
unsigned int count;
objc_property_t *properties = class_copyPropertyList([Person class], &count);
for (unsigned int i = 0; i < count; i++) {
    objc_property_t property = properties[i];
    const char *name = property_getName(property);
    NSLog(@"属性名：%s", name);
    
    // 获取属性特性
    const char *attributes = property_getAttributes(property);
    NSLog(@"属性特性：%s", attributes);
}
free(properties);
```

## 13. 如何获取类的所有实例变量？

### 13.1 获取实例变量列表

```objc
unsigned int count;
Ivar *ivars = class_copyIvarList([Person class], &count);
for (unsigned int i = 0; i < count; i++) {
    Ivar ivar = ivars[i];
    const char *name = ivar_getName(ivar);
    const char *type = ivar_getTypeEncoding(ivar);
    NSLog(@"实例变量名：%s，类型：%s", name, type);
}
free(ivars);
```

## 14. 如何动态添加方法？

### 14.1 添加实例方法

```objc
void dynamicMethodIMP(id self, SEL _cmd, NSString *param) {
    NSLog(@"动态方法，参数：%@", param);
}

class_addMethod([Person class], 
                @selector(dynamicMethod:), 
                (IMP)dynamicMethodIMP, 
                "v@:@");

// 使用
Person *person = [[Person alloc] init];
[person performSelector:@selector(dynamicMethod:) withObject:@"参数"];
```

### 14.2 添加类方法

```objc
void dynamicClassMethodIMP(id self, SEL _cmd) {
    NSLog(@"动态类方法");
}

class_addMethod(object_getClass([Person class]), 
                @selector(dynamicClassMethod), 
                (IMP)dynamicClassMethodIMP, 
                "v@:");

// 使用
[Person performSelector:@selector(dynamicClassMethod)];
```

## 15. 如何替换方法实现？

### 15.1 替换实现

```objc
IMP originalIMP = class_getMethodImplementation([Person class], @selector(sayHello));

void newMethodIMP(id self, SEL _cmd) {
    NSLog(@"新方法实现");
}

class_replaceMethod([Person class], @selector(sayHello), (IMP)newMethodIMP, "v@:");
```

## 16. 如何获取方法实现？

### 16.1 获取 IMP

```objc
// 获取实例方法实现
IMP imp = class_getMethodImplementation([Person class], @selector(sayHello));

// 获取类方法实现
IMP classImp = class_getMethodImplementation(object_getClass([Person class]), @selector(classMethod));

// 调用
void (*func)(id, SEL) = (void *)imp;
func(person, @selector(sayHello));
```

## 17. 什么是类对象和实例对象？

### 17.1 实例对象

实例对象是类的实例，存储实例变量。

```objc
Person *person = [[Person alloc] init]; // person 是实例对象
```

### 17.2 类对象

类对象是类的元数据，存储类方法和实例方法列表。

```objc
Class class = [Person class]; // class 是类对象
```

### 17.3 元类对象

元类对象是类对象的类，存储类方法。

```objc
Class metaClass = object_getClass([Person class]); // metaClass 是元类对象
```

## 18. 如何判断对象类型？

### 18.1 类型判断方法

```objc
Person *person = [[Person alloc] init];

// isKindOfClass: 判断是否是某个类或其子类的实例
if ([person isKindOfClass:[Person class]]) {
    NSLog(@"是 Person 或其子类");
}

// isMemberOfClass: 判断是否是某个类的实例（不包括子类）
if ([person isMemberOfClass:[Person class]]) {
    NSLog(@"是 Person 的实例");
}

// respondsToSelector: 判断是否响应某个方法
if ([person respondsToSelector:@selector(sayHello)]) {
    NSLog(@"响应 sayHello 方法");
}

// conformsToProtocol: 判断是否遵循某个协议
if ([person conformsToProtocol:@protocol(NSCopying)]) {
    NSLog(@"遵循 NSCopying 协议");
}
```

## 19. 什么是 Tagged Pointer？

Tagged Pointer 是苹果的优化技术，将小对象直接存储在指针中。

### 19.1 特点

- 小对象（如小字符串、小数字）直接存储在指针中
- 不需要分配堆内存
- 不需要引用计数管理
- 提高性能

### 19.2 判断方式

```objc
NSString *str = @"Hello";
NSLog(@"%p", str); // 如果是指针值很大，可能是 Tagged Pointer
```

## 20. 什么是 isa 指针的优化？

在 64 位系统中，isa 指针不再直接指向类对象，而是存储了更多信息。

### 20.1 isa 的结构

```
isa = class pointer | extra data
```

### 20.2 获取类对象

```objc
// 需要使用 mask 获取类对象
Class class = (__bridge Class)((void *)((uintptr_t)isa & ISA_MASK));
```

## 21. 什么是方法缓存（Method Cache）？

方法缓存用于提高方法查找效率，存储最近调用的方法。

### 21.1 缓存机制

- 方法调用时，先在缓存中查找
- 如果找到，直接调用
- 如果找不到，在方法列表中查找，并添加到缓存

### 21.2 缓存结构

```objc
struct objc_cache {
    unsigned int mask;           // 缓存大小 - 1
    unsigned int occupied;       // 已占用数量
    Method buckets[1];           // 方法缓存数组
};
```

## 22. 什么是 super 关键字？

`super` 关键字用于调用父类的方法。

### 22.1 super 的实现

```objc
// 使用 super
[super sayHello];

// 编译后转换为：
objc_msgSendSuper(self, @selector(sayHello));
```

### 22.2 super 的结构

```objc
struct objc_super {
    __unsafe_unretained id receiver;  // 消息接收者
    __unsafe_unretained Class super_class; // 父类
};
```

## 23. Runtime 的应用场景？

### 23.1 方法交换

- AOP 编程
- 日志记录
- 异常处理

### 23.2 动态添加方法

- 动态创建类
- 热修复
- 插件化

### 23.3 关联对象

- Category 添加属性
- 扩展功能

### 23.4 消息转发

- 动态代理
- 多继承模拟

## 24. 如何查看 Runtime 源码？

### 24.1 源码位置

- [objc4 源码](https://opensource.apple.com/source/objc4/)
- 可以在 Xcode 中查看 Runtime 头文件

### 24.2 关键文件

- `objc-runtime.h`：Runtime 头文件
- `objc-class.h`：类相关定义
- `message.h`：消息发送相关

## 25. Runtime 的性能影响？

### 25.1 性能开销

- 消息发送比直接函数调用慢
- 方法查找需要遍历方法列表
- 方法缓存可以提高性能

### 25.2 优化建议

- 避免频繁使用 Runtime API
- 使用缓存减少查找次数
- 合理使用 Method Swizzling

## 26. Runtime 的常见面试题总结

1. **什么是 Runtime？** - Objective-C 的运行时系统
2. **Objective-C 的消息机制？** - 消息发送和查找流程
3. **什么是 isa 指针？** - 指向类对象的指针
4. **什么是元类？** - 类对象的类，存储类方法
5. **SEL、IMP、Method 的区别？** - 方法选择器、实现指针、方法结构
6. **消息转发的流程？** - resolveInstanceMethod、forwardingTargetForSelector、forwardInvocation
7. **什么是 Method Swizzling？** - 运行时交换方法实现
8. **什么是 Associated Objects？** - 运行时添加属性
9. **如何动态创建类？** - objc_allocateClassPair、objc_registerClassPair
10. **如何获取类的所有方法？** - class_copyMethodList
11. **如何获取类的所有属性？** - class_copyPropertyList
12. **如何动态添加方法？** - class_addMethod
13. **什么是 Tagged Pointer？** - 小对象存储在指针中
14. **什么是方法缓存？** - 提高方法查找效率
15. **super 关键字的实现？** - objc_msgSendSuper

## 27. Runtime 的最佳实践

### 27.1 谨慎使用 Method Swizzling

- 在 `+load` 中执行
- 使用 `dispatch_once` 确保只执行一次
- 注意方法是否已存在
- 注意子类和父类的方法交换

### 27.2 合理使用关联对象

- 使用合适的关联策略
- 注意内存管理
- 避免过度使用

### 27.3 理解消息转发

- 了解转发流程
- 合理使用转发机制
- 注意性能影响

### 27.4 性能优化

- 避免频繁使用 Runtime API
- 使用缓存减少查找
- 合理使用动态特性

