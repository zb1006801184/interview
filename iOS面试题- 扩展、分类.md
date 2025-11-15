# iOS 面试题 - 扩展、分类

## 1. 什么是 Category（分类）？

Category 是 Objective-C 中用于为已有类添加新方法的一种机制，可以在不修改原有类的情况下扩展类的功能。

### 1.1 基本语法

```objc
// Person.h
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
- (void)sayHello;
@end

// Person+Extension.h（分类）
#import "Person.h"

@interface Person (Extension)
- (void)sayGoodbye;
- (void)introduce;
@end

// Person+Extension.m
#import "Person+Extension.h"

@implementation Person (Extension)
- (void)sayGoodbye {
    NSLog(@"Goodbye!");
}

- (void)introduce {
    NSLog(@"My name is %@", self.name);
}
@end
```

### 1.2 Category 的特点

- **不能添加实例变量**：只能添加方法，不能添加成员变量
- **可以添加属性**：但需要手动实现 getter/setter（使用关联对象）
- **可以添加类方法**：可以添加实例方法和类方法
- **方法优先级**：分类中的方法优先级高于原类方法
- **多个分类**：可以为同一个类创建多个分类

## 2. 什么是 Extension（扩展）？

Extension 是 Category 的一种特殊形式，也称为匿名分类（Anonymous Category），在 .m 文件中使用。

### 2.1 基本语法

```objc
// Person.h（公开接口）
@interface Person : NSObject
@property (nonatomic, strong) NSString *name;
- (void)sayHello;
@end

// Person.m（扩展）
#import "Person.h"

// Extension：在 .m 文件中定义私有属性和方法
@interface Person ()
@property (nonatomic, strong) NSString *privateName; // 私有属性
- (void)privateMethod; // 私有方法
@end

@implementation Person
- (void)sayHello {
    NSLog(@"Hello!");
    [self privateMethod];
}

- (void)privateMethod {
    NSLog(@"This is a private method");
}
@end
```

### 2.2 Extension 的特点

- **可以添加实例变量**：与普通类接口相同
- **可以添加属性**：会自动生成 getter/setter 和实例变量
- **编译时确定**：在编译时就已经确定，不是运行时特性
- **私有性**：用于隐藏类的内部实现细节
- **必须在 .m 文件中**：必须在对应类的 .m 文件中定义

## 3. Category 和 Extension 的区别？

### 3.1 对比表

| 特性 | Category | Extension |
|------|----------|-----------|
| 定义位置 | 独立的 .h/.m 文件 | 在类的 .m 文件中 |
| 可见性 | 公开 | 私有 |
| 添加实例变量 | ❌ 不可以 | ✅ 可以 |
| 添加属性 | ⚠️ 需要关联对象 | ✅ 可以（自动生成） |
| 添加方法 | ✅ 可以 | ✅ 可以 |
| 编译时机 | 运行时 | 编译时 |
| 数量限制 | 可以有多个 | 只能有一个 |
| 方法覆盖 | 可以覆盖原类方法 | 不能覆盖 |

### 3.2 代码示例

```objc
// Category 示例
// Person+Category.h
@interface Person (Category)
@property (nonatomic, strong) NSString *nickname; // 需要关联对象实现
- (void)categoryMethod;
@end

// Extension 示例
// Person.m
@interface Person ()
@property (nonatomic, strong) NSString *privateInfo; // 自动生成实例变量
- (void)privateMethod;
@end
```

## 4. Category 的底层实现原理？

### 4.1 数据结构

Category 在编译时会被转换为 `category_t` 结构体：

```objc
struct category_t {
    const char *name;                    // 分类名称
    classref_t cls;                      // 所属类
    struct method_list_t *instanceMethods; // 实例方法列表
    struct method_list_t *classMethods;   // 类方法列表
    struct protocol_list_t *protocols;    // 协议列表
    struct property_list_t *instanceProperties; // 属性列表
};
```

### 4.2 加载过程

1. **编译时**：编译器将 Category 转换为 `category_t` 结构体
2. **运行时**：在 `objc-runtime-new.mm` 中的 `attachCategories` 函数中加载
3. **方法合并**：将 Category 的方法列表添加到类的 `method_list` 中
4. **方法排序**：后编译的 Category 方法会排在前面（优先级更高）

### 4.3 源码分析

```objc
// 简化版的加载逻辑
static void attachCategories(Class cls, category_list *cats) {
    // 1. 分配方法列表数组
    method_list_t **mlists = (method_list_t **)malloc(cats->count * sizeof(*mlists));
    
    // 2. 遍历所有分类，收集方法
    for (int i = 0; i < cats->count; i++) {
        category_t *cat = cats->list[i];
        mlists[i] = cat->methodsForMeta(isMeta);
    }
    
    // 3. 将方法列表附加到类的方法列表中
    rw->methods.attachLists(mlists, count);
}
```

## 5. Category 的方法覆盖问题？

### 5.1 方法优先级

当 Category 和原类有同名方法时：
- **Category 方法优先**：后编译的 Category 方法会覆盖原类方法
- **多个 Category**：后编译的 Category 优先级更高
- **不会真正覆盖**：原类方法仍然存在，只是调用时优先调用 Category 方法

### 5.2 代码示例

```objc
// Person.m
@implementation Person
- (void)test {
    NSLog(@"Original method");
}
@end

// Person+Category1.m（先编译）
@implementation Person (Category1)
- (void)test {
    NSLog(@"Category1 method");
}
@end

// Person+Category2.m（后编译）
@implementation Person (Category2)
- (void)test {
    NSLog(@"Category2 method");
}
@end

// 调用结果
Person *p = [[Person alloc] init];
[p test]; // 输出：Category2 method（后编译的优先级最高）
```

### 5.3 注意事项

- **避免方法覆盖**：不要轻易覆盖原类方法，可能导致不可预期的行为
- **方法名冲突**：使用前缀避免方法名冲突，如 `xxx_categoryMethod`
- **调试困难**：方法覆盖后，调试时可能找不到原方法

## 6. Category 如何添加属性？

### 6.1 使用关联对象（Associated Objects）

Category 不能直接添加实例变量，但可以通过关联对象实现属性的存储。

### 6.2 实现方式

```objc
// Person+Property.h
#import "Person.h"

@interface Person (Property)
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, assign) NSInteger age;
@end

// Person+Property.m
#import "Person+Property.h"
#import <objc/runtime.h>

@implementation Person (Property)

// 定义关联对象的 key
static const char kNicknameKey;
static const char kAgeKey;

// nickname 的 getter
- (NSString *)nickname {
    return objc_getAssociatedObject(self, &kNicknameKey);
}

// nickname 的 setter
- (void)setNickname:(NSString *)nickname {
    objc_setAssociatedObject(self, 
                            &kNicknameKey, 
                            nickname, 
                            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// age 的 getter
- (NSInteger)age {
    return [objc_getAssociatedObject(self, &kAgeKey) integerValue];
}

// age 的 setter
- (void)setAge:(NSInteger)age {
    objc_setAssociatedObject(self, 
                            &kAgeKey, 
                            @(age), 
                            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
```

### 6.3 关联对象的内存策略

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| OBJC_ASSOCIATION_ASSIGN | 弱引用，不 retain | 基本数据类型、delegate |
| OBJC_ASSOCIATION_RETAIN_NONATOMIC | 强引用，非原子性 | 对象属性（常用） |
| OBJC_ASSOCIATION_COPY_NONATOMIC | 拷贝，非原子性 | NSString、NSArray 等 |
| OBJC_ASSOCIATION_RETAIN | 强引用，原子性 | 需要线程安全 |
| OBJC_ASSOCIATION_COPY | 拷贝，原子性 | 需要线程安全的拷贝 |

## 7. 关联对象的底层实现原理？

### 7.1 数据结构

关联对象使用全局的 `AssociationsHashMap` 存储：

```objc
// 全局关联对象表
static AssociationsHashMap _map;

// 关联对象的数据结构
class AssociationsManager {
    AssociationsHashMap _map;
};

class AssociationsHashMap : public unordered_map<disguised_ptr_t, ObjectAssociationMap> {
    // key: 对象的指针（经过伪装）
    // value: 该对象的所有关联对象
};
```

### 7.2 存储过程

```objc
void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy) {
    // 1. 获取对象的关联对象表
    AssociationsHashMap &associations = getAssociations(object);
    
    // 2. 创建或更新关联对象
    AssociationsHashMap::iterator i = associations.find(key);
    if (i != associations.end()) {
        // 更新现有关联对象
        ObjectAssociationMap *refs = i->second;
        ObjectAssociationMap::iterator j = refs->find(key);
        if (j != refs->end()) {
            // 更新值
            old_association = j->second;
            j->second = ObjcAssociation(policy, value);
        }
    } else {
        // 创建新的关联对象
        ObjectAssociationMap *refs = new ObjectAssociationMap;
        associations[key] = refs;
        (*refs)[key] = ObjcAssociation(policy, value);
    }
}
```

### 7.3 内存管理

- **自动释放**：对象释放时，关联对象会自动释放
- **引用计数**：根据内存策略管理引用计数
- **线程安全**：使用锁保证线程安全

## 8. Category 的加载时机？

### 8.1 加载流程

1. **程序启动**：`_objc_init` 函数初始化运行时
2. **镜像加载**：`map_images` 函数加载镜像文件
3. **类加载**：`read_images` 函数读取类信息
4. **分类加载**：`load_categories_nolock` 函数加载所有分类
5. **方法附加**：`attachCategories` 函数将分类方法附加到类

### 8.2 关键时机

```objc
// 1. 程序启动时
void _objc_init(void) {
    // 初始化运行时环境
}

// 2. 镜像加载时
void map_images(unsigned count, const char * const paths[]) {
    // 加载所有镜像文件
    read_images(hList, hCount, totalClasses, unoptimizedTotalClasses);
}

// 3. 分类加载时
static void load_categories_nolock(header_info *hi) {
    // 加载所有分类
    for (auto& cat : cats) {
        attachCategories(cls, &lc, 1, ATTACH_EXISTING);
    }
}
```

### 8.3 +load 方法

```objc
// Category 中的 +load 方法会在分类加载时调用
@implementation Person (Category)
+ (void)load {
    NSLog(@"Person+Category load");
    // 此时分类已经加载，但方法还未附加到类
}
@end
```

## 9. Category 和 Protocol 的区别？

### 9.1 对比

| 特性 | Category | Protocol |
|------|----------|----------|
| 作用 | 为类添加方法实现 | 定义方法接口 |
| 实现 | 必须提供方法实现 | 可以只声明不实现 |
| 多继承 | 不支持 | 支持（协议可以多继承） |
| 可选方法 | 不支持 | 支持（@optional） |
| 使用场景 | 扩展已有类 | 定义接口规范 |

### 9.2 代码示例

```objc
// Protocol：定义接口
@protocol Flyable <NSObject>
@required
- (void)fly;

@optional
- (void)land;
@end

// Category：实现接口
@interface Bird (Flyable) <Flyable>
@end

@implementation Bird (Flyable)
- (void)fly {
    NSLog(@"Bird is flying");
}
@end
```

## 10. Category 的实际应用场景？

### 10.1 功能扩展

```objc
// 为系统类添加便捷方法
@interface NSString (Extension)
- (BOOL)isValidEmail;
- (NSString *)md5String;
@end

@implementation NSString (Extension)
- (BOOL)isValidEmail {
    // 验证邮箱格式
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (NSString *)md5String {
    // MD5 加密
    // ...
}
@end
```

### 10.2 代码组织

```objc
// 将大类的方法拆分到多个分类中
// Person+Network.h：网络相关方法
@interface Person (Network)
- (void)login;
- (void)logout;
@end

// Person+Cache.h：缓存相关方法
@interface Person (Cache)
- (void)saveToCache;
- (void)loadFromCache;
@end
```

### 10.3 私有方法暴露

```objc
// 在测试中暴露私有方法
// Person+Testing.h（仅在测试中使用）
@interface Person (Testing)
- (void)privateMethod; // 暴露私有方法用于测试
@end
```

### 10.4 方法交换

```objc
// 使用 Category 进行方法交换（Hook）
@implementation UIViewController (Swizzling)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod([self class], @selector(viewDidLoad));
        Method swizzledMethod = class_getInstanceMethod([self class], @selector(swizzled_viewDidLoad));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)swizzled_viewDidLoad {
    [self swizzled_viewDidLoad]; // 实际调用原方法
    NSLog(@"View did load: %@", NSStringFromClass([self class]));
}
@end
```

## 11. Category 的注意事项？

### 11.1 方法名冲突

- **使用前缀**：为 Category 方法添加前缀，如 `xxx_methodName`
- **避免覆盖**：不要覆盖系统方法或原类方法
- **文档说明**：在文档中说明 Category 的用途和方法

### 11.2 内存管理

- **关联对象**：使用关联对象时注意内存策略
- **循环引用**：避免在 Category 中造成循环引用
- **及时释放**：对象释放时，关联对象会自动释放

### 11.3 性能考虑

- **方法查找**：Category 方法查找需要遍历方法列表
- **加载开销**：多个 Category 会增加加载时间
- **方法数量**：避免在一个 Category 中添加过多方法

### 11.4 最佳实践

```objc
// ✅ 好的实践
@interface NSString (Validation)
- (BOOL)isValidEmail;
- (BOOL)isValidPhone;
@end

// ❌ 不好的实践
@interface NSString (Extension)
- (void)description; // 覆盖系统方法
- (void)init; // 覆盖系统方法
@end
```

## 12. Swift 中的 Extension？

### 12.1 Swift Extension 特点

Swift 中的 Extension 功能更强大，可以：
- 添加计算属性和存储属性（通过关联对象）
- 添加实例方法和类方法
- 添加初始化器
- 添加下标
- 添加嵌套类型
- 遵循协议

### 12.2 代码示例

```swift
// Swift Extension
extension String {
    // 计算属性
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // 方法
    func md5() -> String {
        // MD5 实现
        return ""
    }
    
    // 下标
    subscript(index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

// 使用
let email = "test@example.com"
print(email.isValidEmail) // true
print(email[0]) // Optional("t")
```

### 12.3 Swift Extension 与 Objective-C Category 的区别

| 特性 | Objective-C Category | Swift Extension |
|------|---------------------|-----------------|
| 添加存储属性 | ❌ 不可以 | ⚠️ 通过关联对象 |
| 添加计算属性 | ❌ 不可以 | ✅ 可以 |
| 添加初始化器 | ❌ 不可以 | ✅ 可以（便利初始化器） |
| 添加下标 | ❌ 不可以 | ✅ 可以 |
| 添加嵌套类型 | ❌ 不可以 | ✅ 可以 |
| 协议遵循 | ✅ 可以 | ✅ 可以 |

## 13. 常见面试题

### 13.1 Category 能否添加成员变量？

**答案**：不能直接添加成员变量，但可以通过关联对象（Associated Objects）实现属性的存储。

**原因**：
- Category 在运行时才加载，无法在编译时添加实例变量
- 类的内存布局在编译时确定，运行时无法修改
- 关联对象使用全局哈希表存储，不占用类的内存空间

### 13.2 Category 的方法是否会覆盖原类方法？

**答案**：不会真正覆盖，但调用时会优先调用 Category 方法。

**原理**：
- 方法列表是数组结构，Category 方法会插入到数组前面
- 方法查找时从前向后遍历，找到第一个匹配的方法就返回
- 原类方法仍然存在，只是优先级较低

### 13.3 多个 Category 有同名方法时，调用哪个？

**答案**：调用后编译的 Category 方法。

**原因**：
- Category 的加载顺序取决于编译顺序
- 后加载的 Category 方法会插入到方法列表的前面
- 方法查找时优先找到后加载的方法

### 13.4 Extension 和 Category 的主要区别？

**答案**：
1. **定义位置**：Extension 在 .m 文件中，Category 在独立的文件中
2. **可见性**：Extension 是私有的，Category 是公开的
3. **实例变量**：Extension 可以添加，Category 不可以
4. **编译时机**：Extension 编译时确定，Category 运行时加载
5. **数量限制**：Extension 只能有一个，Category 可以有多个

### 13.5 如何为 Category 添加属性？

**答案**：使用关联对象（Associated Objects）。

**步骤**：
1. 定义关联对象的 key
2. 实现 getter 方法，使用 `objc_getAssociatedObject`
3. 实现 setter 方法，使用 `objc_setAssociatedObject`
4. 选择合适的内存管理策略

### 13.6 Category 的 +load 方法调用时机？

**答案**：在程序启动时，所有类的 +load 方法调用之后，Category 的 +load 方法会被调用。

**调用顺序**：
1. 父类的 +load
2. 子类的 +load
3. Category 的 +load（按照编译顺序）

### 13.7 为什么 Category 不能添加实例变量？

**答案**：
1. **内存布局**：类的内存布局在编译时确定，包含实例变量的偏移量
2. **运行时限制**：Category 在运行时加载，无法修改已确定的内存布局
3. **设计限制**：Category 的设计初衷是添加方法，不是修改类的结构

### 13.8 关联对象的内存管理？

**答案**：关联对象会根据指定的内存策略自动管理内存。

**内存策略**：
- `OBJC_ASSOCIATION_ASSIGN`：弱引用，不 retain
- `OBJC_ASSOCIATION_RETAIN_NONATOMIC`：强引用，非原子
- `OBJC_ASSOCIATION_COPY_NONATOMIC`：拷贝，非原子
- `OBJC_ASSOCIATION_RETAIN`：强引用，原子
- `OBJC_ASSOCIATION_COPY`：拷贝，原子

**释放时机**：对象释放时，关联对象会自动释放。

